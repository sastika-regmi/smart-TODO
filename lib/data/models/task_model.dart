import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task.dart';

/// Firestore representation of a [Task].
///
/// All reads are defensive: a document missing an optional field, or holding a
/// value of an unexpected type, must never crash the task list.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.dueDate,
  });

  /// Parses a Firestore document body.
  ///
  /// Takes the id and the raw map rather than a `DocumentSnapshot` so the
  /// parsing rules — including how malformed data is tolerated — are unit
  /// testable without a Firestore instance.
  factory TaskModel.fromMap({
    required String id,
    required Map<String, dynamic>? data,
  }) {
    final fields = data ?? const <String, dynamic>{};
    final createdAt = _readTimestamp(fields['createdAt']) ?? DateTime.now();

    return TaskModel(
      id: id,
      userId: _readString(fields['userId']) ?? '',
      title: _readString(fields['title']) ?? '',
      description: _readString(fields['description']),
      isCompleted: fields['isCompleted'] == true,
      priority: TaskPriority.fromString(_readString(fields['priority'])).value,
      createdAt: createdAt,
      // Fall back to createdAt so a partially written document still renders
      // in a sensible position instead of being dropped or crashing.
      updatedAt: _readTimestamp(fields['updatedAt']) ?? createdAt,
      completedAt: _readTimestamp(fields['completedAt']),
      dueDate: _readTimestamp(fields['dueDate']),
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      priority: task.priority.value,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: task.completedAt,
      dueDate: task.dueDate,
    );
  }

  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      userId: userId,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: TaskPriority.fromString(priority),
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      dueDate: dueDate,
    );
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    Object? description = _unsetModel,
    bool? isCompleted,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _unsetModel,
    Object? dueDate = _unsetModel,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: identical(description, _unsetModel)
          ? this.description
          : description as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _unsetModel)
          ? this.completedAt
          : completedAt as DateTime?,
      dueDate: identical(dueDate, _unsetModel) ? this.dueDate : dueDate as DateTime?,
    );
  }
}

const Object _unsetModel = Object();

String? _readString(Object? value) => value is String ? value : null;

/// Accepts a Firestore [Timestamp] and tolerates the `String`/`int` shapes that
/// occasionally appear in hand-seeded data or older documents.
DateTime? _readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
