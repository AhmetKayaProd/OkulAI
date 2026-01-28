import 'package:cloud_firestore/cloud_firestore.dart';

/// Submission verdict from AI review
enum SubmissionVerdict {
  readyToSend('Gönderilmeye Hazır'),
  needsRevision('Düzeltme Gerekli'),
  uncertain('Belirsiz');

  final String label;
  const SubmissionVerdict(this.label);
}

/// Score suggestion from AI
class ScoreSuggestion {
  final int maxScore;
  final int suggestedScore;
  final List<String> reasoningBullets;

  const ScoreSuggestion({
    required this.maxScore,
    required this.suggestedScore,
    required this.reasoningBullets,
  });

  factory ScoreSuggestion.fromJson(Map<String, dynamic> json) {
    return ScoreSuggestion(
      maxScore: json['maxScore'] as int,
      suggestedScore: json['suggestedScore'] as int,
      reasoningBullets: (json['reasoningBullets'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxScore': maxScore,
      'suggestedScore': suggestedScore,
      'reasoningBullets': reasoningBullets,
    };
  }
}

/// Feedback to parent (no full solutions, only hints)
class FeedbackToParent {
  final String tone;
  final List<String> whatIsGood;
  final List<String> whatToImprove;
  final List<String> hintsWithoutSolution;

  const FeedbackToParent({
    required this.tone,
    required this.whatIsGood,
    required this.whatToImprove,
    required this.hintsWithoutSolution,
  });

  factory FeedbackToParent.fromJson(Map<String, dynamic> json) {
    return FeedbackToParent(
      tone: json['tone'] as String,
      whatIsGood: (json['whatIsGood'] as List).cast<String>(),
      whatToImprove: (json['whatToImprove'] as List).cast<String>(),
      hintsWithoutSolution: (json['hintsWithoutSolution'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tone': tone,
      'whatIsGood': whatIsGood,
      'whatToImprove': whatToImprove,
      'hintsWithoutSolution': hintsWithoutSolution,
    };
  }
}

/// AI review of submission
class AIReview {
  final SubmissionVerdict verdict;
  final double confidence; // 0-1
  final ScoreSuggestion scoreSuggestion;
  final FeedbackToParent feedbackToParent;
  final List<String> flags; // low_confidence_photo, off_topic, missing_step
  final DateTime reviewedAt;

  const AIReview({
    required this.verdict,
    required this.confidence,
    required this.scoreSuggestion,
    required this.feedbackToParent,
    required this.flags,
    required this.reviewedAt,
  });

  factory AIReview.fromJson(Map<String, dynamic> json) {
    return AIReview(
      verdict: SubmissionVerdict.values.firstWhere(
        (e) => e.name == json['verdict'],
      ),
      confidence: (json['confidence'] as num).toDouble(),
      scoreSuggestion: ScoreSuggestion.fromJson(
        json['scoreSuggestion'] as Map<String, dynamic>,
      ),
      feedbackToParent: FeedbackToParent.fromJson(
        json['feedbackToParent'] as Map<String, dynamic>,
      ),
      flags: (json['flags'] as List).cast<String>(),
      reviewedAt: DateTime.fromMillisecondsSinceEpoch(json['reviewedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verdict': verdict.name,
      'confidence': confidence,
      'scoreSuggestion': scoreSuggestion.toJson(),
      'feedbackToParent': feedbackToParent.toJson(),
      'flags': flags,
      'reviewedAt': reviewedAt.millisecondsSinceEpoch,
    };
  }
}

/// Homework submission
class HomeworkSubmission {
  final String id;
  final String homeworkId;
  final String studentId;
  final String parentId;
  final String submissionType; // interactive, text, photo
  final String? textContent;
  final List<String>? photoUrls;
  final Map<String, dynamic>? interactiveAnswers; // for MCQ etc.
  final AIReview? aiReview;
  final int? teacherScore; // teacher override
  final String? teacherFeedback;
  final DateTime submittedAt;
  final int reviewCount; // track re-submissions
  final bool sentToTeacher;
  final DateTime? gradedAt;

  const HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.parentId,
    required this.submissionType,
    this.textContent,
    this.photoUrls,
    this.interactiveAnswers,
    this.aiReview,
    this.teacherScore,
    this.teacherFeedback,
    required this.submittedAt,
    required this.reviewCount,
    required this.sentToTeacher,
    this.gradedAt,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmission(
      id: json['id'] as String,
      homeworkId: json['homeworkId'] as String,
      studentId: json['studentId'] as String,
      parentId: json['parentId'] as String,
      submissionType: json['submissionType'] as String,
      textContent: json['textContent'] as String?,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>(),
      interactiveAnswers: json['interactiveAnswers'] as Map<String, dynamic>?,
      aiReview: json['aiReview'] != null
          ? AIReview.fromJson(json['aiReview'] as Map<String, dynamic>)
          : null,
      teacherScore: json['teacherScore'] as int?,
      teacherFeedback: json['teacherFeedback'] as String?,
      submittedAt: DateTime.fromMillisecondsSinceEpoch(json['submittedAt'] as int),
      reviewCount: json['reviewCount'] as int,
      sentToTeacher: json['sentToTeacher'] as bool,
      gradedAt: json['gradedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['gradedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeworkId': homeworkId,
      'studentId': studentId,
      'parentId': parentId,
      'submissionType': submissionType,
      'textContent': textContent,
      'photoUrls': photoUrls,
      'interactiveAnswers': interactiveAnswers,
      'aiReview': aiReview?.toJson(),
      'teacherScore': teacherScore,
      'teacherFeedback': teacherFeedback,
      'submittedAt': submittedAt.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'sentToTeacher': sentToTeacher,
      'gradedAt': gradedAt?.millisecondsSinceEpoch,
    };
  }

  // Firestore serialization
  factory HomeworkSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeworkSubmission(
      id: doc.id,
      homeworkId: data['homeworkId'] as String,
      studentId: data['studentId'] as String,
      parentId: data['parentId'] as String,
      submissionType: data['submissionType'] as String,
      textContent: data['textContent'] as String?,
      photoUrls: (data['photoUrls'] as List?)?.cast<String>(),
      interactiveAnswers: data['interactiveAnswers'] as Map<String, dynamic>?,
      aiReview: data['aiReview'] != null
          ? AIReview.fromJson(data['aiReview'] as Map<String, dynamic>)
          : null,
      teacherScore: data['teacherScore'] as int?,
      teacherFeedback: data['teacherFeedback'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewCount: data['reviewCount'] as int,
      sentToTeacher: data['sentToTeacher'] as bool,
      gradedAt: data['gradedAt'] != null
          ? (data['gradedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeworkId': homeworkId,
      'studentId': studentId,
      'parentId': parentId,
      'submissionType': submissionType,
      'textContent': textContent,
      'photoUrls': photoUrls,
      'interactiveAnswers': interactiveAnswers,
      'aiReview': aiReview?.toJson(),
      'teacherScore': teacherScore,
      'teacherFeedback': teacherFeedback,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewCount': reviewCount,
      'sentToTeacher': sentToTeacher,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
    };
  }

  HomeworkSubmission copyWith({
    String? id,
    String? homeworkId,
    String? studentId,
    String? parentId,
    String? submissionType,
    String? textContent,
    List<String>? photoUrls,
    Map<String, dynamic>? interactiveAnswers,
    AIReview? aiReview,
    int? teacherScore,
    String? teacherFeedback,
    DateTime? submittedAt,
    bool? sentToTeacher,
    int? reviewCount,
    DateTime? gradedAt,
  }) {
    return HomeworkSubmission(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      parentId: parentId ?? this.parentId,
      submissionType: submissionType ?? this.submissionType,
      textContent: textContent ?? this.textContent,
      photoUrls: photoUrls ?? this.photoUrls,
      interactiveAnswers: interactiveAnswers ?? this.interactiveAnswers,
      aiReview: aiReview ?? this.aiReview,
      teacherScore: teacherScore ?? this.teacherScore,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      sentToTeacher: sentToTeacher ?? this.sentToTeacher,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }

  /// Computed score: Teacher's score takes precedence, otherwise AI suggestion
  int? get finalScore => teacherScore ?? aiReview?.scoreSuggestion.suggestedScore;
}
