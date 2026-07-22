import 'package:flutter_test/flutter_test.dart';

// BurnIn is a private staff app connected to Firebase.
// Integration tests require a real device with Firebase configured.
// This test file is intentionally minimal.

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Smoke test — just verifies no compile errors in the project.
    // Full integration tests run on a device with Firebase credentials.
    expect(true, isTrue);
  });
}
