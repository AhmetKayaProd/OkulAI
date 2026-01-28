import 'package:cloud_firestore/cloud_firestore.dart';

/// Question types for exams
enum QuestionType {
  mcq('Çoktan Seçmeli'),
  trueFalse('Doğru/Yanlış'),
  matching('Eşleştirme'),
  fillBlank('Boşluk Doldurma'),
  shortText('Kısa Yanıt'),
  listening('Dinleme'),
  pictureChoice('Resimli Seçim'),
  drawingCheck('Çizim Kontrolü');

  final String label;
  const QuestionType(this.label);
}

/// Exam status
enum ExamStatus {
  draft('Taslak'),
  published('Yayınlandı'),
  closed('Kapatıldı');

  final String label;
  const ExamStatus(this.label);
}

/// Question rubric for auto-grading
class QuestionRubric {
  final List<String> acceptKeywords;
  final List<String> rejectKeywords;
  final double confidenceThreshold; // 0.0 - 1.0

  const QuestionRubric({
    required this.acceptKeywords,
    required this.rejectKeywords,
    required this.confidenceThreshold,
  });

  factory QuestionRubric.fromJson(Map<String, dynamic> json) {
    return QuestionRubric(
      acceptKeywords: (json['acceptKeywords'] as List).cast<String>(),
      rejectKeywords: (json['rejectKeywords'] as List).cast<String>(),
      confidenceThreshold: (json['confidenceThreshold'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acceptKeywords': acceptKeywords,
      'rejectKeywords': rejectKeywords,
      'confidenceThreshold': confidenceThreshold,
    };
  }
}

/// Individual question in an exam
class ExamQuestion {
  final String qid;
  final QuestionType type;
  final String prompt;

  // Type-specific fields (nullable based on type)
  final List<String>? choices; // For MCQ, Picture Choice
  final List<String>? choiceImageUrls; // Generated image URLs for Picture Choice
  final Map<String, String>? matchingPairs; // For Matching
  final String? correctAnswer; // For Fill Blank, True/False

  // Media
  final String? imageUrl;
  final String? audioUrl;

  // Grading
  final int points;
  final QuestionRubric rubric;

  const ExamQuestion({
    required this.qid,
    required this.type,
    required this.prompt,
    this.choices,
    this.choiceImageUrls,
    this.matchingPairs,
    this.correctAnswer,
    this.imageUrl,
    this.audioUrl,
    required this.points,
    required this.rubric,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      qid: json['qid'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List?)?.cast<String>(),
      choiceImageUrls: (json['choiceImageUrls'] as List?)?.cast<String>(),
      matchingPairs: (json['matchingPairs'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      correctAnswer: json['correctAnswer'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      points: json['points'] as int,
      rubric: QuestionRubric.fromJson(json['rubric'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qid': qid,
      'type': type.name,
      'prompt': prompt,
      'choices': choices,
      'choiceImageUrls': choiceImageUrls,
      'matchingPairs': matchingPairs,
      'correctAnswer': correctAnswer,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'points': points,
      'rubric': rubric.toJson(),
    };
  }
}

/// Teacher-only answer key (excluded from parent/student views)
class ExamAnswerKey {
  final Map<String, dynamic> correctAnswers; // qid -> answer
  final Map<String, String> explanations; // qid -> teacher note
  final Map<String, List<String>> commonMistakes; // qid -> mistake patterns

  const ExamAnswerKey({
    required this.correctAnswers,
    required this.explanations,
    required this.commonMistakes,
  });

  factory ExamAnswerKey.fromJson(Map<String, dynamic> json) {
    return ExamAnswerKey(
      correctAnswers: json['correctAnswers'] as Map<String, dynamic>,
      explanations: (json['explanations'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String)),
      commonMistakes: (json['commonMistakes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as List).cast<String>()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correctAnswers': correctAnswers,
      'explanations': explanations,
      'commonMistakes': commonMistakes,
    };
  }
}

/// Exam definition with metadata and questions
class Exam {
  final String id;
  final String teacherId;
  final String classId;
  final String schoolId;

  // Generation Metadata
  final String gradeBand; // "kres" | "anaokulu" | "ilkokul"
  final String timeWindow; // "gunluk" | "haftalik" | "donemlik"
  final List<String> topics;
  final String teacherStyle; // "nazik" | "oyunlaştırılmış" | "klasik"

  // Publishing Info
  final ExamStatus status;
  final DateTime? publishedAt;
  final DateTime? dueDate;
  final List<String> targetStudentIds; // empty = entire class

  // Content
  final String title;
  final List<ExamQuestion> questions;
  final int estimatedMinutes;
  final int maxScore;

  // Instructions
  final List<String> instructions; // [0] = child instruction, [1] = parent guidance

  // Teacher-Only Data
  final ExamAnswerKey answerKey;
  final List<String> commonMisconceptions;

  // Stats (real-time, updated by Cloud Functions)
  final int submittedCount;
  final int totalStudents;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Exam({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.schoolId,
    required this.gradeBand,
    required this.timeWindow,
    required this.topics,
    required this.teacherStyle,
    required this.status,
    this.publishedAt,
    this.dueDate,
    required this.targetStudentIds,
    required this.title,
    required this.questions,
    required this.estimatedMinutes,
    required this.maxScore,
    required this.instructions,
    required this.answerKey,
    required this.commonMisconceptions,
    this.submittedCount = 0,
    this.totalStudents = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      teacherId: json['teacherId'] as String,
      classId: json['classId'] as String,
      schoolId: json['schoolId'] as String,
      gradeBand: json['gradeBand'] as String,
      timeWindow: json['timeWindow'] as String,
      topics: (json['topics'] as List).cast<String>(),
      teacherStyle: json['teacherStyle'] as String,
      status: ExamStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      publishedAt: json['publishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['publishedAt'] as int)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      targetStudentIds: (json['targetStudentIds'] as List).cast<String>(),
      title: json['title'] as String,
      questions: (json['questions'] as List)
          .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: json['estimatedMinutes'] as int,
      maxScore: json['maxScore'] as int,
      instructions: (json['instructions'] as List).cast<String>(),
      answerKey: ExamAnswerKey.fromJson(json['answerKey'] as Map<String, dynamic>),
      commonMisconceptions: (json['commonMisconceptions'] as List).cast<String>(),
      submittedCount: json['submittedCount'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'classId': classId,
      'schoolId': schoolId,
      'gradeBand': gradeBand,
      'timeWindow': timeWindow,
      'topics': topics,
      'teacherStyle': teacherStyle,
      'status': status.name,
      'publishedAt': publishedAt?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'targetStudentIds': targetStudentIds,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'maxScore': maxScore,
      'instructions': instructions,
      'answerKey': answerKey.toJson(),
      'commonMisconceptions': commonMisconceptions,
      'submittedCount': submittedCount,
      'totalStudents': totalStudents,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firestore serialization
  factory Exam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exam(
      id: doc.id,
      teacherId: data['teacherId'] as String,
      classId: data['classId'] as String,
      schoolId: data['schoolId'] as String,
      gradeBand: data['gradeBand'] as String,
      timeWindow: data['timeWindow'] as String,
      topics: (data['topics'] as List).cast<String>(),
      teacherStyle: data['teacherStyle'] as String,
      status: ExamStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      targetStudentIds: (data['targetStudentIds'] as List).cast<String>(),
      title: data['title'] as String,
      questions: (data['questions'] as List)
          .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: data['estimatedMinutes'] as int,
      maxScore: data['maxScore'] as int,
      instructions: (data['instructions'] as List).cast<String>(),
      answerKey: ExamAnswerKey.fromJson(data['answerKey'] as Map<String, dynamic>),
      commonMisconceptions: (data['commonMisconceptions'] as List).cast<String>(),
      submittedCount: data['submittedCount'] as int? ?? 0,
      totalStudents: data['totalStudents'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'classId': classId,
      'schoolId': schoolId,
      'gradeBand': gradeBand,
      'timeWindow': timeWindow,
      'topics': topics,
      'teacherStyle': teacherStyle,
      'status': status.name,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'targetStudentIds': targetStudentIds,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'maxScore': maxScore,
      'instructions': instructions,
      'answerKey': answerKey.toJson(),
      'commonMisconceptions': commonMisconceptions,
      'submittedCount': submittedCount,
      'totalStudents': totalStudents,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Exam copyWith({
    ExamStatus? status,
    DateTime? publishedAt,
    DateTime? dueDate,
    int? submittedCount,
    int? totalStudents,
    String? title,
    List<ExamQuestion>? questions,
  }) {
    return Exam(
      id: id,
      teacherId: teacherId,
      classId: classId,
      schoolId: schoolId,
      gradeBand: gradeBand,
      timeWindow: timeWindow,
      topics: topics,
      teacherStyle: teacherStyle,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      dueDate: dueDate ?? this.dueDate,
      targetStudentIds: targetStudentIds,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      estimatedMinutes: estimatedMinutes,
      maxScore: maxScore,
      instructions: instructions,
      answerKey: answerKey,
      commonMisconceptions: commonMisconceptions,
      submittedCount: submittedCount ?? this.submittedCount,
      totalStudents: totalStudents ?? this.totalStudents,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
