import 'package:cloud_firestore/cloud_firestore.dart';

/// Submission status
enum SubmissionStatus {
  inProgress('Devam Ediyor'),
  submitted('Gönderildi'),
  graded('Notlandı');

  final String label;
  const SubmissionStatus(this.label);
}

/// Grade status for individual questions
enum GradeStatus {
  correct('Doğru'),
  wrong('Yanlış'),
  uncertain('Belirsiz');

  final String label;
  const GradeStatus(this.label);
}

/// Grade flags
enum GradeFlag {
  lowConfidence('Düşük Güven'),
  suspectedHelp('Şüpheli Yardım'),
  unreadablePhoto('Okunamaz Fotoğraf'),
  incompleteAnswers('Eksik Cevaplar');

  final String label;
  const GradeFlag(this.label);
}

/// Per-question grading details
class QuestionGrade {
  final String qid;
  final int earned;
  final int max;
  final GradeStatus status;
  final String? hint; // NOT the full solution, just a hint
  final String? topicTag;

  const QuestionGrade({
    required this.qid,
    required this.earned,
    required this.max,
    required this.status,
    this.hint,
    this.topicTag,
  });

  factory QuestionGrade.fromJson(Map<String, dynamic> json) {
    return QuestionGrade(
      qid: json['qid'] as String,
      earned: json['earned'] as int,
      max: json['max'] as int,
      status: GradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      hint: json['hint'] as String?,
      topicTag: json['topicTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qid': qid,
      'earned': earned,
      'max': max,
      'status': status.name,
      'hint': hint,
      'topicTag': topicTag,
    };
  }
}

/// Parent feedback (no solutions)
class ParentFeedback {
  final String summary; // Encouraging message
  final List<String> strengths;
  final List<String> improvements;
  final List<String> hintsWithoutSolutions; // Guiding questions

  const ParentFeedback({
    required this.summary,
    required this.strengths,
    required this.improvements,
    required this.hintsWithoutSolutions,
  });

