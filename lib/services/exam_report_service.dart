import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/models/exam_report.dart';
import 'package:kresai/services/exam_store.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

import 'package:kresai/services/exam_ai_service.dart';

/// Exam Report Service - Analytics and insights generation
class ExamReportService {
  static final ExamReportService _instance = ExamReportService._internal();
  factory ExamReportService() => _instance;
  ExamReportService._internal();

  final ExamStore _examStore = ExamStore();
  final ExamSubmissionStore _submissionStore = ExamSubmissionStore();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExamAIService _aiService = ExamAIService();
  
  static const String _schoolId = 'default_school';

  // ==================== REPORT GENERATION ====================

  /// Generate exam report (on-demand)
  Future<ExamReport> generateExamReport(String examId) async {
    final exam = await _examStore.getExam(examId);
    if (exam == null) throw Exception('Exam not found');

    final submissions = await _submissionStore.getGradedSubmissions(examId);
    
    // Calculate participation
    final submittedCount = submissions.length;
    final totalStudents = exam.totalStudents;
    final pendingStudentIds = await _submissionStore.getPendingStudents(
      examId: examId,
      targetStudentIds: exam.targetStudentIds.isEmpty 
          ? [] // TODO: Get all class students
          : exam.targetStudentIds,
    );

    // Calculate average score
    double averageScore = 0.0;
    if (submissions.isNotEmpty) {
      final scores = submissions
          .where((s) => s.grade != null)
          .map((s) => s.grade!.teacherScore ?? s.grade!.score);
      if (scores.isNotEmpty) {
        averageScore = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    // Calculate score distribution
    final scoreDistribution = _calculateScoreDistribution(submissions, exam.maxScore);

    // Analyze questions
    final questionBreakdown = _analyzeQuestions(exam, submissions);

    // Calculate topic accuracy (optional V1)
    final topicAccuracy = _calculateTopicAccuracy(submissions);

    // Generate AI Insights
    AIInsights? aiInsights;
    try {
      if (submissions.isNotEmpty) {
        aiInsights = await _aiService.generateClassInsights(
          exam: exam,
          averageScore: averageScore,
          questionBreakdown: questionBreakdown,
        );
      }
    } catch (e) {
      print('AI Insights Generation Failed: $e');
    }

    // Create report
    final report = ExamReport(
      id: '', // Will be set by Firestore
      examId: examId,
      submittedCount: submittedCount,
      totalStudents: totalStudents,
      pendingStudentIds: pendingStudentIds,
      averageScore: averageScore,
      scoreDistribution: scoreDistribution,
      questionBreakdown: questionBreakdown,
      topicAccuracy: topicAccuracy,
      aiInsights: aiInsights,
      generatedAt: DateTime.now(),
    );

    // Skip Firestore save in TEST_LAB_MODE
    if (TEST_LAB_MODE) {
      return ExamReport(
        id: 'mock_report_${DateTime.now().millisecondsSinceEpoch}',
        examId: report.examId,
        submittedCount: report.submittedCount,
        totalStudents: report.totalStudents,
        pendingStudentIds: report.pendingStudentIds,
        averageScore: report.averageScore,
        scoreDistribution: report.scoreDistribution,
        questionBreakdown: report.questionBreakdown,
        topicAccuracy: report.topicAccuracy,
        aiInsights: report.aiInsights,
        generatedAt: report.generatedAt,
      );
    }

    // Save to Firestore
    final docRef = await _firestore
        .collection('schools/$_schoolId/examReports')
        .add(report.toFirestore());

    return ExamReport(
      id: docRef.id,
      examId: report.examId,
      submittedCount: report.submittedCount,
      totalStudents: report.totalStudents,
      pendingStudentIds: report.pendingStudentIds,
      averageScore: report.averageScore,
      scoreDistribution: report.scoreDistribution,
      questionBreakdown: report.questionBreakdown,
      topicAccuracy: report.topicAccuracy,
      aiInsights: report.aiInsights,
      generatedAt: report.generatedAt,
    );
  }

  /// Generate weekly summary
  Future<WeeklySummary> generateWeeklySummary({
    required String classId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final exams = await _examStore.getExamsByDateRange(
      classId: classId,
      start: weekStart,
      end: weekEnd,
    );

    if (exams.isEmpty) {
      return WeeklySummary(
        id: _getWeekId(weekStart),
        classId: classId,
        examCount: 0,
        avgScore: 0.0,
        topStrugglingTopics: [],
        weekStart: weekStart,
        weekEnd: weekEnd,
        generatedAt: DateTime.now(),
      );
    }

    // Calculate average score across all exams
    double totalScore = 0.0;
    int totalSubmissions = 0;

    for (final exam in exams) {
      final submissions = await _submissionStore.getGradedSubmissions(exam.id);
      for (final submission in submissions) {
        if (submission.grade != null) {
          final score = submission.grade!.teacherScore ?? submission.grade!.score;
          final normalizedScore = (score / submission.grade!.maxScore) * 10; // Normalize to /10
          totalScore += normalizedScore;
          totalSubmissions++;
        }
      }
    }

    final avgScore = totalSubmissions > 0 ? totalScore / totalSubmissions : 0.0;

    // Identify struggling topics (optional V1)
    final topStrugglingTopics = await _identifyStrugglingTopics(exams);

    final summary = WeeklySummary(
      id: _getWeekId(weekStart),
      classId: classId,
      examCount: exams.length,
      avgScore: avgScore,
      topStrugglingTopics: topStrugglingTopics,
      weekStart: weekStart,
      weekEnd: weekEnd,
      generatedAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestore
        .collection('schools/$_schoolId/weeklySummaries')
        .doc(summary.id)
        .set(summary.toFirestore());

    return summary;
  }

  // ==================== REAL-TIME WATCHERS ====================

  /// Watch exam report (live stats)
  Stream<ExamReport?> watchExamReport(String examId) {
    return _firestore
        .collection('schools/$_schoolId/examReports')
        .where('examId', isEqualTo: examId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ExamReport.fromFirestore(snapshot.docs.first);
        });
  }

  /// Watch weekly summary
  Stream<WeeklySummary?> watchWeeklySummary(String weekId) {
    return _firestore
        .collection('schools/$_schoolId/weeklySummaries')
        .doc(weekId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return WeeklySummary.fromFirestore(doc);
        });
  }

  // ==================== HELPER METHODS ====================

  /// Calculate score distribution buckets
  Map<String, dynamic> _calculateScoreDistribution(
    List<ExamSubmission> submissions,
    int maxScore,
  ) {
    final distribution = <String, int>{
      '0-2': 0,
      '3-5': 0,
      '6-8': 0,
      '9-10': 0,
    };

    for (final submission in submissions) {
      if (submission.grade == null) continue;

      final score = submission.grade!.teacherScore ?? submission.grade!.score;
      final normalizedScore = (score / submission.grade!.maxScore) * 10; // Normalize to /10

      if (normalizedScore <= 2) {
        distribution['0-2'] = distribution['0-2']! + 1;
      } else if (normalizedScore <= 5) {
        distribution['3-5'] = distribution['3-5']! + 1;
      } else if (normalizedScore <= 8) {
        distribution['6-8'] = distribution['6-8']! + 1;
      } else {
        distribution['9-10'] = distribution['9-10']! + 1;
      }
    }

    return distribution;
  }

  /// Analyze questions for common errors
  List<QuestionAnalysis> _analyzeQuestions(
    Exam exam,
    List<ExamSubmission> submissions,
  ) {
    final analyses = <QuestionAnalysis>[];

    for (final question in exam.questions) {
      int correctCount = 0;
      int wrongCount = 0;
      int uncertainCount = 0;
      final errors = <String>[];

      for (final submission in submissions) {
        if (submission.grade == null) continue;

        final questionGrade = submission.grade!.perQuestion
            .where((q) => q.qid == question.qid)
            .firstOrNull;

        if (questionGrade == null) continue;

        switch (questionGrade.status) {
          case GradeStatus.correct:
            correctCount++;
            break;
          case GradeStatus.wrong:
            wrongCount++;
            if (questionGrade.hint != null && !errors.contains(questionGrade.hint)) {
              errors.add(questionGrade.hint!);
            }
            break;
          case GradeStatus.uncertain:
            uncertainCount++;
            break;
        }
      }

      analyses.add(QuestionAnalysis(
        qid: question.qid,
        correctCount: correctCount,
        wrongCount: wrongCount,
        uncertainCount: uncertainCount,
        commonErrors: errors.take(3).toList(), // Top 3 errors
      ));
    }

    return analyses;
  }

  /// Calculate topic accuracy (optional V1)
  Map<String, double> _calculateTopicAccuracy(List<ExamSubmission> submissions) {
    final topicScores = <String, List<double>>{};

    for (final submission in submissions) {
      if (submission.grade == null) continue;

      for (final questionGrade in submission.grade!.perQuestion) {
        if (questionGrade.topicTag == null) continue;

        final topic = questionGrade.topicTag!;
        final accuracy = questionGrade.status == GradeStatus.correct ? 1.0 : 0.0;

        topicScores.putIfAbsent(topic, () => []);
        topicScores[topic]!.add(accuracy);
      }
    }

    final topicAccuracy = <String, double>{};
    for (final entry in topicScores.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      topicAccuracy[entry.key] = sum / entry.value.length;
    }

    return topicAccuracy;
  }

  /// Identify struggling topics across exams
  Future<List<String>> _identifyStrugglingTopics(List<Exam> exams) async {
    final topicScores = <String, List<double>>{};

    for (final exam in exams) {
      final submissions = await _submissionStore.getGradedSubmissions(exam.id);
      
      for (final submission in submissions) {
        if (submission.grade == null) continue;

        for (final questionGrade in submission.grade!.perQuestion) {
          if (questionGrade.topicTag == null) continue;

          final topic = questionGrade.topicTag!;
          final accuracy = questionGrade.status == GradeStatus.correct ? 1.0 : 0.0;

          topicScores.putIfAbsent(topic, () => []);
          topicScores[topic]!.add(accuracy);
        }
      }
    }

    // Calculate average and sort by lowest accuracy
    final topicAverages = topicScores.entries
        .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return topicAverages.take(3).map((e) => e.key).toList();
  }

  /// Generate week ID (e.g., "2026-W04")
  String _getWeekId(DateTime date) {
    // Calculate week number
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
    
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
