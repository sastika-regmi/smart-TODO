import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/task.dart';
import 'priority_style.dart';

/// A single task row.
///
/// Presentational only — every interaction is a callback, so the card holds no
/// provider reference and rebuilds only when its own [task] changes.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.enableSwipeToDelete = false,
  });

  final Task task;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Swipe-to-delete is offered on compact layouts, where tapping a small icon
  /// is the slower path. Desktop and tablet keep the explicit button.
  final bool enableSwipeToDelete;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    if (!enableSwipeToDelete) return card;

    return Dismissible(
      key: ValueKey<String>('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(context),
      // Confirm through the same dialog as the delete button so a swipe can
      // never remove a task silently.
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: card,
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: task.isCompleted
                      ? 'Mark "${task.title}" as not completed'
                      : 'Mark "${task.title}" as completed',
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => onToggle(value ?? false),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Semantics(
                        button: true,
                        label: _semanticLabel(isOverdue),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? scheme.onSurfaceVariant
                                          : scheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PriorityBadge(priority: task.priority),
                              ],
                            ),
                            if (task.hasDescription) ...[
                              const SizedBox(height: 6),
                              Text(
                                task.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _MetaRow(task: task, isOverdue: isOverdue),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit task',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                  tooltip: 'Delete task',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _semanticLabel(bool isOverdue) {
    final parts = <String>[
      'Task: ${task.title}',
      task.isCompleted ? 'Completed' : 'Pending',
      'Priority: ${task.priority.displayName}',
      if (task.dueDate != null) AppDateUtils.describeDueDate(task.dueDate!),
      if (isOverdue) 'Overdue',
    ];
    return '${parts.join('. ')}. Open details';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.task, required this.isOverdue});

  final Task task;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final timestamp = task.isCompleted && task.completedAt != null
        ? 'Completed ${AppDateUtils.formatRelativeDate(task.completedAt!)}'
        : 'Created ${AppDateUtils.formatRelativeDate(task.createdAt)}';

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Meta(
          icon: task.isCompleted
              ? Icons.check_circle_outline
              : Icons.schedule_outlined,
          text: timestamp,
          color: scheme.onSurfaceVariant,
        ),
        if (task.dueDate != null)
          _Meta(
            icon: Icons.event_outlined,
            text: AppDateUtils.describeDueDate(task.dueDate!),
            color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
            bold: isOverdue,
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    required this.color,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}

/// Small colour-coded priority pill, themed from the [ColorScheme].
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  final TaskPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = priority.color(scheme);

    return Semantics(
      label: 'Priority: ${priority.displayName}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(priority.icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              priority.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
