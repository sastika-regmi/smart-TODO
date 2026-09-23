import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../errors/failures.dart';
import '../utils/firebase_error_mapper.dart';

/// All Firebase Authentication and user-profile work.
///
/// UI-independent: this class never touches a `BuildContext`, never navigates,
/// and never stores passwords or tokens. Only Firebase holds credentials.
class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    } catch (_) {
      throw const AuthFailure('Authentication failed. Please try again.');
    }
  }

  /// Creates the account, records the display name on the Firebase user, and
  /// writes the matching `users/{uid}` profile document.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final name = fullName.trim();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'Your account was created but could not be loaded. Please sign in.',
        );
      }

      // Keep the Auth record and the Firestore profile in step. Both are
      // best-effort: the account already exists at this point, so a failure
      // here must not strand the user on a sign-up form they cannot resubmit.
      await user.updateDisplayName(name);
      await user.reload();
      await _writeUserProfile(user, name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Your account was created, but setup did not finish. Please sign in.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    } catch (_) {
      throw const AuthFailure('Could not sign out. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(mapAuthErrorCode(e.code));
    } catch (_) {
      throw const AuthFailure('Could not send the reset email. Please try again.');
    }
  }

  /// Writes `users/{uid}` with server timestamps.
  ///
  /// A single `set` rather than a read-then-merge: this runs once, at
  /// registration, so there is no existing document worth preserving — and the
  /// read it replaces was a round trip plus a race.
  Future<void> _writeUserProfile(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
        'uid': user.uid,
        'displayName': displayName,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // ponytail: best-effort. The account is already usable, and a failed
      // profile write must not block sign-up. Move to a retry queue if the
      // profile ever becomes load-bearing.
      debugPrint('AuthService: could not write user profile — $error');
    }
  }
}
