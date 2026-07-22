import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents a logged-in staff member.
class StaffUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const StaffUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'staff',
    this.isActive = true,
    this.createdAt,
  });

  factory StaffUser.fromFirebaseUser(User user) {
    return StaffUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
      role: 'staff',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  factory StaffUser.fromMap(Map<String, dynamic> map, String documentId) {
    return StaffUser(
      uid: documentId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Staff',
      role: map['role'] as String? ?? 'staff',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  StaffUser copyWith({
    String? displayName,
    String? role,
    bool? isActive,
  }) {
    return StaffUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
