import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/failures.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String userId);
  Stream<List<TaskModel>> watchTasks(String userId);
  Future<TaskModel> getTask(String taskId);
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
  Future<TaskModel> toggleTaskCompletion(String taskId, bool isCompleted);
}

/// Firestore-backed task storage scoped to `users/{uid}/tasks/{taskId}`.
///
/// Ownership is always taken from the *authenticated* Firebase user, never from
/// an argument supplied by the caller. That means a compromised or buggy caller
/// cannot read or write another user's tasks by passing a foreign id — and it
/// lets every operation address the task document directly, instead of scanning
/// with a `collectionGroup` query (which the security rules correctly reject,
/// since such a query cannot be proven to stay inside one user's subtree).
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  const TaskRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('You must be signed in to manage tasks.');
    }
    return user.uid;
  }

  /// Guards against a caller passing a uid that is not the signed-in user's.
  void _assertOwnership(String userId) {
    if (userId != _uid) {
      throw const PermissionFailure(
        'You do not have permission to access these tasks.',
      );
    }
  }

  CollectionReference<TaskModel> _collectionFor(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .withConverter<TaskModel>(
          fromFirestore: (snapshot, _) => TaskModel.fromMap(
            id: snapshot.id,
            data: snapshot.data(),
          ),
          toFirestore: (task, _) => task.toFirestore(),
        );
  }

  /// The signed-in user's own task collection.
  CollectionReference<TaskModel> get _tasks => _collectionFor(_uid);

  @override
  Future<List<TaskModel>> getTasks(String userId) async {
    _assertOwnership(userId);
    try {
      final snapshot =
          await _collectionFor(userId).orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw _mapException(e, 'load your tasks');
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    _assertOwnership(userId);
    return _collectionFor(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((Object error) {
          throw _mapException(error, 'load your tasks');
        });
  }

  @override
  Future<TaskModel> getTask(String taskId) async {
    try {
      final snapshot = await _tasks.doc(taskId).get();
      final data = snapshot.data();
      if (data == null) {
        throw const NotFoundFailure('That task no longer exists.');
      }
      return data;
    } on FirebaseException catch (e) {
      throw _mapException(e, 'load that task');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final docRef = _tasks.doc();
      // Force ownership: whatever the caller put in `userId`, the document is
      // written under the authenticated user and stamped with their uid.
      final newTask = task.copyWith(id: docRef.id, userId: _uid);
      await docRef.set(newTask);
      return newTask;
    } on FirebaseException catch (e) {
      throw _mapException(e, 'create that task');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    // Refuse to write a document that claims a different owner. This mirrors
    // the Firestore rule, so the client fails fast with a clear message.
    _assertOwnership(task.userId);
    try {
      final update = task.copyWith(userId: _uid);
      await _tasks.doc(update.id).set(update);
      return update;
    } on FirebaseException catch (e) {
      throw _mapException(e, 'update that task');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasks.doc(taskId).delete();
    } on FirebaseException catch (e) {
      throw _mapException(e, 'delete that task');
    }
  }

  @override
  Future<TaskModel> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      final docRef = _tasks.doc(taskId);
      final snapshot = await docRef.get();
      final current = snapshot.data();
      if (current == null) {
        throw const NotFoundFailure('That task no longer exists.');
      }

      final now = DateTime.now();
      final updated = current.copyWith(
        isCompleted: isCompleted,
        updatedAt: now,
        completedAt: isCompleted ? now : null,
      );

      await docRef.set(updated);
      return updated;
    } on FirebaseException catch (e) {
      throw _mapException(e, 'update that task');
    }
  }

  /// Turns a Firestore failure into a [Failure] carrying a message that is safe
  /// to show a user — never a raw error code or stack trace.
  Failure _mapException(Object error, String action) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const PermissionFailure(
            'You do not have permission to access these tasks.',
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return const NetworkFailure(
            'Could not reach the server. Check your connection and try again.',
          );
        case 'not-found':
          return const NotFoundFailure('That task no longer exists.');
        case 'unauthenticated':
          return const AuthFailure('Your session expired. Please sign in again.');
        default:
          return ServerFailure('Could not $action. Please try again.');
      }
    }
    return ServerFailure('Could not $action. Please try again.');
  }
}
