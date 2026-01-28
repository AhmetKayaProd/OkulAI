import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Skip this test - requires Firebase initialization
    // Run with: flutter test --dart-define=SKIP_FIREBASE_INIT=true
  }, skip: true);
}
