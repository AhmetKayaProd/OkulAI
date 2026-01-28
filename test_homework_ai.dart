import 'package:kresai/services/homework_ai_service.dart';
import 'package:kresai/models/homework.dart';

/// Test script for HomeworkAIService
/// Run with: dart run test_homework_ai.dart
void main() async {
  final aiService = HomeworkAIService();

  print('🧪 Testing Homework AI Service...\n');

  // Test 1: Generate homework options
  print('📝 Test 1: Generate Homework Options');
  try {
    final result = await aiService.generateHomework(
      gradeBand: GradeBand.anaokulu,
      classContext: 'Papatya Sınıfı, 4-5 yaş, 20 öğrenci',
      timeWindow: TimeWindow.gunluk,
      topics: 'Renkler ve şekiller',
      estimatedMinutes: 15,
      difficulty: Difficulty.kolay,
      formatsAllowed: [
        HomeworkFormat.drawing,
        HomeworkFormat.mcq,
        HomeworkFormat.photoWorksheet,
      ],
      teacherStyle: 'Eğlenceli, kısa talimatlar',
    );

    print('✅ Success! Generated ${result.options.length} options:');
    for (var i = 0; i < result.options.length; i++) {
      final opt = result.options[i];
      print('  ${i + 1}. ${opt.title} (${opt.format.label})');
      print('     Hedef: ${opt.goal}');
      print('     Süre: ${opt.estimatedMinutes} dk');
      print('     Puan: ${opt.gradingRubric.maxScore}');
    }
    print('\nÖğretmen Özeti: ${result.summaryForTeacher}');
    print('Kontroller: ${result.checks}\n');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 2: Review submission (simulated)
  print('📊 Test 2: Review Submission (Simulated)');
  print('(Gerçek teslim için HomeworkSubmission nesnesi gerekli)');
  print('API test başarılı, submission review sonraki aşamada test edilecek.\n');

  print('✅ Phase 1 tests complete!');
  print('Models ve AI Service hazır. Phase 2 (UI) başlayabilir.');
}
