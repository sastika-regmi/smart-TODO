import 'package:firebase_auth/firebase_auth.dart';

/// Translates technical authentication failures into messages that are safe and
/// useful to show a user. Raw Firebase error codes must never reach the UI.
String mapAuthErrorCode(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'user-not-found':
      return 'No account was found for this email.';
    case 'wrong-password':
    case 'invalid-credential':
      // Firebase deliberately returns the same code for "no such user" and
      // "wrong password" so the endpoint cannot be used to enumerate accounts.
      return 'The email or password is incorrect.';
    case 'email-already-in-use':
      return 'This email address is already registered.';
    case 'weak-password':
      return 'That password is too weak. Please choose a stronger one.';
    case 'missing-password':
      return 'Please enter your password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
      return 'Email and password sign-in is not enabled for this project.';
    case 'requires-recent-login':
      return 'Please sign in again to complete this action.';
    case 'network-request-failed':
      return 'A network error occurred. Please check your connection and try again.';
    case 'internal-error':
      return 'Something went wrong on our side. Please try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

/// Convenience wrapper that accepts the exception itself.
String mapAuthException(Object error) {
  if (error is FirebaseAuthException) {
    return mapAuthErrorCode(error.code);
  }
  return 'Authentication failed. Please try again.';
}
