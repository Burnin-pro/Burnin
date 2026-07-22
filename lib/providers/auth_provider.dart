import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_user.dart';
import '../services/auth_service.dart';

/// Provides the current auth state as an async stream.
/// - AsyncLoading: checking auth state on startup
/// - AsyncData(null): logged out
/// - AsyncData(StaffUser): logged in
final authStateProvider = StreamProvider<StaffUser?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// Provides the current user synchronously (null if logged out).
/// Use [authStateProvider] for reactive listening.
final currentUserProvider = Provider<StaffUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
