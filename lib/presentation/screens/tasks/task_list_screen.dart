import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/utils/task_query.dart';
import '../../../domain/entities/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_statistics.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTaskForm({Task? task}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)),
    );
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final taskProvider = context.read<TaskProvider>();

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete task',
      message: 'Delete "${task.title}"? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final error = await taskProvider.deleteTask(task.id);
    if (!mounted) return;

    _showResult(error, successMessage: 'Task deleted');
  }

  Future<void> _toggle(Task task) async {
    final taskProvider = context.read<TaskProvider>();
    final error = await taskProvider.toggleTaskCompletion(
      task.id,
      !task.isCompleted,
    );
    if (!mounted || error == null) return;
    _showResult(error);
  }

  void _showResult(String? error, {String? successMessage}) {
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    // Replace rather than stack, so rapid actions cannot queue up snackbars.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage ?? ''),
        backgroundColor: error == null ? null : scheme.errorContainer,
        showCloseIcon: error != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = Responsive.isExpanded(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart ToDo'),
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isExpanded
          ? Row(
              children: [
                const _NavRail(),
                const VerticalDivider(width: 1),
                Expanded(child: _buildBody(context)),
              ],
            )
          : _buildBody(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTaskForm,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Each of these selects a narrow slice, so a change to one does not rebuild
    // the others. Watching the whole provider here — as the previous version
    // did — rebuilt the app bar, rail and list on every keystroke.
    final greeting = context.select<AuthProvider, String>(
      (auth) => auth.displayName,
    );
    final isInitialLoading =
        context.select<TaskProvider, bool>((p) => p.isInitialLoading);
    final error = context.select<TaskProvider, String?>((p) => p.error);
    final hasAnyTasks = context.select<TaskProvider, bool>(
      (p) => p.hasAnyTasks,
    );
    final query = context.select<TaskProvider, TaskQuery>((p) => p.query);
    final tasks = context.select<TaskProvider, List<Task>>((p) => p.tasks);
    final stats = context.select<TaskProvider, _Stats>(
      (p) => _Stats(
        total: p.totalCount,
        pending: p.pendingCount,
        completed: p.completedCount,
        overdue: p.overdueCount,
      ),
    );

    if (isInitialLoading) {
      return const LoadingView(message: 'Loading your tasks…');
    }

    if (error != null && !hasAnyTasks) {
      return ErrorView(
        message: error,
        onRetry: () => context.read<TaskProvider>().retry(),
      );
    }

    return ContentContainer(
      padding: Responsive.horizontalPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Greeting(name: greeting),
          const SizedBox(height: 16),
          TaskStatistics(
            total: stats.total,
            pending: stats.pending,
            completed: stats.completed,
            overdue: stats.overdue,
          ),
          const SizedBox(height: 16),
          TaskSearchBar(
            controller: _searchController,
            onChanged: context.read<TaskProvider>().search,
          ),
          const SizedBox(height: 12),
          TaskFilterBar(
            query: query,
            onStatusChanged: context.read<TaskProvider>().setStatusFilter,
            onPriorityChanged: context.read<TaskProvider>().setPriorityFilter,
            onSortChanged: (sort, order) =>
                context.read<TaskProvider>().setSort(sort, order: order),
            onClearFilters: () {
              _searchController.clear();
              context.read<TaskProvider>().clearFilters();
            },
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildList(context, tasks, hasAnyTasks)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Task> tasks,
    bool hasAnyTasks,
  ) {
    if (tasks.isEmpty) {
      // Distinguish "nothing exists" from "nothing matched": the actions that
      // help are different, and offering "add your first task" to someone with
      // a typo in the search box is unhelpful.
      return hasAnyTasks
          ? EmptyState.noMatches(
              onClearFilters: () {
                _searchController.clear();
                context.read<TaskProvider>().clearFilters();
              },
            )
          : EmptyState.noTasks(onAddTask: _openTaskForm);
    }

    final swipeToDelete = Responsive.isCompact(context);

    return ListView.builder(
      // Room for the FAB so the last card is never hidden behind it.
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          key: ValueKey<String>(task.id),
          task: task,
          enableSwipeToDelete: swipeToDelete,
          onTap: () => _openTaskDetail(task),
          onToggle: (_) => _toggle(task),
          onEdit: () => _openTaskForm(task: task),
          onDelete: () => _confirmDelete(task),
        );
      },
    );
  }
}

/// Compact record of the four counts. A record has structural equality, so
/// `context.select` only rebuilds the statistics when a count actually changes.
class _Stats {
  const _Stats({
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
  bool operator ==(Object other) =>
      other is _Stats &&
      other.total == total &&
      other.pending == pending &&
      other.completed == completed &&
      other.overdue == overdue;

  @override
  int get hashCode => Object.hash(total, pending, completed, overdue);
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final partOfDay = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$partOfDay, $name',
          style: theme.textTheme.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          "Here's what needs doing.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Desktop side navigation.
///
/// Only "Tasks" is a destination *within* this screen; Settings and Profile are
/// separate pages, so they live in the rail's trailing slot as actions. The
/// previous version listed all three as destinations and set the selected index
/// to whichever was tapped — leaving "Settings" highlighted forever, because
/// the pushed page never reported back.
class _NavRail extends StatelessWidget {
  const _NavRail();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(Icons.task),
          label: Text('Tasks'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Profile',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  icon: Icon(Icons.settings_outlined, color: scheme.onSurfaceVariant),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
