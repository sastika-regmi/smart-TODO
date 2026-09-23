import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/task_query.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/toggle_task_completion.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required this._watchTasks,
    required this._createTask,
    required this._updateTask,
    required this._deleteTask,
    required this._toggleTaskCompletion,
    required this._authProvider,
  }) {
    _authProvider.addListener(_onAuthStateChanged);
    final uid = _authProvider.user?.uid;
    if (uid != null) {
      _subscribe(uid);
    }
  }

  final WatchTasks _watchTasks;
  final CreateTask _createTask;
  final UpdateTask _updateTask;
  final DeleteTask _deleteTask;
  final ToggleTaskCompletion _toggleTaskCompletion;
  final AuthProvider _authProvider;

  StreamSubscription<List<Task>>? _subscription;
  Timer? _searchDebounce;

  List<Task> _allTasks = const <Task>[];
  List<Task> _visibleTasks = const <Task>[];

  TaskQuery _query = const TaskQuery();
  TaskQuery get query => _query;

  /// True only while the very first snapshot is in flight. Mutations must not
  /// set this — otherwise toggling one checkbox blanks the whole list.
  bool _isInitialLoading = false;
  bool get isInitialLoading => _isInitialLoading;

  /// True while a create/update/delete is in flight.
  bool _isMutating = false;
  bool get isMutating => _isMutating;

  String? _error;
  String? get error => _error;

  /// Set when the real-time listener has permanently failed. The list is not
  /// usable in this state, so the UI shows an error view with a retry action
  /// rather than an empty list or an endless spinner.
  bool get hasError => _error != null;

  List<Task> get tasks => _visibleTasks;

  // ---- Statistics (computed over all tasks, ignoring filters) ----

  int get totalCount => _allTasks.length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;
  int get pendingCount => totalCount - completedCount;
  int get overdueCount =>
      _allTasks.where((t) => t.isOverdueAt(DateTime.now())).length;

  bool get hasAnyTasks => _allTasks.isNotEmpty;
  bool get hasActiveQuery => _query.isActive;

  /// Looks up the current version of a task by id.
  ///
  /// Detail and edit screens use this instead of holding a stale snapshot, so
  /// they stay correct when the task changes underneath them.
  Task? taskById(String id) {
    for (final task in _allTasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void _onAuthStateChanged() {
    final user = _authProvider.user;
    if (user != null) {
      _subscribe(user.uid);
    } else {
      // Sign-out: drop the listener and every trace of the previous user's
      // data so nothing leaks into the next session.
      _cancelSubscription();
      _allTasks = const <Task>[];
      _visibleTasks = const <Task>[];
      _query = const TaskQuery();
      _error = null;
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  void _subscribe(String userId) {
    _cancelSubscription();
    _isInitialLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = _watchTasks(userId).listen(
        _onTasks,
        onError: _onStreamError,
      );
    } on Failure catch (failure) {
      // The data source checks ownership *before* it builds the stream, so a
      // synchronous throw here is a real failure rather than a stream event.
      // Uncaught it would escape this ChangeNotifier callback as an unhandled
      // exception, leaving the screen on a spinner that never resolves.
      _isInitialLoading = false;
      _error = failure.message;
      notifyListeners();
    }
  }

  void _onTasks(List<Task> tasks) {
    // Both flags changed for the UI's purposes, so the list is only *one* of
    // the things that may need repainting. Without forcing the notification, an
    // account with no tasks (or one recovering from an error) would keep
    // showing the spinner or the error banner: `_recompute` stays silent when
    // the resulting list is identical to the current one.
    final needsNotify = _isInitialLoading || _error != null;
    _allTasks = tasks;
    _isInitialLoading = false;
    _error = null;
    _recompute(force: needsNotify);
  }

  void _onStreamError(Object error) {
    _isInitialLoading = false;
    _error = error is Failure ? error.message : 'Could not load your tasks.';
    notifyListeners();
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Retries the real-time listener after a failure.
  void retry() {
    final user = _authProvider.user;
    if (user != null) _subscribe(user.uid);
  }

  /// Recomputes the visible list and notifies once.
  ///
  /// Returns early when the result is unchanged, so a Firestore snapshot that
  /// does not alter the filtered view never triggers a rebuild. [force] covers
  /// the cases where something besides the list changed — the loading flag, the
  /// error message — and the UI has to hear about it either way.
  bool _recompute({bool force = false}) {
    final next = _query.apply(_allTasks);
    if (!force && listEquals(next, _visibleTasks)) return false;
    _visibleTasks = next;
    notifyListeners();
    return true;
  }

  // ---- Query mutators (local UI state only; never touch Firestore) ----

  void setStatusFilter(TaskStatusFilter status) {
    if (_query.status == status) return;
    _query = _query.copyWith(status: status);
    _recompute();
  }

  void setPriorityFilter(TaskPriorityFilter priority) {
    if (_query.priority == priority) return;
    _query = _query.copyWith(priority: priority);
    _recompute();
  }

  void setSort(TaskSort sort, {TaskSortOrder? order}) {
    final nextOrder = order ??
        (_query.sort == sort
            ? _query.order.toggled()
            : TaskSortOrder.descending);
    if (_query.sort == sort && _query.order == nextOrder) return;
    _query = _query.copyWith(sort: sort, order: nextOrder);
    _recompute();
  }

  /// Debounced so a fast typist does not re-filter the whole list on every
  /// keystroke. The pending timer is cancelled on dispose.
  void search(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      // Clearing is instant — waiting to show everything again feels broken.
      _applySearch('');
      return;
    }
    _searchDebounce = Timer(AppConstants.searchDebounce, () {
      _applySearch(value);
    });
  }

  void _applySearch(String value) {
    if (_query.search == value) return;
    _query = _query.copyWith(search: value);
    _recompute();
  }

  void clearFilters() {
    if (!_query.isActive) return;
    _query = const TaskQuery();
    _recompute();
  }

  // ---- Mutations ----

  /// Creates a task owned by the signed-in user. Returns null on success, or a
  /// user-facing error message on failure.
  Future<String?> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final user = _authProvider.user;
    if (user == null) return 'You must be signed in to add a task.';
    if (_isMutating) return null;

    _isMutating = true;
    notifyListeners();

    final now = DateTime.now();
    final task = Task(
      id: '',
      userId: user.uid,
      title: title.trim(),
      description: _nullableTrim(description),
      isCompleted: false,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      dueDate: dueDate,
    );

    try {
      final result = await _createTask(task);
      return switch (result) {
        FailureResult(:final failure) => failure.message,
        Success() => null,
      };
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String?> updateTask(Task task) async {
    if (_isMutating) return null;

    _isMutating = true;
    notifyListeners();
    try {
      final result = await _updateTask(task.copyWith(updatedAt: DateTime.now()));
      return switch (result) {
        FailureResult(:final failure) => failure.message,
        Success() => null,
      };
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTask(String taskId) async {
    if (_isMutating) return null;

    _isMutating = true;
    notifyListeners();
    try {
      final result = await _deleteTask(taskId);
      return switch (result) {
        FailureResult(:final failure) => failure.message,
        Success() => null,
      };
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<String?> toggleTaskCompletion(String taskId, bool isCompleted) async {
    if (_isMutating) return null;

    _isMutating = true;
    notifyListeners();
    try {
      final result = await _toggleTaskCompletion(taskId, isCompleted);
      return switch (result) {
        FailureResult(:final failure) => failure.message,
        Success() => null,
      };
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _cancelSubscription();
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
