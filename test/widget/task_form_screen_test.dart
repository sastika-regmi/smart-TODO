import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:smart_todo/core/constants/app_constants.dart';
import 'package:smart_todo/core/errors/failures.dart';
import 'package:smart_todo/core/theme/app_theme.dart';
import 'package:smart_todo/domain/entities/task.dart';
import 'package:smart_todo/domain/repositories/task_repository.dart';
import 'package:smart_todo/presentation/providers/task_provider.dart';
import 'package:smart_todo/presentation/screens/tasks/task_form_screen.dart';

import '../helpers/fakes.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(buildTask());
  });

  late MockTaskRepository repository;
  late TaskProvider taskProvider;

  setUp(() {
    repository = MockTaskRepository();
    final tasks = Stream<List<Task>>.value(const <Task>[]);
    when(() => repository.watchTasks(any())).thenAnswer((_) => tasks);
    taskProvider = buildTaskProvider(repository: repository);
  });

  /// Pushes the form onto a real route stack, so "the form closes after a
  /// successful save" is an assertion that actually means something.
  Widget harness() {
    return ChangeNotifierProvider<TaskProvider>.value(
      value: taskProvider,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const TaskFormScreen()),
              ),
              child: const Text('open form'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    // Lets the mocked auth stream deliver the signed-in user.
    await tester.pump();
    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await tester.pump();
  }

  testWidgets('will not submit an empty title', (tester) async {
    await openForm(tester);

    await tapSave(tester);

    expect(find.text('Task title is required.'), findsOneWidget);
    verifyNever(() => repository.createTask(any()));
  });

  testWidgets('will not submit a title over the length limit', (tester) async {
    await openForm(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'a' * (AppConstants.maxTaskTitleLength + 1),
    );
    await tapSave(tester);

    expect(
      find.text(
        'Title must be at most ${AppConstants.maxTaskTitleLength} characters.',
      ),
      findsOneWidget,
    );
    verifyNever(() => repository.createTask(any()));
  });

  testWidgets('rejects a description over the length limit', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'A valid title');
    await tester.enterText(
      find.byType(TextFormField).last,
      'a' * (AppConstants.maxTaskDescriptionLength + 1),
    );
    await tapSave(tester);

    expect(
      find.text(
        'Description must be at most '
        '${AppConstants.maxTaskDescriptionLength} characters.',
      ),
      findsOneWidget,
    );
    verifyNever(() => repository.createTask(any()));
  });

  testWidgets('creates the task and closes the form', (tester) async {
    when(() => repository.createTask(any())).thenAnswer(
      (invocation) async =>
          Success<Task>(invocation.positionalArguments.first as Task),
    );

    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, '  Buy milk  ');
    await tapSave(tester);
    await tester.pumpAndSettle();

    final captured = verify(() => repository.createTask(captureAny())).captured;
    final created = captured.single as Task;
    expect(created.title, 'Buy milk', reason: 'title should be trimmed');
    expect(created.description, isNull);
    expect(created.isCompleted, isFalse);
    expect(created.userId, 'user-1', reason: 'ownership comes from the session');

    expect(find.byType(TaskFormScreen), findsNothing);
  });

  testWidgets('stays open and reports the failure when the save fails', (
    tester,
  ) async {
    when(() => repository.createTask(any())).thenAnswer(
      (_) async => const FailureResult<Task>(ServerFailure('Nope.')),
    );

    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Buy milk');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TaskFormScreen), findsOneWidget);
    expect(find.text('Nope.'), findsOneWidget);
  });
}
