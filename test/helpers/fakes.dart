import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:mocktail/mocktail.dart';
import 'package:smart_todo/core/services/auth_service.dart';
import 'package:smart_todo/domain/entities/task.dart';
import 'package:smart_todo/domain/repositories/task_repository.dart';
import 'package:smart_todo/domain/usecases/create_task.dart';
import 'package:smart_todo/domain/usecases/delete_task.dart';
import 'package:smart_todo/domain/usecases/toggle_task_completion.dart';
import 'package:smart_todo/domain/usecases/update_task.dart';
import 'package:smart_todo/domain/usecases/watch_tasks.dart';
import 'package:smart_todo/presentation/providers/auth_provider.dart';
import 'package:smart_todo/presentation/providers/task_provider.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockTaskRepository extends Mock implements TaskRepository {}

/// Builds a [Task] with sensible defaults so each test states only what it
/// actually cares about.
Task buildTask({
  String id = 'task-1',
  String userId = 'user-1',
  String title = 'Test task',
  String? description,
  bool isCompleted = false,
  TaskPriority priority = TaskPriority.medium,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  DateTime? dueDate,
}) {
  final created = createdAt ?? DateTime(2026, 1, 1, 9);
  return Task(
    id: id,
    userId: userId,
    title: title,
    description: description,
    isCompleted: isCompleted,
    priority: priority,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    completedAt: completedAt,
    dueDate: dueDate,
  );
}

/// A real [AuthProvider] backed by a mocked [AuthService].
///
/// The provider itself is the class under test in several suites, so it is
/// never mocked — only the Firebase-backed service beneath it.
AuthProvider buildAuthProvider({
  String uid = 'user-1',
  String email = 'test@example.com',
  String displayName = 'Test User',
  bool signedIn = true,
}) {
  final service = MockAuthService();
  final user = signedIn ? fakeUser(uid, email, displayName) : null;
  final stateChanges = Stream<User?>.value(user);
  when(service.authStateChanges).thenAnswer((_) => stateChanges);
  return AuthProvider(service);
}

/// A stand-in for `FirebaseAuth.currentUser`.
User fakeUser(String uid, String email, String displayName) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.email).thenReturn(email);
  when(() => user.displayName).thenReturn(displayName);
  return user;
}

/// A real [TaskProvider] wired to a mocked repository.
///
/// Every use case is a pass-through to the repository, so mocking at that
/// boundary exercises the provider's own filtering, debouncing and error
/// handling rather than replacing it.
TaskProvider buildTaskProvider({
  List<Task> tasks = const <Task>[],
  TaskRepository? repository,
  AuthProvider? authProvider,
}) {
  final repo = repository ?? MockTaskRepository();
  if (repository == null && repo is MockTaskRepository) {
    when(() => repo.watchTasks(any())).thenAnswer((_) => Stream.value(tasks));
  }
  return TaskProvider(
    watchTasks: WatchTasks(repo),
    createTask: CreateTask(repo),
    updateTask: UpdateTask(repo),
    deleteTask: DeleteTask(repo),
    toggleTaskCompletion: ToggleTaskCompletion(repo),
    authProvider: authProvider ?? buildAuthProvider(),
  );
}
