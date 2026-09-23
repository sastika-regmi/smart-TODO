import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_todo/core/errors/failures.dart';
import 'package:smart_todo/core/utils/task_query.dart';
import 'package:smart_todo/domain/entities/task.dart';
import 'package:smart_todo/domain/repositories/task_repository.dart';
import 'package:smart_todo/presentation/providers/auth_provider.dart';
import 'package:smart_todo/presentation/providers/task_provider.dart';

import '../helpers/fakes.dart';

void main() {
  setUpAll(() => registerFallbackValue(buildTask()));

  late MockTaskRepository repository;
  late MockAuthService authService;
  late StreamController<List<Task>> tasks;
  late StreamController<User?> authState;

  setUp(() {
    repository = MockTaskRepository();
    tasks = StreamController<List<Task>>.broadcast();
    when(() => repository.watchTasks(any())).thenAnswer((_) => tasks.stream);

    authService = MockAuthService();
    authState = StreamController<User?>.broadcast();
    when(authService.authStateChanges).thenAnswer((_) => authState.stream);
  });

  tearDown(() async {
    await tasks.close();
    await authState.close();
  });

  Future<TaskProvider> signedInProvider({List<Task> initial = const []}) async {
    final auth = AuthProvider(authService);
    final provider = buildTaskProvider(repository: repository, authProvider: auth);

    authState.add(fakeUser('user-1', 'user@example.com', 'Test User'));
    await pumpEventQueue();
    tasks.add(initial);
    await pumpEventQueue();
    return provider;
  }

  test('does not subscribe until a user is signed in', () async {
    buildTaskProvider(repository: repository, authProvider: AuthProvider(authService));
    await pumpEventQueue();

    verifyNever(() => repository.watchTasks(any()));
  });

  test('watching a user loads their tasks', () async {
    final provider = await signedInProvider(initial: [buildTask(title: 'One')]);

    expect(provider.tasks.map((t) => t.title), ['One']);
    expect(provider.isInitialLoading, isFalse);
    verify(() => repository.watchTasks('user-1')).called(1);
  });

  test('an empty first snapshot still ends the loading state', () async {
    final auth = AuthProvider(authService);
    final provider = buildTaskProvider(repository: repository, authProvider: auth);
    var notifications = 0;
    provider.addListener(() => notifications++);

    authState.add(fakeUser('user-1', 'user@example.com', 'Test User'));
    await pumpEventQueue();

    // The visible list is unchanged by this snapshot (both empty), so a
    // provider that only notified on a list change would leave a brand-new
    // account staring at a spinner forever.
    notifications = 0;
    tasks.add(const <Task>[]);
    await pumpEventQueue();

    expect(provider.isInitialLoading, isFalse);
    expect(provider.hasAnyTasks, isFalse);
    expect(notifications, greaterThan(0));
  });

  test('signing out drops the previous user\'s tasks and filters', () async {
    final provider = await signedInProvider(initial: [buildTask(title: 'Secret')]);
    provider.setStatusFilter(TaskStatusFilter.pending);
    expect(provider.tasks, hasLength(1));

    authState.add(null);
    await pumpEventQueue();

    expect(provider.tasks, isEmpty);
    expect(provider.hasAnyTasks, isFalse);
    expect(provider.query.status, TaskStatusFilter.all);
    expect(provider.error, isNull);
  });

  test('statistics cover all tasks, ignoring the active filter', () async {
    final provider = await signedInProvider(
      initial: [
        buildTask(id: '1', title: 'Pending'),
        buildTask(id: '2', title: 'Done', isCompleted: true),
        buildTask(id: '3', title: 'Late', dueDate: DateTime(2020, 1, 1)),
      ],
    );

    provider.setStatusFilter(TaskStatusFilter.completed);

    expect(provider.tasks, hasLength(1));
    expect(provider.totalCount, 3);
    expect(provider.completedCount, 1);
    expect(provider.pendingCount, 2);
    expect(provider.overdueCount, 1);
  });

  test('filtering narrows the visible list without touching the source', () async {
    final provider = await signedInProvider(
      initial: [
        buildTask(id: '1', title: 'Low thing', priority: TaskPriority.low),
        buildTask(id: '2', title: 'High thing', priority: TaskPriority.high),
      ],
    );

    provider.setPriorityFilter(TaskPriorityFilter.high);

    expect(provider.tasks.map((t) => t.id), ['2']);
    expect(provider.totalCount, 2);
    expect(provider.hasActiveQuery, isTrue);

    provider.clearFilters();

    expect(provider.tasks, hasLength(2));
    expect(provider.hasActiveQuery, isFalse);
  });

  test('search is debounced, then clears instantly', () async {
    final provider = await signedInProvider(
      initial: [
        buildTask(id: '1', title: 'Buy milk'),
        buildTask(id: '2', title: 'Write report'),
      ],
    );

    provider.search('milk');
    // Still unfiltered: the debounce has not elapsed.
    expect(provider.tasks, hasLength(2));

    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(provider.tasks.map((t) => t.id), ['1']);

    provider.search('');
    // Clearing must not wait — an empty search feels broken if it lags.
    expect(provider.tasks, hasLength(2));
  });

  test('a toggle does not blank the list behind a loading state', () async {
    final provider = await signedInProvider(initial: [buildTask(id: '1')]);
    when(() => repository.toggleTaskCompletion(any(), any())).thenAnswer(
      (invocation) async => Success<Task>(
        buildTask(id: '1', isCompleted: invocation.positionalArguments[1] as bool),
      ),
    );

    final pending = provider.toggleTaskCompletion('1', true);

    // The list stays on screen while the write is in flight; only the mutation
    // guard flips.
    expect(provider.isInitialLoading, isFalse);
    expect(provider.isMutating, isTrue);
    expect(provider.tasks, hasLength(1));

    expect(await pending, isNull);
    expect(provider.isMutating, isFalse);
  });

  test('a failed mutation returns the message and clears the guard', () async {
    final provider = await signedInProvider(initial: [buildTask(id: '1')]);
    when(() => repository.deleteTask(any())).thenAnswer(
      (_) async => const FailureResult<void>(PermissionFailure('Not yours.')),
    );

    expect(await provider.deleteTask('1'), 'Not yours.');
    expect(provider.isMutating, isFalse);
  });

  test('creating requires a signed-in user', () async {
    final provider = buildTaskProvider(
      repository: repository,
      authProvider: AuthProvider(authService),
    );

    expect(
      await provider.createTask(title: 'Anything'),
      'You must be signed in to add a task.',
    );
    verifyNever(() => repository.createTask(any()));
  });

  test('a stream error surfaces as a message, not an endless spinner', () async {
    final auth = AuthProvider(authService);
    final provider = buildTaskProvider(repository: repository, authProvider: auth);

    authState.add(fakeUser('user-1', 'user@example.com', 'Test User'));
    await pumpEventQueue();

    tasks.addError(const NetworkFailure('No connection.'));
    await pumpEventQueue();

    expect(provider.isInitialLoading, isFalse);
    expect(provider.error, 'No connection.');
    expect(provider.hasError, isTrue);
  });

  test('retry resubscribes after a failure', () async {
    final auth = AuthProvider(authService);
    final provider = buildTaskProvider(repository: repository, authProvider: auth);

    authState.add(fakeUser('user-1', 'user@example.com', 'Test User'));
    await pumpEventQueue();
    tasks.addError(const NetworkFailure('No connection.'));
    await pumpEventQueue();

    provider.retry();
    await pumpEventQueue();
    tasks.add([buildTask(title: 'Recovered')]);
    await pumpEventQueue();

    expect(provider.error, isNull);
    expect(provider.tasks.map((t) => t.title), ['Recovered']);
  });
}
