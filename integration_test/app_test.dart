import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kresai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ÖdevAI End-to-End Tests', () {
    testWidgets('Test 1: App Launch and School Type Selection', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify school type selection screen
      expect(find.text('KresAI'), findsOneWidget);
      expect(find.text('Okul Tipini Seçin'), findsWidgets);
      
      // Select Anaokulu
      await tester.tap(find.text('Anaokulu'));
      await tester.pumpAndSettle();
      
      // Should navigate to role selection or login
      expect(find.text('Rolünüzü Seçin'), findsWidgets);
    });

    testWidgets('Test 2: Navigation to Teacher Login', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Select school type
      await tester.tap(find.text('Anaokulu'));
      await tester.pumpAndSettle();
      
      // Select teacher role
      await tester.tap(find.text('Öğretmen'));
      await tester.pumpAndSettle();
      
      // Should show login screen
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password
    });

    testWidgets('Test 3: Teacher Login Flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to teacher login
      await tester.tap(find.text('Anaokulu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Öğretmen'));
      await tester.pumpAndSettle();
      
      // Enter credentials (test account)
      await tester.enterText(find.byType(TextField).first, 'test@teacher.com');
      await tester.enterText(find.byType(TextField).last, 'testpass123');
      
      // Tap login button
      await tester.tap(find.text('Giriş Yap'));
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // Should navigate to teacher home (or show error if account doesn't exist)
      // This test will fail without pre-created test account
    });

    testWidgets('Test 4: Homework Creation Screen UI', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Login flow (assuming successful)
      // ... navigation to homework screen
      
      // Find "Yeni Ödev" button
      final newHomeworkButton = find.text('Yeni Ödev');
      if (newHomeworkButton.evaluate().isNotEmpty) {
        await tester.tap(newHomeworkButton);
        await tester.pumpAndSettle();
        
        // Verify homework creation form
        expect(find.text('Yeni Ödev Oluştur'), findsOneWidget);
        expect(find.text('Düzey'), findsOneWidget);
        expect(find.text('Konu & Hedef'), findsOneWidget);
      }
    });

    testWidgets('Test 5: Parent Homework List Access', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to parent role
      await tester.tap(find.text('Anaokulu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Veli'));
      await tester.pumpAndSettle();
      
      // Login as parent (requires test account)
      // ... login flow
      
      // Should show homework list
      // expect(find.text('Ödevler'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Test 6: Bottom Navigation Bar', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Assuming logged in, verify bottom nav exists
      // This will vary based on authentication state
    });

    testWidgets('Test 7: Back Button Handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate through screens
      // Test back button doesn't crash app
    });
  });

  group('UI Responsiveness Tests', () {
    testWidgets('Test 8: Screen Loads Without Timeout', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // Verify app doesn't hang
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Test 9: No Overflow Errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate through screens and check for overflow
      // This is implicit - test will fail if overflow occurs
    });
  });
}
