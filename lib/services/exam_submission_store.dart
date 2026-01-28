import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/app.dart';

/// Exam Submission Store - Firestore-enabled CRUD operations
class ExamSubmissionStore {
  static final ExamSubmissionStore _instance = ExamSubmissionStore._internal();
  factory ExamSubmissionStore() => _instance;
  ExamSubmissionStore._internal() {
    _ensureMockInitialized();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support

  // In-memory store for TEST_LAB_MODE - lazy initialized with mock data
  static final Map<String, ExamSubmission> _mockSubmissions = {};
  static bool _mockInitialized = false;
  
  static void _ensureMockInitialized() {
    if (!TEST_LAB_MODE || _mockInitialized) return;
    _mockInitialized = true;
    
    final now = DateTime.now();
    _mockSubmissions['mock_sub_teacher_demo'] = ExamSubmission(
      id: 'mock_sub_teacher_demo',
      examId: 'mock_exam_1',  // Matches the getExam mock
      studentId: 'mock_student_1',
      parentId: 'mock_parent_1',
      classId: 'global',
      answers: {'q1': 'Jüpiter'},
      photoUrls: [],
      status: SubmissionStatus.graded,
      grade: const ExamGrade(
        score: 100,
        maxScore: 100,
        confidence: 0.95,
        perQuestion: [
          QuestionGrade(
            qid: 'q1',
            earned: 10,
            max: 10,
            status: GradeStatus.correct,
            hint: null,
            topicTag: 'Uzay',
          ),
        ],
        flags: [],
        parentFeedback: ParentFeedback(
          summary: 'Harika bir performans! Tüm soruları doğru yanıtladın.',
          strengths: ['Uzay bilgisi mükemmel', 'Gezegen isimlerini iyi biliyor'],
          improvements: [],
          hintsWithoutSolutions: ['Böyle devam et!'],
        ),
      ),
      needsTeacherReview: false,
      startedAt: now.subtract(const Duration(hours: 1)),
      submittedAt: now.subtract(const Duration(minutes: 30)),
      gradedAt: now.subtract(const Duration(minutes: 25)),
      elapsedMinutes: 15,
    );
  }
  
  final _mockStreamController = StreamController<Map<String, ExamSubmission>>.broadcast();

  // ==================== FIRESTORE OPERATIONS ====================

  /// Create/save submission (auto-save during exam)
  Future<String> saveSubmission(ExamSubmission submission) async {
    if (TEST_LAB_MODE) {
      final id = submission.id.isEmpty ? 'mock_sub_${DateTime.now().millisecondsSinceEpoch}' : submission.id;
      final newSubmission = submission.copyWith(id: id);
      _mockSubmissions[id] = newSubmission;
      _emitMockUpdate();
      return id;
    }
    
    final docRef = submission.id.isEmpty
        ? _firestore.collection('schools/$_schoolId/examSubmissions').doc()
        : _firestore.collection('schools/$_schoolId/examSubmissions').doc(submission.id);

    final submissionWithId = ExamSubmission(
      id: docRef.id,
      examId: submission.examId,
      studentId: submission.studentId,
      parentId: submission.parentId,
      classId: submission.classId,
      answers: submission.answers,
      photoUrls: submission.photoUrls,
      status: submission.status,
      grade: submission.grade,
      needsTeacherReview: submission.needsTeacherReview,
      startedAt: submission.startedAt,
      submittedAt: submission.submittedAt,
      gradedAt: submission.gradedAt,
      elapsedMinutes: submission.elapsedMinutes,
    );

    await docRef.set(submissionWithId.toFirestore());
    return docRef.id;
  }

  /// Submit for grading (change status)
  Future<void> submitForGrading(String submissionId) async {
    if (TEST_LAB_MODE) {
      if (_mockSubmissions.containsKey(submissionId)) {
        final sub = _mockSubmissions[submissionId]!;
        _mockSubmissions[submissionId] = sub.copyWith(
          status: SubmissionStatus.submitted,
          submittedAt: DateTime.now(),
        );
        _emitMockUpdate();
      }
      return;
    }

    await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .update({
      'status': SubmissionStatus.submitted.name,
      'submittedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update grade (AI or teacher)
  Future<void> updateGrade({
    required String submissionId,
    required ExamGrade grade,
  }) async {
    if (TEST_LAB_MODE) {
      if (_mockSubmissions.containsKey(submissionId)) {
        final sub = _mockSubmissions[submissionId]!;
        _mockSubmissions[submissionId] = sub.copyWith(
          grade: grade,
          status: SubmissionStatus.graded,
          gradedAt: DateTime.now(),
          needsTeacherReview: grade.confidence < 0.6 || grade.flags.contains('lowConfidence'),
        );
        _emitMockUpdate();
      }
      return;
    }

    await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .update({
      'grade': grade.toJson(),
      'status': SubmissionStatus.graded.name,
      'gradedAt': Timestamp.fromDate(DateTime.now()),
      'needsTeacherReview': grade.confidence < 0.6 || grade.flags.contains('lowConfidence'),
    });
  }

  /// Teacher override (manual score)
  Future<void> overrideGrade({
    required String submissionId,
    required int teacherScore,
    String? teacherFeedback,
  }) async {
    // Get current grade
    final submission = await getSubmission(submissionId);
    if (submission == null || submission.grade == null) {
      throw Exception('Submission or grade not found');
    }

    // Create updated grade with teacher override
    final updatedGrade = ExamGrade(
      score: submission.grade!.score,
      maxScore: submission.grade!.maxScore,
      confidence: submission.grade!.confidence,
      perQuestion: submission.grade!.perQuestion,
      flags: submission.grade!.flags,
      parentFeedback: submission.grade!.parentFeedback,
      teacherScore: teacherScore,
      teacherFeedback: teacherFeedback,
      isTeacherOverride: true,
    );

    if (TEST_LAB_MODE) {
      if (_mockSubmissions.containsKey(submissionId)) {
         _mockSubmissions[submissionId] = submission.copyWith(
           grade: updatedGrade,
           needsTeacherReview: false,
         );
         _emitMockUpdate();
      }
      return;
    }

    await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .update({
      'grade': updatedGrade.toJson(),
      'needsTeacherReview': false, // Teacher reviewed, no longer needs review
    });
  }

  /// Update answers (during exam)
  Future<void> updateAnswers({
    required String submissionId,
    required Map<String, dynamic> answers,
    required int elapsedMinutes,
  }) async {
    if (TEST_LAB_MODE) {
      if (_mockSubmissions.containsKey(submissionId)) {
        final sub = _mockSubmissions[submissionId]!;
        _mockSubmissions[submissionId] = sub.copyWith(
          answers: answers,
          elapsedMinutes: elapsedMinutes,
        );
        _emitMockUpdate(); // Optional: might be too frequent, but okay for local dev
      }
      return;
    }

    await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .update({
      'answers': answers,
      'elapsedMinutes': elapsedMinutes,
    });
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    if (TEST_LAB_MODE) {
      _mockSubmissions.remove(submissionId);
      _emitMockUpdate();
      return;
    }
    await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .delete();
  }

  /// Get single submission
  Future<ExamSubmission?> getSubmission(String submissionId) async {
    if (TEST_LAB_MODE) {
       return _mockSubmissions[submissionId];
    }

    final doc = await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .doc(submissionId)
        .get();

    if (!doc.exists) return null;
    return ExamSubmission.fromFirestore(doc);
  }

  // ==================== REAL-TIME LISTENERS ====================

  void _emitMockUpdate() {
    _mockStreamController.add(_mockSubmissions);
  }

  /// Watch submissions for an exam (teacher view)
  Stream<List<ExamSubmission>> watchExamSubmissions(String examId) {
    if (TEST_LAB_MODE) {
      return _mockStreamController.stream.map((map) {
        return map.values
            .where((s) => s.examId == examId && (s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded))
            .toList();
      }).asBroadcastStream(onListen: (_) => _emitMockUpdate());
    }

    return _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('status', whereIn: [SubmissionStatus.submitted.name, SubmissionStatus.graded.name])
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamSubmission.fromFirestore(doc))
            .toList());
  }

  /// Watch student's submission for an exam (parent view)
  Stream<ExamSubmission?> watchStudentSubmission({
    required String examId,
    required String studentId,
  }) {
    // Note: Firestore implementation omitted for brevity as asked to replace file content
     if (TEST_LAB_MODE) {
      return _mockStreamController.stream.map((map) {
        try {
          return map.values.firstWhere(
            (s) => s.examId == examId && s.studentId == studentId,
          );
        } catch (e) {
          return null;
        }
      }).asBroadcastStream(onListen: (_) => _emitMockUpdate());
    }
    
    return _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ExamSubmission.fromFirestore(snapshot.docs.first);
        });
  }

