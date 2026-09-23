/// Pure-Dart task entity.
///
/// Deliberately free of any Flutter/UI import: the domain layer must not know
/// about [Color], [IconData] or widgets. Presentation concerns such as the
/// priority colour and icon live in `presentation/widgets/priority_style.dart`.
enum TaskPriority {
  low,
  medium,
  high;

  /// Stable string used for Firestore persistence. Never rename without a
  /// migration — existing documents store these exact values.
  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  /// Sort weight: higher means more urgent.
  int get weight => index;

  static TaskPriority fromString(String? value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

/// Sentinel used by [Task.copyWith] so callers can explicitly pass `null` to
/// clear a nullable field.
const Object _unset = Object();

class Task {
  const Task({
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

  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  /// Overdue is only meaningful for an unfinished task that has a due date.
  ///
  /// Takes `now` explicitly so the behaviour is deterministic and testable.
  bool isOverdueAt(DateTime now) {
    final due = dueDate;
    if (due == null || isCompleted) return false;
    // Compare on calendar days: a task due today is not yet overdue.
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfDue = DateTime(due.year, due.month, due.day);
    return startOfDue.isBefore(startOfToday);
  }

  bool get isOverdue => isOverdueAt(DateTime.now());

  /// Passing `null` for [description], [completedAt] or [dueDate] clears the
  /// field; omitting the argument leaves it unchanged.
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    Object? description = _unset,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _unset,
    Object? dueDate = _unset,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          identical(completedAt, _unset) ? this.completedAt : completedAt as DateTime?,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.completedAt == completedAt &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        description,
        isCompleted,
        priority,
        createdAt,
        updatedAt,
        completedAt,
        dueDate,
      );

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted, priority: $priority)';
}
