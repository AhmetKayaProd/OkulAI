import 'package:cloud_firestore/cloud_firestore.dart';

/// Question-level analysis for exam reports
class QuestionAnalysis {
  final String qid;
  final int correctCount;
  final int wrongCount;
  final int uncertainCount;
  final List<String> commonErrors;

  const QuestionAnalysis({
    required this.qid,
    required this.correctCount,
    required this.wrongCount,
    required this.uncertainCount,
    required this.commonErrors,
  });

  factory QuestionAnalysis.fromJson(Map<String, dynamic> json) {
    return QuestionAnalysis(
      qid: json['qid'] as String,
      correctCount: json['correctCount'] as int,
      wrongCount: json['wrongCount'] as int,
      uncertainCount: json['uncertainCount'] as int,
      commonErrors: (json['commonErrors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qid': qid,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'uncertainCount': uncertainCount,
      'commonErrors': commonErrors,
    };
  }
}

/// AI-generated insights for the whole class
class AIInsights {
  final String summary;
  final List<String> keyMisconceptions;
  final List<String> successfulTopics;
  final List<String> recommendationsForTeacher;

  const AIInsights({
    required this.summary,
    required this.keyMisconceptions,
    required this.successfulTopics,
    required this.recommendationsForTeacher,
  });

  factory AIInsights.fromJson(Map<String, dynamic> json) {
    return AIInsights(
      summary: json['summary'] as String? ?? 'Henüz analiz yapılmadı.',
      keyMisconceptions: (json['keyMisconceptions'] as List?)?.cast<String>() ?? [],
      successfulTopics: (json['successfulTopics'] as List?)?.cast<String>() ?? [],
      recommendationsForTeacher: (json['recommendationsForTeacher'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyMisconceptions': keyMisconceptions,
      'successfulTopics': successfulTopics,
      'recommendationsForTeacher': recommendationsForTeacher,
    };
  }
}

/// Single exam analytics report
class ExamReport {
  final String id;
  final String examId;
  
  // Participation
  final int submittedCount;
  final int totalStudents;
  final List<String> pendingStudentIds;
  
  // Scores
  final double averageScore;
  final Map<String, dynamic> scoreDistribution; // "0-2": 3, "3-5": 7, etc.
  
  // Question Analysis
  final List<QuestionAnalysis> questionBreakdown;
  
  // Topics (optional V2)
  final Map<String, double> topicAccuracy; // topic -> % correct
  
  // AI Insights
  final AIInsights? aiInsights;
  
  final DateTime generatedAt;

  const ExamReport({
    required this.id,
    required this.examId,
    required this.submittedCount,
    required this.totalStudents,
    required this.pendingStudentIds,
    required this.averageScore,
    required this.scoreDistribution,
    required this.questionBreakdown,
    required this.topicAccuracy,
    this.aiInsights,
    required this.generatedAt,
  });

  factory ExamReport.fromJson(Map<String, dynamic> json) {
    return ExamReport(
      id: json['id'] as String,
      examId: json['examId'] as String,
      submittedCount: json['submittedCount'] as int,
      totalStudents: json['totalStudents'] as int,
      pendingStudentIds: (json['pendingStudentIds'] as List).cast<String>(),
      averageScore: (json['averageScore'] as num).toDouble(),
      scoreDistribution: json['scoreDistribution'] as Map<String, dynamic>,
      questionBreakdown: (json['questionBreakdown'] as List)
          .map((e) => QuestionAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicAccuracy: (json['topicAccuracy'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      aiInsights: json['aiInsights'] != null 
          ? AIInsights.fromJson(json['aiInsights'] as Map<String, dynamic>)
          : null,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'submittedCount': submittedCount,
      'totalStudents': totalStudents,
      'pendingStudentIds': pendingStudentIds,
      'averageScore': averageScore,
      'scoreDistribution': scoreDistribution,
      'questionBreakdown': questionBreakdown.map((q) => q.toJson()).toList(),
      'topicAccuracy': topicAccuracy,
      'aiInsights': aiInsights?.toJson(),
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  // Firestore serialization
  factory ExamReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamReport(
      id: doc.id,
      examId: data['examId'] as String,
      submittedCount: data['submittedCount'] as int,
      totalStudents: data['totalStudents'] as int,
      pendingStudentIds: (data['pendingStudentIds'] as List).cast<String>(),
      averageScore: (data['averageScore'] as num).toDouble(),
      scoreDistribution: data['scoreDistribution'] as Map<String, dynamic>,
      questionBreakdown: (data['questionBreakdown'] as List)
          .map((e) => QuestionAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicAccuracy: (data['topicAccuracy'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      aiInsights: data['aiInsights'] != null 
          ? AIInsights.fromJson(data['aiInsights'] as Map<String, dynamic>)
          : null,
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'examId': examId,
      'submittedCount': submittedCount,
      'totalStudents': totalStudents,
      'pendingStudentIds': pendingStudentIds,
      'averageScore': averageScore,
      'scoreDistribution': scoreDistribution,
      'questionBreakdown': questionBreakdown.map((q) => q.toJson()).toList(),
      'topicAccuracy': topicAccuracy,
      'aiInsights': aiInsights?.toJson(),
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}

/// Weekly summary across multiple exams
class WeeklySummary {
  final String id; // "2026-W04"
  final String classId;
  
  final int examCount;
  final double avgScore;
  final List<String> topStrugglingTopics; // optional V1
  
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime generatedAt;

  const WeeklySummary({
    required this.id,
    required this.classId,
    required this.examCount,
    required this.avgScore,
    required this.topStrugglingTopics,
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      id: json['id'] as String,
      classId: json['classId'] as String,
      examCount: json['examCount'] as int,
      avgScore: (json['avgScore'] as num).toDouble(),
      topStrugglingTopics: (json['topStrugglingTopics'] as List).cast<String>(),
      weekStart: DateTime.fromMillisecondsSinceEpoch(json['weekStart'] as int),
      weekEnd: DateTime.fromMillisecondsSinceEpoch(json['weekEnd'] as int),
      generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'examCount': examCount,
      'avgScore': avgScore,
      'topStrugglingTopics': topStrugglingTopics,
      'weekStart': weekStart.millisecondsSinceEpoch,
      'weekEnd': weekEnd.millisecondsSinceEpoch,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  // Firestore serialization
  factory WeeklySummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklySummary(
      id: doc.id,
      classId: data['classId'] as String,
      examCount: data['examCount'] as int,
      avgScore: (data['avgScore'] as num).toDouble(),
      topStrugglingTopics: (data['topStrugglingTopics'] as List).cast<String>(),
      weekStart: (data['weekStart'] as Timestamp).toDate(),
      weekEnd: (data['weekEnd'] as Timestamp).toDate(),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'examCount': examCount,
      'avgScore': avgScore,
      'topStrugglingTopics': topStrugglingTopics,
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
