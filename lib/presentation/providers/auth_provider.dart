import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _subscription = _authService.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (Object error) {
        _error = 'Could not reach the authentication service. Please try again.';
        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? _user;
  User? get user => _user;

  /// True once Firebase has reported the initial auth state.
  ///
  /// Until then `user == null` only means "not known yet", which is why the
  /// UI must show a loading state rather than the sign-in screen — otherwise a
  /// returning signed-in user sees the sign-in form flash on every cold start.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isSignedIn => _user != null;

  String get displayName {
    final name = _user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = _user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'there';
  }

  /// First letter of the display name, for avatars. Never indexes blindly —
  /// an empty string would otherwise throw a RangeError.
  String get initial {
    final name = displayName.trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _run(() => _authService.signIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _run(
      () => _authService.register(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    return _run(() => _authService.sendPasswordResetEmail(email));
  }

  /// Returns whether the sign-out succeeded, so callers can decide whether to
  /// navigate away without guessing from a stale user object.
  Future<bool> signOut() => _run(_authService.signOut);

  /// Runs an auth action, mapping failures to a user-facing message.
  /// Returns whether it succeeded so the caller can drive its own UI.
  Future<bool> _run(Future<void> Function() action) async {
    // Guard against double submissions from a fast double tap.
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    var succeeded = false;
    try {
      await action();
      succeeded = true;
    } on Failure catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    } finally {
      // Exactly one notification per action, covering both outcomes — a
      // spinner left behind by a success path that never notified is a
      // classic stuck-loading-state bug.
      _isLoading = false;
      notifyListeners();
    }
    return succeeded;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
