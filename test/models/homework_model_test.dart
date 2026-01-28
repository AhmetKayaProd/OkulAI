import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/models/homework.dart';

void main() {
  group('Homework Model Tests', () {
    test('Homework toFirestore serialization', () {
      final homework = Homework(
        id: 'test_123',
        classId: 'class_1',
        teacherId: 'teacher_1',
        selectedOptionId: 'opt_1',
        option: HomeworkOption(
          optionId: 'opt_1',
          title: 'Renkleri Öğren',
          goal: 'Çocuklar temel renkleri tanıyabilecek',
          format: HomeworkFormat.drawing,
          estimatedMinutes: 15,
          materials: ['Kağıt', 'Kalem'],
          studentInstructions: ['Kırmızı bir nesne bul'],
          parentGuidance: ['Evde kırmızı nesneler gösterin'],
          submissionType: SubmissionType.text,
          gradingRubric: GradingRubric(
            maxScore: 10,
            criteria: [],
          ),
          teacherAnswerKey: TeacherAnswerKey(
            notes: 'Test notes',
            expectedPoints: ['Point 1'],
            sampleAnswers: ['Answer 1'],
          ),
          adaptations: Adaptations(
            easy: 'Easier version',
            hard: 'Harder version',
          ),
        ),
        targetStudentIds: [],
        status: HomeworkStatus.published,
        createdAt: DateTime(2024, 1, 20),
        publishedAt: DateTime(2024, 1, 20),
        dueDate: DateTime(2024, 1, 27),
      );

      final firestoreData = homework.toFirestore();

      expect(firestoreData['classId'], 'class_1');
      expect(firestoreData['status'], 'published');
      expect(firestoreData['option']['title'], 'Renkleri Öğren');
    });

    test('Homework copyWith method', () {
      final original = Homework(
        id: 'hw_001',
        classId: 'class_1',
        teacherId: 'teacher_1',
        selectedOptionId: 'opt_1',
        option: HomeworkOption(
          optionId: 'opt_1',
          title: 'Test',
          goal: 'Goal',
          format: HomeworkFormat.mcq,
          estimatedMinutes: 10,
          materials: [],
          studentInstructions: [],
          parentGuidance: [],
          submissionType: SubmissionType.interactive,
          gradingRubric: GradingRubric(maxScore: 10, criteria: []),
          teacherAnswerKey: TeacherAnswerKey(
            notes: '',
            expectedPoints: [],
            sampleAnswers: [],
          ),
          adaptations: Adaptations(easy: '', hard: ''),
        ),
        targetStudentIds: [],
        status: HomeworkStatus.draft,
        createdAt: DateTime(2024, 1, 20),
      );

      final updated = original.copyWith(
        status: HomeworkStatus.published,
        publishedAt: DateTime(2024, 1, 21),
      );

      expect(updated.id, 'hw_001'); // Unchanged
      expect(updated.status, HomeworkStatus.published); // Changed
      expect(updated.publishedAt, DateTime(2024, 1, 21)); // Changed
    });
  });

  group('Enum Tests', () {
    test('GradeBand enum values', () {
      expect(GradeBand.anaokulu.name, 'anaokulu');
      expect(GradeBand.ilkokul.name, 'ilkokul');
    });

    test('HomeworkStatus enum values', () {
      expect(HomeworkStatus.draft.name, 'draft');
      expect(HomeworkStatus.published.name, 'published');
      expect(HomeworkStatus.closed.name, 'closed');
    });

    test('HomeworkFormat enum values', () {
      expect(HomeworkFormat.mcq.name, 'mcq');
      expect(HomeworkFormat.drawing.name, 'drawing');
    });
  });
}
