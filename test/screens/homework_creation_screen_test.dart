import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/screens/teacher/homework_creation_screen.dart';

void main() {
  group('HomeworkCreationScreen Widget Tests', () {
    testWidgets('renders correctly with all form elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeworkCreationScreen(),
        ),
      );

      // Verify screen title
      expect(find.text('Yeni Ödev Oluştur'), findsOneWidget);

      // Verify form elements exist
      expect(find.text('Düzey'), findsOneWidget);
      expect(find.text('Konu & Hedef'), findsOneWidget);
      expect(find.text('Zaman Aralığı'), findsOneWidget);
      expect(find.text('Tahmini Süre'), findsOneWidget);
      expect(find.text('Zorluk Seviyesi'), findsOneWidget);
      expect(find.text('Format Tercihleri'), findsOneWidget);

      // Verify action button
      expect(find.text('AI ile Ödev Üret'), findsOneWidget);
    });

    testWidgets('shows validation error when topic is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeworkCreationScreen(),
        ),
      );

      // Try to generate without entering topic
      final generateButton = find.text('AI ile Ödev Üret');
      await tester.tap(generateButton);
      await tester.pump();

      // Should show validation message
      expect(find.text('Lütfen konu girin'), findsOneWidget);
    });

    testWidgets('difficulty slider works', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeworkCreationScreen(),
        ),
      );

      // Find and drag difficulty slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Verify initial value (should be 2 - Orta)
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.value, 2.0);
    });

    testWidgets('format checkboxes can be selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeworkCreationScreen(),
        ),
      );

      // Find format checkboxes
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(4)); // MCQ, Çizim, Foto, Etkileşimli

      // Tap first checkbox (MCQ)
      await tester.tap(checkboxes.first);
      await tester.pump();

      // Checkbox should be selected (visual feedback)
      final firstCheckbox = tester.widget<CheckboxListTile>(checkboxes.first);
      expect(firstCheckbox.value, true);
    });
  });
}
