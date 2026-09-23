import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirmation_dialog.dart';

/// Account overview: who is signed in, and their task counts.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Sign out',
      message: 'You will need to sign in again to see your tasks.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;

    final succeeded = await auth.signOut();
    if (!context.mounted) return;

    // Return to the root either way, so the auth gate decides what to show.
    navigator.popUntil((route) => route.isFirst);

    if (succeeded) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Could not sign out. Please try again.'),
          showCloseIcon: true,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Narrow slices: a task being completed elsewhere must not rebuild the
    // whole account card, and vice versa.
    final name = context.select<AuthProvider, String>((a) => a.displayName);
    final email = context.select<AuthProvider, String>(
      (a) => a.user?.email ?? 'Not available',
    );
    final initial = context.select<AuthProvider, String>((a) => a.initial);
    final userId = context.select<AuthProvider, String>(
      (a) => a.user?.uid ?? '—',
    );
    final createdAt = context.select<AuthProvider, DateTime?>(
      (a) => a.user?.metadata.creationTime,
    );
    final stats = context.select<TaskProvider, _TaskStats>(
      (p) => _TaskStats(
        total: p.totalCount,
        pending: p.pendingCount,
        completed: p.completedCount,
        overdue: p.overdueCount,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ContentContainer(
        maxWidth: Responsive.maxFormWidth(context) + 120,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Member since ${AppDateUtils.formatDate(createdAt)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total',
                    value: stats.total,
                    icon: Icons.task_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Pending',
                    value: stats.pending,
                    icon: Icons.radio_button_unchecked,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Completed',
                    value: stats.completed,
                    icon: Icons.check_circle_outline,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Overdue',
                    value: stats.overdue,
                    icon: Icons.warning_amber_outlined,
                    color: scheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Account', style: theme.textTheme.titleMedium),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _InfoRow(label: 'Email', value: email),
                    const Divider(),
                    _InfoRow(label: 'User ID', value: userId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Structural equality so `context.select` only rebuilds on a count change.
class _TaskStats {
  const _TaskStats({
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
      other is _TaskStats &&
      other.total == total &&
      other.pending == pending &&
      other.completed == completed &&
      other.overdue == overdue;

  @override
  int get hashCode => Object.hash(total, pending, completed, overdue);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
