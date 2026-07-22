import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/staff_user.dart';

/// Wraps Firebase Auth — sign in, sign out, change password.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'staff_users';

  /// Stream of auth state changes — null when logged out.
  Stream<StaffUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection(_collection).doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          return StaffUser.fromMap(doc.data()!, doc.id);
        }
      } catch (_) {}
      return StaffUser.fromFirebaseUser(user);
    });
  }

  /// Current user asynchronously since it fetches from Firestore.
  Future<StaffUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return StaffUser.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}
    return StaffUser.fromFirebaseUser(user);
  }

  /// Current user synchronously (only contains Auth details, not DB details).
  StaffUser? get currentUserAuthOnly {
    final user = _auth.currentUser;
    return user == null ? null : StaffUser.fromFirebaseUser(user);
  }

  /// Sign in with email.
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
    
    final user = credential.user!;
    final docRef = _firestore.collection(_collection).doc(user.uid);
    final docSnap = await docRef.get();
    
    if (!docSnap.exists) {
      // Auto-create user in Firestore on first login
      final newStaff = StaffUser.fromFirebaseUser(user);
      await docRef.set(newStaff.toMap());
      return newStaff;
    } else {
      return StaffUser.fromMap(docSnap.data()!, docSnap.id);
    }
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Change password — requires recent sign-in.
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
