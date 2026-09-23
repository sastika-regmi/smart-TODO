import 'package:flutter/material.dart';

import '../../../core/utils/task_query.dart';

/// Status and priority filters plus the sort menu, in one compact row.
///
/// Replaces the previous pair of modal bottom sheets: filtering used to require
/// opening a sheet, changing a chip, then pressing a decorative "Apply" button.
/// Chips now apply immediately and the sheet is gone.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.query,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  final TaskQuery query;
  final ValueChanged<TaskStatusFilter> onStatusChanged;
  final ValueChanged<TaskPriorityFilter> onPriorityChanged;
  final void Function(TaskSort sort, TaskSortOrder order) onSortChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in TaskStatusFilter.values) ...[
                  FilterChip(
                    label: Text(status.label),
                    selected: query.status == status,
                    showCheckmark: false,
                    onSelected: (_) => onStatusChanged(status),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: scheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                for (final priority in TaskPriorityFilter.values) ...[
                  FilterChip(
                    label: Text(priority.label),
                    selected: query.priority == priority,
                    showCheckmark: false,
                    onSelected: (_) => onPriorityChanged(priority),
                  ),
                  const SizedBox(width: 8),
                ],
                if (query.isActive)
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Clear'),
                    onPressed: onClearFilters,
                  ),
              ],
            ),
          ),
        ),
        _SortMenuButton(query: query, onSortChanged: onSortChanged),
      ],
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({required this.query, required this.onSortChanged});

  final TaskQuery query;
  final void Function(TaskSort sort, TaskSortOrder order) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortChoice>(
      tooltip: 'Sort tasks',
      icon: const Icon(Icons.sort),
      initialValue: _SortChoice(query.sort, query.order),
      onSelected: (choice) => onSortChanged(choice.sort, choice.order),
      itemBuilder: (context) => [
        for (final sort in TaskSort.values) ...[
          if (sort == TaskSort.createdDate) ...[
            // "Newest first" / "Oldest first" are what people actually look
            // for, rather than an abstract ascending/descending toggle.
            _item(sort, TaskSortOrder.descending, 'Newest first'),
            _item(sort, TaskSortOrder.ascending, 'Oldest first'),
          ] else if (sort == TaskSort.dueDate) ...[
            _item(sort, TaskSortOrder.ascending, 'Due soonest'),
            _item(sort, TaskSortOrder.descending, 'Due latest'),
          ] else ...[
            _item(sort, TaskSortOrder.descending, '${sort.label}: high to low'),
            _item(sort, TaskSortOrder.ascending, '${sort.label}: low to high'),
          ],
          if (sort != TaskSort.values.last) const PopupMenuDivider(),
        ],
      ],
    );
  }

  PopupMenuItem<_SortChoice> _item(
    TaskSort sort,
    TaskSortOrder order,
    String label,
  ) {
    final selected = query.sort == sort && query.order == order;
    return PopupMenuItem<_SortChoice>(
      value: _SortChoice(sort, order),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Value type so a menu entry can carry both the field and the direction.
class _SortChoice {
  const _SortChoice(this.sort, this.order);

  final TaskSort sort;
  final TaskSortOrder order;

  @override
  bool operator ==(Object other) =>
      other is _SortChoice && other.sort == sort && other.order == order;

  @override
  int get hashCode => Object.hash(sort, order);
}
