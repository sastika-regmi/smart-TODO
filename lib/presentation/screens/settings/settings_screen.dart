import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = 'v${info.version}+${info.buildNumber}');
    } catch (_) {
      // Version is decorative — a platform channel failure must not break the
      // screen, so it simply stays hidden.
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Sign out',
      message: 'You will need to sign in again to see your tasks.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !mounted) return;

    final succeeded = await auth.signOut();
    if (!mounted) return;

    // Return to the root either way, so the auth gate decides what to show.
    // Without this the settings page stays on top of the sign-in screen.
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

  void _showAbout() {
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: _version?.replaceFirst('v', ''),
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.checklist_rounded,
          size: 30,
          color: theme.colorScheme.primary,
        ),
      ),
      children: [
        const Text(AppConstants.appTagline),
        const SizedBox(height: 12),
        const Text('Built with Flutter, Firebase, and Provider.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedMode = context.select<ThemeProvider, AppThemeMode>(
      (p) => p.themeMode,
    );
    final email = context.select<AuthProvider, String>(
      (auth) => auth.user?.email ?? 'Not available',
    );
    final initial = context.select<AuthProvider, String>(
      (auth) => auth.initial,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentContainer(
        maxWidth: Responsive.maxFormWidth(context) + 120,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const _SectionHeader(title: 'Appearance'),
            Card(
              child: Column(
                children: [
                  for (final mode in AppThemeMode.values) ...[
                    if (mode != AppThemeMode.values.first)
                      const Divider(height: 1),
                    ListTile(
                      leading: Icon(mode.icon),
                      title: Text(mode.label),
                      subtitle: Text(mode.description),
                      selected: selectedMode == mode,
                      trailing: Icon(
                        selectedMode == mode
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedMode == mode
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      onTap: () => context
                          .read<ThemeProvider>()
                          .setThemeMode(mode),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(email),
                    subtitle: const Text('Signed in'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: scheme.error),
                    title: Text(
                      'Sign out',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'About'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About ${AppConstants.appName}'),
                subtitle: Text(_version ?? AppConstants.appTagline),
                onTap: _showAbout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
