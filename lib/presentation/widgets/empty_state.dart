import 'package:flutter/material.dart';

/// Empty-list placeholder.
///
/// Two variants matter, and they need different copy: nothing exists yet
/// versus nothing matched the current search and filters. Offering
/// "Add your first task" when the user has 40 tasks and a typo in the search
/// box is confusing.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  /// No tasks exist at all.
  factory EmptyState.noTasks({required VoidCallback onAddTask}) {
    return EmptyState(
      icon: Icons.playlist_add_rounded,
      title: 'No tasks yet',
      message: 'Add your first task to get started.',
      actionLabel: 'Add task',
      onAction: onAddTask,
    );
  }

  /// Tasks exist, but none match the current query.
  factory EmptyState.noMatches({required VoidCallback onClearFilters}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No matching tasks',
      message: 'Try a different search term, or clear your filters.',
      actionLabel: 'Clear filters',
      onAction: onClearFilters,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
              if (onSecondaryAction != null && secondaryActionLabel != null)
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
