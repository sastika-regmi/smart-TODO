import '../constants/app_constants.dart';

/// Form validation shared by the auth and task forms.
///
/// Pure functions returning an error message or null, so every rule is unit
/// testable without a widget tree.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$');

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Strength rules for *creating* an account.
  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }
    if (password.length > AppConstants.maxPasswordLength) {
      return 'Password must be at most ${AppConstants.maxPasswordLength} characters.';
    }
    return null;
  }

  /// Sign-in only checks that something was typed.
  ///
  /// Applying the sign-up strength rules here would lock out any account whose
  /// password predates a rule change, with an error the user cannot act on.
  static String? validatePasswordPresence(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Full name is required.';
    if (name.length > AppConstants.maxNameLength) {
      return 'Name must be at most ${AppConstants.maxNameLength} characters.';
    }
    return null;
  }

  static String? validateTaskTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Task title is required.';
    if (title.length > AppConstants.maxTaskTitleLength) {
      return 'Title must be at most ${AppConstants.maxTaskTitleLength} characters.';
    }
    return null;
  }

  static String? validateTaskDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.length > AppConstants.maxTaskDescriptionLength) {
      return 'Description must be at most ${AppConstants.maxTaskDescriptionLength} characters.';
    }
    return null;
  }
}