  /// Watch all submissions for a student (parent view - all exams)
  Stream<Map<String, ExamSubmission>> watchAllStudentSubmissions(String studentId) {
    if (TEST_LAB_MODE) {
      return _mockStreamController.stream.map((map) {
        final studentSubs = map.values.where((s) => s.studentId == studentId);
        final result = <String, ExamSubmission>{};
        for (final sub in studentSubs) {
          result[sub.examId] = sub;
        }
        return result;
      }).asBroadcastStream(onListen: (_) => _emitMockUpdate());
    }

    return _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final map = <String, ExamSubmission>{};
          for (final doc in snapshot.docs) {
            final submission = ExamSubmission.fromFirestore(doc);
            map[submission.examId] = submission;
          }
          return map;
        });
  }

  /// Watch submissions needing teacher review
  Stream<List<ExamSubmission>> watchPendingReviews(String teacherId) {
    if (TEST_LAB_MODE) {
        return _mockStreamController.stream.map((map) {
        return map.values
            .where((s) => s.needsTeacherReview && s.status == SubmissionStatus.graded)
            .toList();
      }).asBroadcastStream(onListen: (_) => _emitMockUpdate());
    }

    return _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('needsTeacherReview', isEqualTo: true)
        .where('status', isEqualTo: SubmissionStatus.graded.name)
        .orderBy('gradedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamSubmission.fromFirestore(doc))
            .toList());
  }

  // ==================== QUERIES ====================

  /// Get submissions for an exam
  Future<List<ExamSubmission>> getExamSubmissions(String examId) async {
    if (TEST_LAB_MODE) {
      return _mockSubmissions.values
          .where((s) => s.examId == examId && (s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded))
          .toList();
    }

    final snapshot = await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('status', whereIn: [SubmissionStatus.submitted.name, SubmissionStatus.graded.name])
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExamSubmission.fromFirestore(doc))
        .toList();
  }

  /// Get student's submission for an exam
  Future<ExamSubmission?> getStudentSubmission({
    required String examId,
    required String studentId,
  }) async {
    if (TEST_LAB_MODE) {
      try {
        return _mockSubmissions.values.firstWhere(
            (s) => s.examId == examId && s.studentId == studentId);
      } catch (e) {
        return null;
      }
    }

    final snapshot = await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ExamSubmission.fromFirestore(snapshot.docs.first);
  }

  /// Get submission count for exam
  Future<int> getSubmissionCount(String examId) async {
    if (TEST_LAB_MODE) {
      return _mockSubmissions.values
          .where((s) => s.examId == examId && (s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.graded))
          .length;
    }

    final snapshot = await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('status', whereIn: [SubmissionStatus.submitted.name, SubmissionStatus.graded.name])
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get average score for exam
  Future<double> getAverageScore(String examId) async {
    if (TEST_LAB_MODE) {
      final submissions = _mockSubmissions.values
          .where((s) => s.examId == examId && s.grade != null)
          .toList();
      
      if (submissions.isEmpty) return 0.0;
      
      final sum = submissions
          .map((s) => s.grade!.teacherScore ?? s.grade!.score)
          .reduce((a, b) => a + b);
      
      return sum / submissions.length;
    }

    final submissions = await getExamSubmissions(examId);
    
    if (submissions.isEmpty) return 0.0;

    final scores = submissions
        .where((s) => s.grade != null)
        .map((s) => s.grade!.teacherScore ?? s.grade!.score)
        .toList();

    if (scores.isEmpty) return 0.0;

    final sum = scores.reduce((a, b) => a + b);
    return sum / scores.length;
  }

  /// Check if student has submitted
  Future<bool> hasStudentSubmitted({
    required String examId,
    required String studentId,
  }) async {
    final submission = await getStudentSubmission(
      examId: examId,
      studentId: studentId,
    );
    return submission != null && 
           (submission.status == SubmissionStatus.submitted || 
            submission.status == SubmissionStatus.graded);
  }

  /// Get graded submissions (for analytics)
  Future<List<ExamSubmission>> getGradedSubmissions(String examId) async {
    if (TEST_LAB_MODE) {
      return _mockSubmissions.values
          .where((s) => s.examId == examId && s.status == SubmissionStatus.graded)
          .toList();
    }

    final snapshot = await _firestore
        .collection('schools/$_schoolId/examSubmissions')
        .where('examId', isEqualTo: examId)
        .where('status', isEqualTo: SubmissionStatus.graded.name)
        .get();

    return snapshot.docs
        .map((doc) => ExamSubmission.fromFirestore(doc))
        .toList();
  }

  /// Get pending students (not submitted)
  Future<List<String>> getPendingStudents({
    required String examId,
    required List<String> targetStudentIds,
  }) async {
    final submissions = await getExamSubmissions(examId);
    final submittedStudentIds = submissions.map((s) => s.studentId).toSet();
    
    return targetStudentIds
        .where((id) => !submittedStudentIds.contains(id))
        .toList();
  }
}
