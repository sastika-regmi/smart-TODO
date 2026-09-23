import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/core/utils/task_query.dart';
import 'package:smart_todo/domain/entities/task.dart';

import '../helpers/fakes.dart';

void main() {
  // Fixed clock: sorting by due date must not depend on when the suite runs.
  final base = DateTime(2026, 1, 1);

  final groceries = buildTask(
    id: 'a',
    title: 'Buy groceries',
    description: 'Milk and eggs',
    priority: TaskPriority.low,
    createdAt: base,
    dueDate: DateTime(2026, 1, 10),
  );
  final report = buildTask(
    id: 'b',
    title: 'Write report',
    description: 'Quarterly numbers',
    priority: TaskPriority.high,
    createdAt: base.add(const Duration(days: 1)),
    dueDate: DateTime(2026, 1, 5),
  );
  final callMom = buildTask(
    id: 'c',
    title: 'Call Mom',
    priority: TaskPriority.medium,
    createdAt: base.add(const Duration(days: 2)),
  );
  final done = buildTask(
    id: 'd',
    title: 'Pay rent',
    description: 'Transfer to landlord',
    priority: TaskPriority.high,
    isCompleted: true,
    completedAt: base.add(const Duration(days: 3)),
    createdAt: base.add(const Duration(days: 3)),
    dueDate: DateTime(2026, 1, 1),
  );

  final all = <Task>[groceries, report, callMom, done];

  List<String> idsOf(List<Task> tasks) => tasks.map((t) => t.id).toList();

  group('search', () {
    test('matches the title case-insensitively', () {
      final result = const TaskQuery(search: 'REPORT').apply(all);
      expect(idsOf(result), ['b']);
    });

    test('matches the description', () {
      final result = const TaskQuery(search: 'landlord').apply(all);
      expect(idsOf(result), ['d']);
    });

    test('ignores surrounding whitespace', () {
      expect(idsOf(const TaskQuery(search: '  mom  ').apply(all)), ['c']);
    });

    test('an empty search returns everything', () {
      expect(const TaskQuery(search: '').apply(all).length, all.length);
      expect(const TaskQuery(search: '   ').apply(all).length, all.length);
    });

    test('returns nothing when there is no match', () {
      expect(const TaskQuery(search: 'zzz').apply(all), isEmpty);
    });
  });

  group('status filter', () {
    test('pending excludes completed tasks', () {
      final result =
          const TaskQuery(status: TaskStatusFilter.pending).apply(all);
      expect(idsOf(result), isNot(contains('d')));
      expect(result.length, 3);
    });

    test('completed returns only completed tasks', () {
      final result =
          const TaskQuery(status: TaskStatusFilter.completed).apply(all);
      expect(idsOf(result), ['d']);
    });
  });

  group('priority filter', () {
    test('selects a single priority', () {
      final result =
          const TaskQuery(priority: TaskPriorityFilter.high).apply(all);
      expect(idsOf(result), containsAll(['b', 'd']));
      expect(result.length, 2);
    });

    test('all does not filter', () {
      expect(
        const TaskQuery(priority: TaskPriorityFilter.all).apply(all).length,
        all.length,
      );
    });
  });

  group('sort', () {
    test('by created date, newest first by default', () {
      final result = const TaskQuery().apply(all);
      expect(idsOf(result), ['d', 'c', 'b', 'a']);
    });

    test('by created date, oldest first when ascending', () {
      final result = const TaskQuery(order: TaskSortOrder.ascending).apply(all);
      expect(idsOf(result), ['a', 'b', 'c', 'd']);
    });

    test('by due date, soonest first', () {
      final result = const TaskQuery(
        sort: TaskSort.dueDate,
        order: TaskSortOrder.ascending,
      ).apply(all);
      expect(idsOf(result), ['d', 'b', 'a', 'c']);
    });

    test('keeps tasks without a due date last in both directions', () {
      // A missing deadline is "no information", not "the earliest deadline".
      const dueDescending = TaskQuery(
        sort: TaskSort.dueDate,
        order: TaskSortOrder.descending,
      );
      expect(idsOf(dueDescending.apply(all)).last, 'c');

      const dueAscending = TaskQuery(
        sort: TaskSort.dueDate,
        order: TaskSortOrder.ascending,
      );
      expect(idsOf(dueAscending.apply(all)).last, 'c');
    });

    test('by priority, highest first', () {
      final result = const TaskQuery(
        sort: TaskSort.priority,
        order: TaskSortOrder.descending,
      ).apply(all);
      expect(idsOf(result).take(2), containsAll(['b', 'd']));
      expect(idsOf(result).last, 'a');
    });

    test('by title, alphabetically', () {
      final result = const TaskQuery(
        sort: TaskSort.title,
        order: TaskSortOrder.ascending,
      ).apply(all);
      expect(idsOf(result), ['a', 'c', 'd', 'b']);
    });
  });

  group('combined filters', () {
    test('search plus status plus priority plus sort', () {
      final result = const TaskQuery(
        search: 'e',
        status: TaskStatusFilter.pending,
        priority: TaskPriorityFilter.high,
        sort: TaskSort.title,
        order: TaskSortOrder.ascending,
      ).apply(all);

      // Only the pending high-priority task ("Write report") survives all three
      // narrowings; the completed high-priority task is filtered out by status.
      expect(idsOf(result), ['b']);
    });

    test('a combination that matches nothing yields an empty list', () {
      final result = const TaskQuery(
        search: 'groceries',
        priority: TaskPriorityFilter.high,
      ).apply(all);
      expect(result, isEmpty);
    });
  });

  group('TaskQuery', () {
    test('never mutates the input list', () {
      final input = List<Task>.of(all);
      const TaskQuery(sort: TaskSort.title, order: TaskSortOrder.ascending)
          .apply(input);
      expect(idsOf(input), idsOf(all));
    });

    test('isActive reflects whether anything narrows the list', () {
      expect(const TaskQuery().isActive, isFalse);
      expect(const TaskQuery(sort: TaskSort.title).isActive, isFalse);
      expect(const TaskQuery(search: 'x').isActive, isTrue);
      expect(const TaskQuery(status: TaskStatusFilter.pending).isActive, isTrue);
      expect(const TaskQuery(priority: TaskPriorityFilter.low).isActive, isTrue);
    });

    test('compares by value, so a no-op change does not notify listeners', () {
      expect(const TaskQuery(search: 'a'), const TaskQuery(search: 'a'));
      expect(
        const TaskQuery(search: 'a').hashCode,
        const TaskQuery(search: 'a').hashCode,
      );
      expect(
        const TaskQuery(search: 'a'),
        isNot(const TaskQuery(search: 'b')),
      );
    });

    test('copyWith replaces only the fields given', () {
      const original = TaskQuery(
        search: 'x',
        status: TaskStatusFilter.pending,
        sort: TaskSort.title,
      );

      final updated = original.copyWith(priority: TaskPriorityFilter.high);

      expect(updated.search, 'x');
      expect(updated.status, TaskStatusFilter.pending);
      expect(updated.sort, TaskSort.title);
      expect(updated.priority, TaskPriorityFilter.high);
    });
  });
}
