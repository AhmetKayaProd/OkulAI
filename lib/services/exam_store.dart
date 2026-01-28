import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/app.dart';

/// Exam Store - Firestore-enabled CRUD operations
class ExamStore {
  static final ExamStore _instance = ExamStore._internal();
  factory ExamStore() => _instance;
  ExamStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support

  // ==================== FIRESTORE OPERATIONS ====================

  /// Create new exam (draft)
  Future<String> createDraftExam(Exam exam) async {
    final docRef = _firestore
        .collection('schools/$_schoolId/exams')
        .doc();

    final draftExam = exam.copyWith(
      status: ExamStatus.draft,
    );

    // Use the generated ID
    final examWithId = Exam(
      id: docRef.id,
      teacherId: draftExam.teacherId,
      classId: draftExam.classId,
      schoolId: _schoolId,
      gradeBand: draftExam.gradeBand,
      timeWindow: draftExam.timeWindow,
      topics: draftExam.topics,
      teacherStyle: draftExam.teacherStyle,
      status: ExamStatus.draft,
      targetStudentIds: draftExam.targetStudentIds,
      title: draftExam.title,
      questions: draftExam.questions,
      estimatedMinutes: draftExam.estimatedMinutes,
      maxScore: draftExam.maxScore,
      instructions: draftExam.instructions,
      answerKey: draftExam.answerKey,
      commonMisconceptions: draftExam.commonMisconceptions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(examWithId.toFirestore());
    return docRef.id;
  }

  /// Publish exam to class/students
  Future<void> publishExam({
    required String examId,
    required DateTime dueDate,
  }) async {
    // Get current exam to count target students
    final exam = await getExam(examId);
    if (exam == null) throw Exception('Exam not found');

    // Calculate total students (will be updated by Cloud Function in real impl)
    int totalStudents = 0;
    if (exam.targetStudentIds.isEmpty) {
      // TODO: Query class roster for student count
      totalStudents = 0; // Placeholder
    } else {
      totalStudents = exam.targetStudentIds.length;
    }

    await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .update({
      'status': ExamStatus.published.name,
      'publishedAt': Timestamp.fromDate(DateTime.now()),
      'dueDate': Timestamp.fromDate(dueDate),
      'totalStudents': totalStudents,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Close exam (prevent new submissions)
  Future<void> closeExam(String examId) async {
    await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .update({
      'status': ExamStatus.closed.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update exam (title, questions, etc.) - only allowed for draft status
  Future<void> updateExam(Exam exam) async {
    await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(exam.id)
        .update({
      'title': exam.title,
      'questions': exam.questions.map((q) => q.toJson()).toList(),
      'estimatedMinutes': exam.estimatedMinutes,
      'maxScore': exam.maxScore,
      'instructions': exam.instructions,
      'answerKey': exam.answerKey.toJson(),
      'commonMisconceptions': exam.commonMisconceptions,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete exam (only if draft)
  Future<void> deleteExam(String examId) async {
    final exam = await getExam(examId);
    if (exam == null) throw Exception('Exam not found');
    if (exam.status != ExamStatus.draft) {
      throw Exception('Cannot delete published/closed exam');
    }

    await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .delete();
  }

  /// Get single exam
  Future<Exam?> getExam(String examId) async {
    if (TEST_LAB_MODE) {
       return Exam(
          id: examId, // Return requested ID
          teacherId: 'mock_teacher_1',
          classId: 'global',
          schoolId: 'mock_school_1',
          gradeBand: 'ilkokul',
          timeWindow: 'haftalik',
          topics: ['Matematik', 'Uzay'],
          teacherStyle: 'oyunlaştırılmış',
          status: ExamStatus.published,
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          targetStudentIds: [],
          title: 'Uzay Yolculuğu Sınavı (Test Lab)',
          questions: [
            const ExamQuestion(
              qid: 'q1',
              type: QuestionType.mcq,
              prompt: 'En büyük gezegen hangisidir?',
              choices: ['Mars', 'Jüpiter', 'Dünya', 'Venüs'],
              points: 10,
              rubric: QuestionRubric(
                acceptKeywords: ['Jüpiter'],
                rejectKeywords: [],
                confidenceThreshold: 0.8,
              ),
            ),
          ],
          estimatedMinutes: 20,
          maxScore: 100,
          instructions: ['Soruları dikkatlice oku.'],
          answerKey: const ExamAnswerKey(
            correctAnswers: {'q1': 'Jüpiter'},
            explanations: {'q1': 'Jüpiter güneş sisteminin en büyük gezegenidir.'},
            commonMistakes: {},
          ),
          commonMisconceptions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    }

    final doc = await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .get();

    if (!doc.exists) return null;
    return Exam.fromFirestore(doc);
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Watch teacher's exams
  Stream<List<Exam>> watchTeacherExams(String teacherId) {
    if (TEST_LAB_MODE) {
      return Stream.value([
        Exam(
          id: 'mock_exam_1',
          teacherId: teacherId,
          classId: 'global',
          schoolId: 'mock_school_1',
          gradeBand: 'ilkokul',
          timeWindow: 'haftalik',
          topics: ['Matematik', 'Uzay'],
          teacherStyle: 'oyunlaştırılmış',
          status: ExamStatus.published,
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          targetStudentIds: [],
          title: 'Uzay Yolculuğu Sınavı (Test Lab)',
          questions: [
            const ExamQuestion(
              qid: 'q1',
              type: QuestionType.mcq,
              prompt: 'En büyük gezegen hangisidir?',
              choices: ['Mars', 'Jüpiter', 'Dünya', 'Venüs'],
              points: 10,
              rubric: QuestionRubric(
                acceptKeywords: ['Jüpiter'],
                rejectKeywords: [],
                confidenceThreshold: 0.8,
              ),
            ),
          ],
          estimatedMinutes: 20,
          maxScore: 100,
          instructions: ['Soruları dikkatlice oku.'],
          answerKey: const ExamAnswerKey(
            correctAnswers: {'q1': 'Jüpiter'},
            explanations: {'q1': 'Jüpiter güneş sisteminin en büyük gezegenidir.'},
            commonMistakes: {},
          ),
          commonMisconceptions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    }
    return _firestore
        .collection('schools/$_schoolId/exams')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList());
  }

  /// Watch published exams for a class
  Stream<List<Exam>> watchClassExams(String classId) {
    return _firestore
        .collection('schools/$_schoolId/exams')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: ExamStatus.published.name)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList());
  }

  /// Watch exams assigned to specific student
  Stream<List<Exam>> watchStudentExams({
    required String classId,
    required String studentId,
  }) {
    if (TEST_LAB_MODE) {
      return Stream.value([
        Exam(
          id: 'mock_exam_1',
          teacherId: 'mock_teacher_1',
          classId: classId,
          schoolId: 'mock_school_1',
          gradeBand: 'ilkokul',
          timeWindow: 'haftalik',
          topics: ['Matematik', 'Uzay'],
          teacherStyle: 'oyunlaştırılmış',
          status: ExamStatus.published,
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          targetStudentIds: [studentId],
          title: 'Uzay Yolculuğu Sınavı (Test Lab)',
          questions: [
            const ExamQuestion(
              qid: 'q1',
              type: QuestionType.mcq,
              prompt: 'En büyük gezegen hangisidir?',
              choices: ['Mars', 'Jüpiter', 'Dünya', 'Venüs'],
              points: 10,
              rubric: QuestionRubric(
                acceptKeywords: ['Jüpiter'],
                rejectKeywords: [],
                confidenceThreshold: 0.8,
              ),
            ),
          ],
          estimatedMinutes: 20,
          maxScore: 100,
          instructions: ['Soruları dikkatlice oku.', 'Velinden yardım isteme.'],
          answerKey: const ExamAnswerKey(
            correctAnswers: {'q1': 'Jüpiter'},
            explanations: {'q1': 'Jüpiter güneş sisteminin en büyük gezegenidir.'},
            commonMistakes: {'q1': ['Satürn ile karıştırılabilir']},
          ),
          commonMisconceptions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
    }

    return _firestore
        .collection('schools/$_schoolId/exams')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: ExamStatus.published.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Exam.fromFirestore(doc))
              .where((exam) =>
                  exam.targetStudentIds.isEmpty ||
                  exam.targetStudentIds.contains(studentId))
              .toList();
        });
  }

  /// Watch single exam (for live stats updates)
  Stream<Exam?> watchExam(String examId) {
    if (TEST_LAB_MODE && examId == 'mock_exam_1') {
      return Stream.value(Exam(
          id: 'mock_exam_1',
          teacherId: 'mock_teacher_1',
          classId: 'global',
          schoolId: 'mock_school_1',
          gradeBand: 'ilkokul',
          timeWindow: 'haftalik',
          topics: ['Matematik', 'Uzay'],
          teacherStyle: 'oyunlaştırılmış',
          status: ExamStatus.published,
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          dueDate: DateTime.now().add(const Duration(days: 2)),
          targetStudentIds: [],
          title: 'Uzay Yolculuğu Sınavı (Test Lab)',
          questions: [
            const ExamQuestion(
              qid: 'q1',
              type: QuestionType.mcq,
              prompt: 'En büyük gezegen hangisidir?',
              choices: ['Mars', 'Jüpiter', 'Dünya', 'Venüs'],
              points: 10,
              rubric: QuestionRubric(
                acceptKeywords: ['Jüpiter'],
                rejectKeywords: [],
                confidenceThreshold: 0.8,
              ),
            ),
          ],
          estimatedMinutes: 20,
          maxScore: 100,
          instructions: ['Soruları dikkatlice oku.'],
          answerKey: const ExamAnswerKey(
            correctAnswers: {'q1': 'Jüpiter'},
            explanations: {'q1': 'Jüpiter güneş sisteminin en büyük gezegenidir.'},
            commonMistakes: {},
          ),
          commonMisconceptions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
    }

    return _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return Exam.fromFirestore(doc);
        });
  }

  // ==================== QUERIES ====================

  /// Get published exams by class
  Future<List<Exam>> getPublishedExams(String classId) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/exams')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: ExamStatus.published.name)
        .orderBy('publishedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList();
  }

  /// Get exam count for teacher
  Future<int> getTeacherExamCount(String teacherId) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/exams')
        .where('teacherId', isEqualTo: teacherId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Check if exam exists
  Future<bool> examExists(String examId) async {
    final doc = await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .get();

    return doc.exists;
  }

  /// Get exams by date range (for analytics)
  Future<List<Exam>> getExamsByDateRange({
    required String classId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/exams')
        .where('classId', isEqualTo: classId)
        .where('publishedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('publishedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs.map((doc) => Exam.fromFirestore(doc)).toList();
  }

  /// Increment submitted count (called by Cloud Function in real impl)
  /// For V1, can be called directly after submission
  Future<void> incrementSubmittedCount(String examId) async {
    await _firestore
        .collection('schools/$_schoolId/exams')
        .doc(examId)
        .update({
      'submittedCount': FieldValue.increment(1),
    });
  }
}
