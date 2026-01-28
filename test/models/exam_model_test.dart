import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/models/exam.dart';

void main() {
  group('Exam Model Tests', () {
    test('Exam toFirestore serialization', () {
      final exam = Exam(
        id: 'exam_123',
        teacherId: 'teacher_1',
        classId: 'class_1',
        schoolId: 'school_1',
        gradeBand: 'anaokulu',
        timeWindow: 'gunluk',
        topics: ['Renkler', 'Sayılar'],
        teacherStyle: 'oyunlaştırılmış',
        status: ExamStatus.published,
        publishedAt: DateTime(2024, 1, 20),
        dueDate: DateTime(2024, 1, 27),
        targetStudentIds: [],
        title: 'Renk ve Sayı Testi',
        questions: [
          ExamQuestion(
            qid: 'q1',
            type: QuestionType.mcq,
            prompt: 'Hangisi kırmızı?',
            choices: ['Elma', 'Muz', 'Çimen'],
            correctAnswer: 'Elma',
            points: 1,
            rubric: QuestionRubric(
              acceptKeywords: ['elma'],
              rejectKeywords: ['muz', 'çimen'],
              confidenceThreshold: 0.8,
            ),
          ),
        ],
        estimatedMinutes: 10,
        maxScore: 10,
        instructions: [
          'Soruları dikkatlice oku ve doğru cevabı seç',
          'Veliye not: Cevabı söylemeden yönlendirin',
        ],
        answerKey: ExamAnswerKey(
          correctAnswers: {'q1': 'Elma'},
          explanations: {'q1': 'Elma kırmızıdır'},
          commonMistakes: {'q1': ['Muz diyen çocuklar var']},
        ),
        commonMisconceptions: ['Sarıyı kırmızı ile karıştırma'],
        submittedCount: 5,
        totalStudents: 12,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 20),
      );

      final firestoreData = exam.toFirestore();

      expect(firestoreData['teacherId'], 'teacher_1');
      expect(firestoreData['classId'], 'class_1');
      expect(firestoreData['status'], 'published');
      expect(firestoreData['title'], 'Renk ve Sayı Testi');
      expect(firestoreData['maxScore'], 10);
      expect(firestoreData['questions'].length, 1);
      expect(firestoreData['questions'][0]['qid'], 'q1');
      expect(firestoreData['submittedCount'], 5);
    });

    test('Exam copyWith method', () {
      final original = Exam(
        id: 'exam_001',
        teacherId: 'teacher_1',
        classId: 'class_1',
        schoolId: 'school_1',
        gradeBand: 'kres',
        timeWindow: 'haftalik',
        topics: ['Test Topic'],
        teacherStyle: 'klasik',
        status: ExamStatus.draft,
        targetStudentIds: [],
        title: 'Test Exam',
        questions: [],
        estimatedMinutes: 15,
        maxScore: 10,
        instructions: ['Instruction 1'],
        answerKey: ExamAnswerKey(
          correctAnswers: {},
          explanations: {},
          commonMistakes: {},
        ),
        commonMisconceptions: [],
        createdAt: DateTime(2024, 1, 20),
        updatedAt: DateTime(2024, 1, 20),
      );

      final updated = original.copyWith(
        status: ExamStatus.published,
        publishedAt: DateTime(2024, 1, 21),
        submittedCount: 8,
      );

      expect(updated.id, 'exam_001'); // Unchanged
      expect(updated.status, ExamStatus.published); // Changed
      expect(updated.publishedAt, DateTime(2024, 1, 21)); // Changed
      expect(updated.submittedCount, 8); // Changed
      expect(updated.teacherId, 'teacher_1'); // Unchanged
    });

    test('ExamQuestion JSON serialization', () {
      final question = ExamQuestion(
        qid: 'q1',
        type: QuestionType.trueFalse,
        prompt: 'Elma kırmızıdır',
        correctAnswer: 'Doğru',
        points: 1,
        rubric: QuestionRubric(
          acceptKeywords: ['doğru', 'evet'],
          rejectKeywords: ['yanlış', 'hayır'],
          confidenceThreshold: 0.9,
        ),
      );

      final json = question.toJson();

      expect(json['qid'], 'q1');
      expect(json['type'], 'trueFalse');
      expect(json['prompt'], 'Elma kırmızıdır');
      expect(json['correctAnswer'], 'Doğru');
      expect(json['points'], 1);

      final reconstructed = ExamQuestion.fromJson(json);

      expect(reconstructed.qid, question.qid);
      expect(reconstructed.type, question.type);
      expect(reconstructed.prompt, question.prompt);
    });

    test('QuestionRubric JSON serialization', () {
      final rubric = QuestionRubric(
        acceptKeywords: ['kırmızı', 'red'],
        rejectKeywords: ['mavi', 'yeşil'],
        confidenceThreshold: 0.75,
      );

      final json = rubric.toJson();

      expect(json['acceptKeywords'], ['kırmızı', 'red']);
      expect(json['rejectKeywords'], ['mavi', 'yeşil']);
      expect(json['confidenceThreshold'], 0.75);

      final reconstructed = QuestionRubric.fromJson(json);

      expect(reconstructed.acceptKeywords, rubric.acceptKeywords);
      expect(reconstructed.confidenceThreshold, rubric.confidenceThreshold);
    });

    test('ExamAnswerKey JSON serialization', () {
      final answerKey = ExamAnswerKey(
        correctAnswers: {'q1': 'A', 'q2': 'B'},
        explanations: {'q1': 'A doğru cevap', 'q2': 'B doğru cevap'},
        commonMistakes: {
          'q1': ['C seçeneklerini seçenler var'],
          'q2': ['D seçeneklerini seçenler var'],
        },
      );

      final json = answerKey.toJson();

      expect(json['correctAnswers']['q1'], 'A');
      expect(json['explanations']['q1'], 'A doğru cevap');
      expect(json['commonMistakes']['q1'][0], 'C seçeneklerini seçenler var');

      final reconstructed = ExamAnswerKey.fromJson(json);

      expect(reconstructed.correctAnswers['q1'], answerKey.correctAnswers['q1']);
      expect(reconstructed.explanations['q1'], answerKey.explanations['q1']);
    });
  });

  group('Enum Tests', () {
    test('QuestionType enum values', () {
      expect(QuestionType.mcq.name, 'mcq');
      expect(QuestionType.trueFalse.name, 'trueFalse');
      expect(QuestionType.matching.name, 'matching');
      expect(QuestionType.fillBlank.name, 'fillBlank');
    });

    test('ExamStatus enum values', () {
      expect(ExamStatus.draft.name, 'draft');
      expect(ExamStatus.published.name, 'published');
      expect(ExamStatus.closed.name, 'closed');
    });

    test('QuestionType labels', () {
      expect(QuestionType.mcq.label, 'Çoktan Seçmeli');
      expect(QuestionType.trueFalse.label, 'Doğru/Yanlış');
      expect(QuestionType.pictureChoice.label, 'Resimli Seçim');
    });

    test('ExamStatus labels', () {
      expect(ExamStatus.draft.label, 'Taslak');
      expect(ExamStatus.published.label, 'Yayınlandı');
      expect(ExamStatus.closed.label, 'Kapatıldı');
    });
  });

  group('Question Type-Specific Fields', () {
    test('MCQ question with choices', () {
      final question = ExamQuestion(
        qid: 'q1',
        type: QuestionType.mcq,
        prompt: 'Seçin',
        choices: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        points: 1,
        rubric: QuestionRubric(
          acceptKeywords: [],
          rejectKeywords: [],
          confidenceThreshold: 1.0,
        ),
      );

      expect(question.choices, isNotNull);
      expect(question.choices!.length, 4);
      expect(question.matchingPairs, isNull);
    });

    test('Matching question with pairs', () {
      final question = ExamQuestion(
        qid: 'q2',
        type: QuestionType.matching,
        prompt: 'Eşleştir',
        matchingPairs: {'Kırmızı': 'Elma', 'Sarı': 'Muz'},
        points: 2,
        rubric: QuestionRubric(
          acceptKeywords: [],
          rejectKeywords: [],
          confidenceThreshold: 1.0,
        ),
      );

      expect(question.matchingPairs, isNotNull);
      expect(question.matchingPairs!.length, 2);
      expect(question.choices, isNull);
    });

    test('Question with media', () {
      final question = ExamQuestion(
        qid: 'q3',
        type: QuestionType.listening,
        prompt: 'Dinle ve cevapla',
        audioUrl: 'https://example.com/audio.mp3',
        imageUrl: 'https://example.com/image.jpg',
        correctAnswer: 'Doğru cevap',
        points: 1,
        rubric: QuestionRubric(
          acceptKeywords: [],
          rejectKeywords: [],
          confidenceThreshold: 0.7,
        ),
      );

      expect(question.audioUrl, 'https://example.com/audio.mp3');
      expect(question.imageUrl, 'https://example.com/image.jpg');
    });
  });
}
