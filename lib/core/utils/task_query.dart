import '../../domain/entities/task.dart';

enum TaskStatusFilter { all, pending, completed }

extension TaskStatusFilterLabel on TaskStatusFilter {
  String get label {
    switch (this) {
      case TaskStatusFilter.all:
        return 'All';
      case TaskStatusFilter.pending:
        return 'Pending';
      case TaskStatusFilter.completed:
        return 'Completed';
    }
  }

  bool matches(Task task) {
    switch (this) {
      case TaskStatusFilter.all:
        return true;
      case TaskStatusFilter.pending:
        return !task.isCompleted;
      case TaskStatusFilter.completed:
        return task.isCompleted;
    }
  }
}

enum TaskPriorityFilter { all, low, medium, high }

extension TaskPriorityFilterLabel on TaskPriorityFilter {
  String get label {
    switch (this) {
      case TaskPriorityFilter.all:
        return 'All';
      case TaskPriorityFilter.low:
        return 'Low';
      case TaskPriorityFilter.medium:
        return 'Medium';
      case TaskPriorityFilter.high:
        return 'High';
    }
  }

  /// The domain priority this filter selects, or null for "all".
  TaskPriority? get priority {
    switch (this) {
      case TaskPriorityFilter.all:
        return null;
      case TaskPriorityFilter.low:
        return TaskPriority.low;
      case TaskPriorityFilter.medium:
        return TaskPriority.medium;
      case TaskPriorityFilter.high:
        return TaskPriority.high;
    }
  }
}

enum TaskSort { createdDate, dueDate, priority, title }

extension TaskSortLabel on TaskSort {
  String get label {
    switch (this) {
      case TaskSort.createdDate:
        return 'Date created';
      case TaskSort.dueDate:
        return 'Due date';
      case TaskSort.priority:
        return 'Priority';
      case TaskSort.title:
        return 'Title';
    }
  }
}

enum TaskSortOrder { ascending, descending }

extension TaskSortOrderLabel on TaskSortOrder {
  TaskSortOrder toggled() =>
      this == TaskSortOrder.ascending ? TaskSortOrder.descending : TaskSortOrder.ascending;
}

/// An immutable description of how the task list should be narrowed and
/// ordered. Pure data — no Flutter, no Firestore.
///
/// Filtering and sorting happen locally, so search and filters never modify
/// the underlying Firestore documents and never trigger a network round trip.
class TaskQuery {
  const TaskQuery({
    this.search = '',
    this.status = TaskStatusFilter.all,
    this.priority = TaskPriorityFilter.all,
    this.sort = TaskSort.createdDate,
    this.order = TaskSortOrder.descending,
  });

  final String search;
  final TaskStatusFilter status;
  final TaskPriorityFilter priority;
  final TaskSort sort;
  final TaskSortOrder order;

  /// Whether anything is narrowing the list, used to decide between the
  /// "no tasks yet" and "no matching tasks" empty states.
  bool get isActive =>
      search.trim().isNotEmpty ||
      status != TaskStatusFilter.all ||
      priority != TaskPriorityFilter.all;

  TaskQuery copyWith({
    String? search,
    TaskStatusFilter? status,
    TaskPriorityFilter? priority,
    TaskSort? sort,
    TaskSortOrder? order,
  }) {
    return TaskQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      sort: sort ?? this.sort,
      order: order ?? this.order,
    );
  }

  /// Applies search, filters and sorting, returning a new list.
  ///
  /// The input list is never mutated.
  List<Task> apply(List<Task> tasks) {
    final needle = search.trim().toLowerCase();

    final result = tasks.where((task) {
      if (!status.matches(task)) return false;
      final wantedPriority = priority.priority;
      if (wantedPriority != null && task.priority != wantedPriority) return false;
      if (needle.isEmpty) return true;
      return task.title.toLowerCase().contains(needle) ||
          (task.description?.toLowerCase().contains(needle) ?? false);
    }).toList();

    result.sort(_compare);
    return result;
  }

  int _compare(Task a, Task b) {
    int result;
    switch (sort) {
      case TaskSort.createdDate:
        result = a.createdAt.compareTo(b.createdAt);
      case TaskSort.dueDate:
        // Tasks with no due date always sort last, in both directions — a
        // missing deadline is "no information", not "the earliest deadline".
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue == null && bDue == null) return _tieBreak(a, b);
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        result = aDue.compareTo(bDue);
      case TaskSort.priority:
        result = a.priority.weight.compareTo(b.priority.weight);
      case TaskSort.title:
        result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }

    if (result == 0) return _tieBreak(a, b);
    return order == TaskSortOrder.ascending ? result : -result;
  }

  /// Stable, direction-independent tie-break so equal keys keep a deterministic
  /// order and the list does not reshuffle between rebuilds.
  int _tieBreak(Task a, Task b) => b.createdAt.compareTo(a.createdAt);

  @override
  bool operator ==(Object other) =>
      other is TaskQuery &&
      other.search == search &&
      other.status == status &&
      other.priority == priority &&
      other.sort == sort &&
      other.order == order;

  @override
  int get hashCode => Object.hash(search, status, priority, sort, order);
}
