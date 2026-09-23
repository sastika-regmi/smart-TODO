import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_scaffold.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    // On success the AuthGate swaps in the task list; this screen is disposed,
    // so there is nothing to navigate to from here.
    await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _openSignUp() async {
    context.read<AuthProvider>().clearError();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to ${AppConstants.appName}',
      errorMessage: auth.error,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                validator: Validators.validateEmail,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                label: 'Password',
                enabled: !isLoading,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                validator: Validators.validatePasswordPresence,
                onSubmitted: _submit,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _showForgotPasswordDialog,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              SubmitButton(
                label: 'Sign In',
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton(
              onPressed: isLoading ? null : _openSignUp,
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(dialogContext).pop();
              final sent = await auth.sendPasswordResetEmail(
                emailController.text,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    sent
                        ? 'Password reset email sent.'
                        : auth.error ?? 'Could not send the reset email.',
                  ),
                ),
              );
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    emailController.dispose();
  }
}
