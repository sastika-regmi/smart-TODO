import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/task_card.dart';
import 'task_form_screen.dart';

/// Read-only view of one task.
///
/// Identified by id and looked up from the provider on every build, so the
/// screen reflects the live Firestore document. The previous version held a
/// `Task` value captured at navigation time, which meant that completing or
/// editing a task left this screen showing the old data until it was closed.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final task = context.select<TaskProvider, Task?>(
      (p) => p.taskById(taskId),
    );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('This task no longer exists.'),
          ),
        ),
      );
    }

    return _TaskDetailView(task: task);
  }
}

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView({required this.task});

  final Task task;

  Future<void> _toggle(BuildContext context) async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.toggleTaskCompletion(
      task.id,
      !task.isCompleted,
    );
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<TaskProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete task',
      message: 'Delete "${task.title}"? This cannot be undone.',
    );
    if (!confirmed) return;

    final error = await provider.deleteTask(task.id);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOverdue = task.isOverdue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          IconButton(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => TaskFormScreen(task: task),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentContainer(
          maxWidth: Responsive.maxFormWidth(context) + 120,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? scheme.onSurfaceVariant : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(isCompleted: task.isCompleted),
                  PriorityBadge(priority: task.priority),
                  if (isOverdue) const _OverdueChip(),
                ],
              ),
              const SizedBox(height: 24),
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                task.hasDescription ? task.description! : 'No description.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: task.hasDescription
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  fontStyle: task.hasDescription ? null : FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Due date',
                        value: task.dueDate == null
                            ? 'None'
                            : '${AppDateUtils.formatDueDate(task.dueDate!)}'
                                ' · ${AppDateUtils.describeDueDate(task.dueDate!)}',
                        emphasise: isOverdue,
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.add_circle_outline,
                        label: 'Created',
                        value: AppDateUtils.formatDateTime(task.createdAt),
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.update_outlined,
                        label: 'Last updated',
                        value: AppDateUtils.formatDateTime(task.updatedAt),
                      ),
                      if (task.completedAt != null) ...[
                        const Divider(),
                        _DetailRow(
                          icon: Icons.check_circle_outline,
                          label: 'Completed',
                          value: AppDateUtils.formatDateTime(task.completedAt!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggle(context),
                  icon: Icon(
                    task.isCompleted
                        ? Icons.undo_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(task.isCompleted ? 'Reopen' : 'Complete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskFormScreen(task: task),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: isCompleted ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
      label: Text(isCompleted ? 'Completed' : 'Pending'),
      backgroundColor:
          isCompleted ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
      side: BorderSide(
        color: isCompleted ? scheme.secondary : scheme.outlineVariant,
      ),
    );
  }
}

class _OverdueChip extends StatelessWidget {
  const _OverdueChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.warning_amber_outlined, size: 18, color: scheme.error),
      label: const Text('Overdue'),
      backgroundColor: scheme.errorContainer,
      side: BorderSide(color: scheme.error),
      labelStyle: TextStyle(color: scheme.onErrorContainer),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: emphasise ? scheme.error : scheme.onSurface,
                    fontWeight: emphasise ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
