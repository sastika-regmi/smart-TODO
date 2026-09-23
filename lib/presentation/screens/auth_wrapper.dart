import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/error_view.dart';
import 'auth/sign_in_screen.dart';
import 'splash_screen.dart';
import 'tasks/task_list_screen.dart';

/// Decides what the app shows based on the authentication state.
///
/// Three distinct states, which the previous implementation collapsed into two
/// and so flashed the sign-in form at already-signed-in users on every cold
/// start:
///
///  * still resolving  -> splash
///  * signed out      -> sign in
///  * signed in       -> the protected task list
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isInitialized =
        context.select<AuthProvider, bool>((auth) => auth.isInitialized);
    final isSignedIn =
        context.select<AuthProvider, bool>((auth) => auth.user != null);
    final error = context.select<AuthProvider, String?>((auth) => auth.error);

    if (!isInitialized) {
      // An error before the first auth event means the listener itself failed;
      // retrying is the only way forward, so say so instead of spinning.
      if (error != null) {
        return Scaffold(
          body: ErrorView(
            message: error,
            icon: Icons.lock_outline,
            onRetry: () => Navigator.of(context).pushReplacement<void, void>(
              MaterialPageRoute<void>(builder: (_) => const AuthGate()),
            ),
          ),
        );
      }
      return const SplashScreen();
    }

    if (isSignedIn) return const TaskListScreen();

    return const SignInScreen();
  }
}