  factory ParentFeedback.fromJson(Map<String, dynamic> json) {
    return ParentFeedback(
      summary: json['summary'] as String,
      strengths: (json['strengths'] as List).cast<String>(),
      improvements: (json['improvements'] as List).cast<String>(),
      hintsWithoutSolutions: (json['hintsWithoutSolutions'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'strengths': strengths,
      'improvements': improvements,
      'hintsWithoutSolutions': hintsWithoutSolutions,
    };
  }
}

/// Grading result (AI + optional teacher override)
class ExamGrade {
  final int score;
  final int maxScore;
  final double confidence; // 0.0 - 1.0
  
  // Per-question breakdown
  final List<QuestionGrade> perQuestion;
  
  // Flags
  final List<String> flags; // Use GradeFlag.name values
  
  // Parent feedback
  final ParentFeedback? parentFeedback;
  
  // Teacher override
  final int? teacherScore;
  final String? teacherFeedback;
  final bool isTeacherOverride;

  const ExamGrade({
    required this.score,
    required this.maxScore,
    required this.confidence,
    required this.perQuestion,
    required this.flags,
    this.parentFeedback,
    this.teacherScore,
    this.teacherFeedback,
    this.isTeacherOverride = false,
  });

  factory ExamGrade.fromJson(Map<String, dynamic> json) {
    return ExamGrade(
      score: json['score'] as int,
      maxScore: json['maxScore'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      perQuestion: (json['perQuestion'] as List)
          .map((e) => QuestionGrade.fromJson(e as Map<String, dynamic>))
          .toList(),
      flags: (json['flags'] as List).cast<String>(),
      parentFeedback: json['parentFeedback'] != null
          ? ParentFeedback.fromJson(json['parentFeedback'] as Map<String, dynamic>)
          : null,
      teacherScore: json['teacherScore'] as int?,
      teacherFeedback: json['teacherFeedback'] as String?,
      isTeacherOverride: json['isTeacherOverride'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'maxScore': maxScore,
      'confidence': confidence,
      'perQuestion': perQuestion.map((q) => q.toJson()).toList(),
      'flags': flags,
      'parentFeedback': parentFeedback?.toJson(),
      'teacherScore': teacherScore,
      'teacherFeedback': teacherFeedback,
      'isTeacherOverride': isTeacherOverride,
    };
  }
}

/// Student submission for an exam
class ExamSubmission {
  final String id;
  final String examId;
  final String studentId;
  final String parentId;
  final String classId;
  
  // Answers
  final Map<String, dynamic> answers; // qid -> answer (text | choice letter | etc)
  final List<String>? photoUrls; // For paper exams (optional V1)
  
  // Grading
  final SubmissionStatus status;
  final ExamGrade? grade;
  final bool needsTeacherReview;
  
  // Metadata
  final DateTime startedAt;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final int elapsedMinutes;

  const ExamSubmission({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.parentId,
    required this.classId,
    required this.answers,
    this.photoUrls,
    required this.status,
    this.grade,
    this.needsTeacherReview = false,
    required this.startedAt,
    this.submittedAt,
    this.gradedAt,
    this.elapsedMinutes = 0,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) {
    return ExamSubmission(
      id: json['id'] as String,
      examId: json['examId'] as String,
      studentId: json['studentId'] as String,
      parentId: json['parentId'] as String,
      classId: json['classId'] as String,
      answers: json['answers'] as Map<String, dynamic>,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      grade: json['grade'] != null
          ? ExamGrade.fromJson(json['grade'] as Map<String, dynamic>)
          : null,
      needsTeacherReview: json['needsTeacherReview'] as bool? ?? false,
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      submittedAt: json['submittedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['submittedAt'] as int)
          : null,
      gradedAt: json['gradedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['gradedAt'] as int)
          : null,
      elapsedMinutes: json['elapsedMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'parentId': parentId,
      'classId': classId,
      'answers': answers,
      'photoUrls': photoUrls,
      'status': status.name,
      'grade': grade?.toJson(),
      'needsTeacherReview': needsTeacherReview,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'submittedAt': submittedAt?.millisecondsSinceEpoch,
      'gradedAt': gradedAt?.millisecondsSinceEpoch,
      'elapsedMinutes': elapsedMinutes,
    };
  }

  // Firestore serialization
  factory ExamSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamSubmission(
      id: doc.id,
      examId: data['examId'] as String,
      studentId: data['studentId'] as String,
      parentId: data['parentId'] as String,
      classId: data['classId'] as String,
      answers: data['answers'] as Map<String, dynamic>,
      photoUrls: (data['photoUrls'] as List?)?.cast<String>(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      grade: data['grade'] != null
          ? ExamGrade.fromJson(data['grade'] as Map<String, dynamic>)
          : null,
      needsTeacherReview: data['needsTeacherReview'] as bool? ?? false,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      gradedAt: data['gradedAt'] != null
          ? (data['gradedAt'] as Timestamp).toDate()
          : null,
      elapsedMinutes: data['elapsedMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'examId': examId,
      'studentId': studentId,
      'parentId': parentId,
      'classId': classId,
      'answers': answers,
      'photoUrls': photoUrls,
      'status': status.name,
      'grade': grade?.toJson(),
      'needsTeacherReview': needsTeacherReview,
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'elapsedMinutes': elapsedMinutes,
    };
  }

  ExamSubmission copyWith({
    String? id,
    Map<String, dynamic>? answers,
    SubmissionStatus? status,
    ExamGrade? grade,
    bool? needsTeacherReview,
    DateTime? submittedAt,
    DateTime? gradedAt,
    int? elapsedMinutes,
  }) {
    return ExamSubmission(
      id: id ?? this.id,
      examId: examId,
      studentId: studentId,
      parentId: parentId,
      classId: classId,
      answers: answers ?? this.answers,
      photoUrls: photoUrls,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      needsTeacherReview: needsTeacherReview ?? this.needsTeacherReview,
      startedAt: startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
    );
  }
}
