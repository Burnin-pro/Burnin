import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a stream of network connectivity states.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// A boolean provider that returns true if the device is currently offline.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStreamProvider);
  return connectivityAsync.maybeWhen(
    data: (results) {
      // If the results contain only 'none', we are offline.
      if (results.isNotEmpty && results.every((r) => r == ConnectivityResult.none)) {
        return true;
      }
      return false;
    },
    orElse: () => false,
  );
});
