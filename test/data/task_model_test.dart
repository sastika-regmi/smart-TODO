import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/data/models/task_model.dart';
import 'package:smart_todo/domain/entities/task.dart';

import '../helpers/fakes.dart';

void main() {
  final created = DateTime(2026, 1, 1, 9);

  group('TaskModel.toFirestore', () {
    test('writes every field the security rules validate', () {
      final model = TaskModel.fromEntity(
        buildTask(description: 'Details', dueDate: DateTime(2026, 2, 1)),
      );

      final map = model.toFirestore();

      expect(
        map.keys.toSet(),
        {
          'userId',
          'title',
          'description',
          'isCompleted',
          'priority',
          'dueDate',
          'createdAt',
          'updatedAt',
          'completedAt',
        },
      );
      expect(map['userId'], 'user-1');
      expect(map['title'], 'Test task');
      expect(map['description'], 'Details');
      expect(map['isCompleted'], isFalse);
      expect(map['priority'], 'medium');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['dueDate'], isA<Timestamp>());
      expect(map['completedAt'], isNull);
    });

    test('stores the priority as its string value, not the enum index', () {
      final map =
          TaskModel.fromEntity(buildTask(priority: TaskPriority.high))
              .toFirestore();
      expect(map['priority'], 'high');
    });
  });

  group('TaskModel.fromMap', () {
    test('parses a well-formed document', () {
      final model = TaskModel.fromMap(
        id: 'task-9',
        data: <String, dynamic>{
          'userId': 'user-1',
          'title': 'Write the report',
          'description': 'Before Friday',
          'isCompleted': true,
          'priority': 'high',
          'createdAt': Timestamp.fromDate(created),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
          'completedAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
          'dueDate': Timestamp.fromDate(DateTime(2026, 1, 5)),
        },
      );

      expect(model.id, 'task-9');
      expect(model.userId, 'user-1');
      expect(model.title, 'Write the report');
      expect(model.description, 'Before Friday');
      expect(model.isCompleted, isTrue);
      expect(model.priority, 'high');
      expect(model.createdAt, created);
      expect(model.dueDate, DateTime(2026, 1, 5));
      expect(model.completedAt, DateTime(2026, 1, 3));
    });

    test('survives a null document body', () {
      final model = TaskModel.fromMap(id: 'empty', data: null);

      expect(model.id, 'empty');
      expect(model.userId, '');
      expect(model.title, '');
      expect(model.description, isNull);
      expect(model.isCompleted, isFalse);
      expect(model.priority, 'medium');
      expect(model.dueDate, isNull);
    });

    test('ignores values of the wrong type instead of throwing', () {
      // Hand-seeded or legacy documents are the realistic source of this, and a
      // single bad row must not take down the whole task list.
      final model = TaskModel.fromMap(
        id: 'bad',
        data: <String, dynamic>{
          'userId': 42,
          'title': <String>['not', 'a', 'string'],
          'description': 7,
          'isCompleted': 'yes',
          'priority': 'nonsense',
          'createdAt': false,
          'updatedAt': 12345,
          'dueDate': 'also not a date',
        },
      );

      expect(model.userId, '');
      expect(model.title, '');
      expect(model.description, isNull);
      expect(model.isCompleted, isFalse);
      expect(model.priority, 'medium');
      expect(model.dueDate, isNull);
    });

    test('accepts String and int timestamps from legacy documents', () {
      final model = TaskModel.fromMap(
        id: 'legacy',
        data: <String, dynamic>{
          'createdAt': '2026-01-01T09:00:00.000',
          'updatedAt': DateTime(2026, 1, 2).millisecondsSinceEpoch,
        },
      );

      expect(model.createdAt, DateTime(2026, 1, 1, 9));
      expect(model.updatedAt, DateTime(2026, 1, 2));
    });

    test('falls back to createdAt when updatedAt is missing', () {
      final model = TaskModel.fromMap(
        id: 'partial',
        data: <String, dynamic>{'createdAt': Timestamp.fromDate(created)},
      );

      expect(model.updatedAt, created);
    });

    test('manufactures a createdAt when the field is absent', () {
      // Never null: callers sort and format this, and a null would be a crash
      // waiting for the one document that lacks it.
      expect(TaskModel.fromMap(id: 'x', data: const {}).createdAt, isNotNull);
    });
  });

  group('round trip', () {
    test('entity -> model -> entity preserves every field', () {
      final original = buildTask(
        id: 'task-3',
        description: 'Round trip',
        priority: TaskPriority.low,
        isCompleted: true,
        completedAt: DateTime(2026, 1, 4),
        dueDate: DateTime(2026, 1, 9),
      );

      final restored = TaskModel.fromMap(
        id: original.id,
        data: TaskModel.fromEntity(original).toFirestore(),
      ).toEntity();

      expect(restored, original);
    });
  });

  group('TaskModel.copyWith', () {
    test('clears nullable fields when null is passed', () {
      final model = TaskModel.fromEntity(
        buildTask(description: 'x', dueDate: DateTime(2026, 2, 2)),
      );

      final cleared = model.copyWith(description: null, dueDate: null);

      expect(cleared.description, isNull);
      expect(cleared.dueDate, isNull);
      expect(cleared.title, model.title);
    });

    test('keeps nullable fields when the argument is omitted', () {
      final model = TaskModel.fromEntity(buildTask(dueDate: DateTime(2026, 2, 2)));
      expect(model.copyWith(title: 'New').dueDate, DateTime(2026, 2, 2));
    });
  });
}
