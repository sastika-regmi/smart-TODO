import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/domain/entities/task.dart';

import '../helpers/fakes.dart';

void main() {
  group('Task.copyWith', () {
    test('preserves every field that is not passed', () {
      final task = buildTask(
        description: 'Original description',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 3, 1),
        completedAt: null,
      );

      final updated = task.copyWith(title: 'Updated title');

      expect(updated.id, task.id);
      expect(updated.userId, task.userId);
      expect(updated.title, 'Updated title');
      expect(updated.description, 'Original description');
      expect(updated.isCompleted, task.isCompleted);
      expect(updated.priority, TaskPriority.high);
      expect(updated.createdAt, task.createdAt);
      expect(updated.updatedAt, task.updatedAt);
      expect(updated.dueDate, DateTime(2026, 3, 1));
      expect(updated.completedAt, isNull);
    });

    test('clears a due date when null is passed explicitly', () {
      // The whole point of the sentinel: `dueDate: null` must mean "remove it",
      // while omitting the argument must mean "leave it alone".
      final task = buildTask(dueDate: DateTime(2026, 3, 1));

      expect(task.copyWith(dueDate: null).dueDate, isNull);
      expect(task.copyWith().dueDate, DateTime(2026, 3, 1));
    });

    test('clears a description and a completion time', () {
      final task = buildTask(
        description: 'Something',
        isCompleted: true,
        completedAt: DateTime(2026, 2, 1),
      );

      final cleared = task.copyWith(description: null, completedAt: null);

      expect(cleared.description, isNull);
      expect(cleared.completedAt, isNull);
      expect(cleared.isCompleted, isTrue);
    });
  });

  group('Task equality', () {
    test('compares every field, not just the id', () {
      // Id-only equality would make `context.select` and `listEquals` miss
      // edits, leaving stale rows on screen.
      final original = buildTask(title: 'Original');
      final edited = original.copyWith(title: 'Edited');
      final sameId = buildTask(title: 'Original');

      expect(original, isNot(edited));
      expect(original, sameId);
      expect(original.hashCode, sameId.hashCode);
    });
  });

  group('Task.isOverdueAt', () {
    final now = DateTime(2026, 6, 15, 14, 30);

    test('is false without a due date', () {
      expect(buildTask().isOverdueAt(now), isFalse);
    });

    test('is false for a due date later today', () {
      // Compared by calendar day: a deadline of "today 09:00" is not overdue at
      // 14:30, otherwise every same-day task would look late all afternoon.
      final task = buildTask(dueDate: DateTime(2026, 6, 15, 9));
      expect(task.isOverdueAt(now), isFalse);
    });

    test('is true from the next calendar day onwards', () {
      expect(buildTask(dueDate: DateTime(2026, 6, 14)).isOverdueAt(now), isTrue);
      expect(buildTask(dueDate: DateTime(2026, 1, 1)).isOverdueAt(now), isTrue);
    });

    test('is false for a future due date', () {
      expect(buildTask(dueDate: DateTime(2026, 6, 16)).isOverdueAt(now), isFalse);
    });

    test('is false once the task is completed', () {
      final task = buildTask(
        dueDate: DateTime(2026, 6, 1),
        isCompleted: true,
        completedAt: DateTime(2026, 6, 2),
      );
      expect(task.isOverdueAt(now), isFalse);
    });
  });

  group('Task.hasDescription', () {
    test('treats null and blank descriptions as absent', () {
      expect(buildTask().hasDescription, isFalse);
      expect(buildTask(description: '').hasDescription, isFalse);
      expect(buildTask(description: '   ').hasDescription, isFalse);
      expect(buildTask(description: 'Real').hasDescription, isTrue);
    });
  });

  group('TaskPriority', () {
    test('round-trips through its stored value', () {
      for (final priority in TaskPriority.values) {
        expect(TaskPriority.fromString(priority.value), priority);
      }
    });

    test('falls back to medium for unknown or missing values', () {
      expect(TaskPriority.fromString(null), TaskPriority.medium);
      expect(TaskPriority.fromString(''), TaskPriority.medium);
      expect(TaskPriority.fromString('urgent'), TaskPriority.medium);
    });

    test('weight orders low < medium < high', () {
      expect(TaskPriority.low.weight, lessThan(TaskPriority.medium.weight));
      expect(TaskPriority.medium.weight, lessThan(TaskPriority.high.weight));
    });
  });
}
