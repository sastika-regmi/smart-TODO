import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_scaffold.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final succeeded = await auth.signUp(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    // On success the AuthGate swaps this subtree out. On failure the screen
    // stays put with the entered values intact and the error shown inline.
    if (succeeded && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Join ${AppConstants.appName} and start organising',
      errorMessage: auth.error,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                maxLength: AppConstants.maxNameLength,
                validator: Validators.validateFullName,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Ada Lovelace',
                  prefixIcon: Icon(Icons.person_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
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
                autofillHints: const [AutofillHints.newPassword],
                helperText:
                    'At least ${AppConstants.minPasswordLength} characters',
                validator: Validators.validatePassword,
                onSubmitted: _confirmFocus.requestFocus,
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmController,
                label: 'Confirm password',
                enabled: !isLoading,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 24),
              SubmitButton(
                label: 'Create account',
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
              'Already have an account?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
