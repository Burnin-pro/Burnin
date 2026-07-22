import 'package:firebase_auth/firebase_auth.dart';

import '../models/staff_user.dart';

/// Wraps Firebase Auth — sign in, sign out, change password.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  /// Stream of auth state changes — null when logged out.
  Stream<StaffUser?> get authStateChanges {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : StaffUser.fromFirebaseUser(user),
        );
  }

  /// Current user synchronously (null if not logged in).
  StaffUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : StaffUser.fromFirebaseUser(user);
  }

  /// Sign in with email (staff emails pre-created in Firebase console).
  Future<StaffUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Sign in returned null user.',
      );
    }
    return StaffUser.fromFirebaseUser(credential.user!);
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Change password — requires recent sign-in (re-auth handled by caller
  /// if FirebaseAuthException code == 'requires-recent-login').
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in.');
    await user.updatePassword(newPassword);
  }

  /// Re-authenticate before sensitive operations.
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in.');
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Friendly error message from FirebaseAuthException.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please log out and log back in to change your password.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
