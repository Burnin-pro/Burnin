import 'package:firebase_auth/firebase_auth.dart';

/// Represents a logged-in staff member.
class StaffUser {
  final String uid;
  final String email;
  final String displayName;

  const StaffUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory StaffUser.fromFirebaseUser(User user) {
    return StaffUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
    );
  }

  StaffUser copyWith({String? displayName}) {
    return StaffUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
    );
  }
}
