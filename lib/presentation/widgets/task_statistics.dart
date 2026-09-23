import 'package:flutter/material.dart';

/// Read-only task counts for the dashboard.
///
/// Takes plain numbers rather than the provider, so it is a pure presentational
/// widget: it rebuilds only when a count actually changes, and it is trivial to
/// test or preview without any Firebase wiring.
class TaskStatistics extends StatelessWidget {
  const TaskStatistics({
    super.key,
    required this.total,
    required this.pending,
    required this.completed,
    required this.overdue,
  });

  final int total;
  final int pending;
  final int completed;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        const spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final scheme = Theme.of(context).colorScheme;

        final tiles = <Widget>[
          _StatTile(
            label: 'Total',
            value: total,
            icon: Icons.list_alt_outlined,
            color: scheme.primary,
            width: tileWidth,
          ),
          _StatTile(
            label: 'Pending',
            value: pending,
            icon: Icons.pending_outlined,
            color: scheme.secondary,
            width: tileWidth,
          ),
          _StatTile(
            label: 'Completed',
            value: completed,
            icon: Icons.check_circle_outline,
            color: scheme.tertiary,
            width: tileWidth,
          ),
          _StatTile(
            label: 'Overdue',
            value: overdue,
            icon: Icons.warning_amber_outlined,
            color: overdue > 0 ? scheme.error : scheme.outline,
            width: tileWidth,
            emphasised: overdue > 0,
          ),
        ];

        return Wrap(spacing: spacing, runSpacing: spacing, children: tiles);
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
    this.emphasised = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final double width;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: RepaintBoundary(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$value',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: emphasised ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
