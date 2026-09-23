import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // All async setup happens before the first frame, so the app never shows an
  // unstyled or half-wired screen. The native splash covers this window.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // The usual cause is an unconfigured or mistyped Firebase project. Showing
    // a real message beats the white screen this would otherwise produce.
    runApp(_StartupFailureApp(details: '$error'));
    return;
  }

  final providers = await initializeDependencies();
  runApp(SmartTodoApp(providers: providers));
}

class SmartTodoApp extends StatelessWidget {
  const SmartTodoApp({super.key, required this.providers});

  final List<SingleChildWidget> providers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      // Only the theme is consumed here, so switching theme rebuilds the
      // MaterialApp and nothing else.
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.flutterThemeMode,
            home: const AuthGate(),
            builder: (context, child) {
              // Clamp extreme text scaling rather than replacing the user's
              // setting outright — the platform scale still applies within it.
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.6,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shown only when Firebase itself could not start.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase could not start',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check that lib/firebase_options.dart matches your Firebase '
                    'project and that Email/Password sign-in is enabled.\n'
                    'See the README for the setup steps.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
