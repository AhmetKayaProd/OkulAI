import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/models/exam_report.dart';

void main() {
  group('ExamReport Model Tests', () {
    test('ExamReport toFirestore serialization', () {
      final report = ExamReport(
        id: 'report_123',
        examId: 'exam_456',
        submittedCount: 10,
        totalStudents: 12,
        pendingStudentIds: ['student_1', 'student_2'],
        averageScore: 7.5,
        scoreDistribution: {
          '0-2': 1,
          '3-5': 2,
          '6-8': 5,
          '9-10': 2,
        },
        questionBreakdown: [
          QuestionAnalysis(
            qid: 'q1',
            correctCount: 8,
            wrongCount: 2,
            uncertainCount: 0,
            commonErrors: ['Kırmızı yerine mavi dediler'],
          ),
        ],
        topicAccuracy: {
          'Renkler': 0.8,
          'Sayılar': 0.6,
        },
        generatedAt: DateTime(2024, 1, 21, 10, 0),
      );

      final firestoreData = report.toFirestore();

      expect(firestoreData['examId'], 'exam_456');
      expect(firestoreData['submittedCount'], 10);
      expect(firestoreData['totalStudents'], 12);
      expect(firestoreData['averageScore'], 7.5);
      expect(firestoreData['scoreDistribution']['6-8'], 5);
      expect(firestoreData['questionBreakdown'].length, 1);
      expect(firestoreData['topicAccuracy']['Renkler'], 0.8);
    });

    test('QuestionAnalysis JSON serialization', () {
      final analysis = QuestionAnalysis(
        qid: 'q1',
        correctCount: 15,
        wrongCount: 3,
        uncertainCount: 2,
        commonErrors: [
          'Renkleri karıştırdılar',
          'Şekilleri yanlış eşleştirdiler',
        ],
      );

      final json = analysis.toJson();

      expect(json['qid'], 'q1');
      expect(json['correctCount'], 15);
      expect(json['wrongCount'], 3);
      expect(json['uncertainCount'], 2);
      expect(json['commonErrors'].length, 2);

      final reconstructed = QuestionAnalysis.fromJson(json);

      expect(reconstructed.qid, analysis.qid);
      expect(reconstructed.correctCount, analysis.correctCount);
      expect(reconstructed.commonErrors, analysis.commonErrors);
    });

    test('ExamReport with empty pending students', () {
      final report = ExamReport(
        id: 'report_full',
        examId: 'exam_001',
        submittedCount: 12,
        totalStudents: 12,
        pendingStudentIds: [], // All submitted
        averageScore: 8.0,
        scoreDistribution: {},
        questionBreakdown: [],
        topicAccuracy: {},
        generatedAt: DateTime(2024, 1, 21),
      );

      expect(report.pendingStudentIds.isEmpty, true);
      expect(report.submittedCount, report.totalStudents);
    });

    test('ExamReport participation calculations', () {
      final report = ExamReport(
        id: 'report_partial',
        examId: 'exam_001',
        submittedCount: 8,
        totalStudents: 12,
        pendingStudentIds: ['s1', 's2', 's3', 's4'],
        averageScore: 6.5,
        scoreDistribution: {},
        questionBreakdown: [],
        topicAccuracy: {},
        generatedAt: DateTime(2024, 1, 21),
      );

      final participationRate = report.submittedCount / report.totalStudents;

      expect(participationRate, 8 / 12);
      expect(report.pendingStudentIds.length, 4);
    });

    test('Score distribution buckets', () {
      final report = ExamReport(
        id: 'report_dist',
        examId: 'exam_001',
        submittedCount: 20,
        totalStudents: 20,
        pendingStudentIds: [],
        averageScore: 6.5,
        scoreDistribution: {
          '0-2': 2, // Poor
          '3-5': 5, // Average
          '6-8': 10, // Good
          '9-10': 3, // Excellent
        },
        questionBreakdown: [],
        topicAccuracy: {},
        generatedAt: DateTime(2024, 1, 21),
      );

      final totalInBuckets = report.scoreDistribution.values.reduce((a, b) => a + b);

      expect(totalInBuckets, 20);
      expect(report.scoreDistribution['6-8'], greaterThan(report.scoreDistribution['0-2']));
    });
  });

  group('WeeklySummary Model Tests', () {
    test('WeeklySummary toFirestore serialization', () {
      final summary = WeeklySummary(
        id: '2026-W04',
        classId: 'class_1',
        examCount: 4,
        avgScore: 7.2,
        topStrugglingTopics: ['Geometri', 'Sayma'],
        weekStart: DateTime(2026, 1, 20),
        weekEnd: DateTime(2026, 1, 26),
        generatedAt: DateTime(2026, 1, 27, 10, 0),
      );

      final firestoreData = summary.toFirestore();

      expect(firestoreData['classId'], 'class_1');
      expect(firestoreData['examCount'], 4);
      expect(firestoreData['avgScore'], 7.2);
      expect(firestoreData['topStrugglingTopics'], ['Geometri', 'Sayma']);
    });

    test('WeeklySummary JSON serialization', () {
      final summary = WeeklySummary(
        id: '2026-W05',
        classId: 'class_2',
        examCount: 3,
        avgScore: 8.5,
        topStrugglingTopics: ['Okuma'],
        weekStart: DateTime(2026, 1, 27),
        weekEnd: DateTime(2026, 2, 2),
        generatedAt: DateTime(2026, 2, 3),
      );

      final json = summary.toJson();

      expect(json['id'], '2026-W05');
      expect(json['classId'], 'class_2');
      expect(json['examCount'], 3);
      expect(json['avgScore'], 8.5);

      final reconstructed = WeeklySummary.fromJson(json);

      expect(reconstructed.id, summary.id);
      expect(reconstructed.avgScore, summary.avgScore);
      expect(reconstructed.topStrugglingTopics, summary.topStrugglingTopics);
    });

    test('WeeklySummary week range calculation', () {
      final summary = WeeklySummary(
        id: '2026-W04',
        classId: 'class_1',
        examCount: 5,
        avgScore: 7.0,
        topStrugglingTopics: [],
        weekStart: DateTime(2026, 1, 20),
        weekEnd: DateTime(2026, 1, 26),
        generatedAt: DateTime(2026, 1, 27),
      );

      final weekDuration = summary.weekEnd.difference(summary.weekStart);

      expect(weekDuration.inDays, 6); // 6 days (Mon-Sun)
    });

    test('WeeklySummary with no struggling topics', () {
      final summary = WeeklySummary(
        id: '2026-W04',
        classId: 'class_1',
        examCount: 2,
        avgScore: 9.5, // High average
        topStrugglingTopics: [], // No struggles
        weekStart: DateTime(2026, 1, 20),
        weekEnd: DateTime(2026, 1, 26),
        generatedAt: DateTime(2026, 1, 27),
      );

      expect(summary.topStrugglingTopics.isEmpty, true);
      expect(summary.avgScore, greaterThan(9.0));
    });
  });

  group('Analytics Calculations', () {
    test('Question success rate calculation', () {
      final analysis = QuestionAnalysis(
        qid: 'q1',
        correctCount: 18,
        wrongCount: 4,
        uncertainCount: 1,
        commonErrors: [],
      );

      final totalResponses = analysis.correctCount + 
                            analysis.wrongCount + 
                            analysis.uncertainCount;
      final successRate = analysis.correctCount / totalResponses;

      expect(successRate, closeTo(0.78, 0.01)); // 18/23 ≈ 0.78
    });

    test('Topic accuracy aggregation', () {
      final report = ExamReport(
        id: 'report_topics',
        examId: 'exam_001',
        submittedCount: 10,
        totalStudents: 10,
        pendingStudentIds: [],
        averageScore: 7.0,
        scoreDistribution: {},
        questionBreakdown: [],
        topicAccuracy: {
          'Renkler': 0.9,
          'Sayılar': 0.7,
          'Şekiller': 0.8,
        },
        generatedAt: DateTime(2024, 1, 21),
      );

      final avgTopicAccuracy = report.topicAccuracy.values.reduce((a, b) => a + b) / 
                               report.topicAccuracy.length;

      expect(avgTopicAccuracy, closeTo(0.8, 0.01));
    });

    test('Identify struggling questions', () {
      final questionBreakdown = [
        QuestionAnalysis(
          qid: 'q1',
          correctCount: 2,
          wrongCount: 18,
          uncertainCount: 0,
          commonErrors: ['Zorlanıldı'],
        ),
        QuestionAnalysis(
          qid: 'q2',
          correctCount: 18,
          wrongCount: 2,
          uncertainCount: 0,
          commonErrors: [],
        ),
      ];

      final strugglingQuestions = questionBreakdown.where((q) {
        final total = q.correctCount + q.wrongCount + q.uncertainCount;
        final successRate = q.correctCount / total;
        return successRate < 0.5;
      }).toList();

      expect(strugglingQuestions.length, 1);
      expect(strugglingQuestions.first.qid, 'q1');
    });
  });
}
