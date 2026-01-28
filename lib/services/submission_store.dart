import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

/// Homework Submission Store - Firestore-enabled
class SubmissionStore {
  static final SubmissionStore _instance = SubmissionStore._internal();
  factory SubmissionStore() => _instance;
  SubmissionStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support

  // ==================== FIRESTORE OPERATIONS ====================

  /// Create new submission
  Future<String> createSubmission({
    required String homeworkId,
    required String studentId,
    required String parentId,
    required String submissionType,
    String? textContent,
    List<String>? photoUrls,
    Map<String, dynamic>? interactiveAnswers,
  }) async {
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1));
      return 'mock_sub_${DateTime.now().millisecondsSinceEpoch}';
    }
    final docRef = _firestore
        .collection('schools/$_schoolId/submissions')
        .doc();

    final submission = HomeworkSubmission(
      id: docRef.id,
      homeworkId: homeworkId,
      studentId: studentId,
      parentId: parentId,
      submissionType: submissionType,
      textContent: textContent,
      photoUrls: photoUrls,
      interactiveAnswers: interactiveAnswers,
      submittedAt: DateTime.now(),
      reviewCount: 0,
      sentToTeacher: false,
    );

    await docRef.set(submission.toFirestore());
    return docRef.id;
  }

  /// Update submission with AI review
  Future<void> updateWithAIReview({
    required String submissionId,
    required AIReview aiReview,
  }) async {
    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .update({
      'aiReview': aiReview.toJson(),
      'reviewCount': FieldValue.increment(1),
    });
  }

  /// Send submission to teacher
  Future<void> sendToTeacher(String submissionId) async {
    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .update({
      'sentToTeacher': true,
    });
  }

  /// Teacher adds score and feedback
  Future<void> teacherGrade({
    required String submissionId,
    required int score,
    String? feedback,
  }) async {
    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .update({
      'teacherScore': score,
      'teacherFeedback': feedback,
    });
  }

  /// Update submission content (revision)
  Future<void> updateSubmissionContent({
    required String submissionId,
    String? textContent,
    List<String>? photoUrls,
    Map<String, dynamic>? interactiveAnswers,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (textContent != null) updateData['textContent'] = textContent;
    if (photoUrls != null) updateData['photoUrls'] = photoUrls;
    if (interactiveAnswers != null) updateData['interactiveAnswers'] = interactiveAnswers;
    
    updateData['submittedAt'] = Timestamp.fromDate(DateTime.now());

    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .update(updateData);
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .delete();
  }

  /// Create submission from HomeworkSubmission object (wrapper)
  Future<HomeworkSubmission> createSubmissionFromObject(HomeworkSubmission submission) async {
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1));
      return submission.copyWith(
        id: 'mock_sub_obj_${DateTime.now().millisecondsSinceEpoch}',
        submittedAt: DateTime.now(),
      );
    }
    final docRef = _firestore
        .collection('schools/$_schoolId/submissions')
        .doc();

    final submissionWithId = HomeworkSubmission(
      id: docRef.id,
      homeworkId: submission.homeworkId,
      studentId: submission.studentId,
      parentId: submission.parentId,
      submissionType: submission.submissionType,
      textContent: submission.textContent,
      photoUrls: submission.photoUrls,
      interactiveAnswers: submission.interactiveAnswers,
      aiReview: submission.aiReview,
      teacherScore: submission.teacherScore,
      teacherFeedback: submission.teacherFeedback,
      submittedAt: submission.submittedAt,
      reviewCount: submission.reviewCount,
      sentToTeacher: submission.sentToTeacher,
    );

    await docRef.set(submissionWithId.toFirestore());
    return submissionWithId;
  }

  /// Update submission from HomeworkSubmission object (wrapper)
  Future<void> updateSubmission(HomeworkSubmission submission) async {
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
    await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submission.id)
        .set(submission.toFirestore(), SetOptions(merge: true));
  }

  /// Get single submission
  Future<HomeworkSubmission?> getSubmission(String submissionId) async {
    final doc = await _firestore
        .collection('schools/$_schoolId/submissions')
        .doc(submissionId)
        .get();

    if (!doc.exists) return null;
    return HomeworkSubmission.fromFirestore(doc);
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Watch submissions for a homework (teacher view)
  Stream<List<HomeworkSubmission>> watchHomeworkSubmissions(String homeworkId) {
      if (TEST_LAB_MODE) {
      return Stream.value([
        HomeworkSubmission(
          id: 'mock_sub_1',
          homeworkId: homeworkId,
          studentId: 'Ali Veli',
          parentId: 'mock_parent_id',
          photoUrls: ['https://placeholder.com/homework.jpg'],
          textContent: 'Renkleri ayırdık ve saydık.',
          submissionType: 'text',
          reviewCount: 1,
          aiReview: AIReview(
            verdict: SubmissionVerdict.readyToSend,
            confidence: 0.95,
            scoreSuggestion: const ScoreSuggestion(
              maxScore: 100,
              suggestedScore: 95,
              reasoningBullets: ['Gayet basarili', 'Renkler dogru'],
            ),
            feedbackToParent: const FeedbackToParent(
              tone: 'Positive',
              whatIsGood: ['Sayim dogru', 'Gorseller net'],
              whatToImprove: [],
              hintsWithoutSolution: ['Daha fazla nesne eklenebilir'],
            ),
            flags: const [],
            reviewedAt: DateTime.now(),
          ), 
          sentToTeacher: true,
          submittedAt: DateTime.now(),
        ),
      ]);
    }
    return _firestore
        .collection('schools/$_schoolId/submissions')
        .where('homeworkId', isEqualTo: homeworkId)
        .where('sentToTeacher', isEqualTo: true)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HomeworkSubmission.fromFirestore(doc))
            .toList());
  }

  /// Watch student's submission for a homework (parent view)
  Stream<HomeworkSubmission?> watchStudentSubmission({
    required String homeworkId,
    required String studentId,
  }) {
    if (TEST_LAB_MODE) return Stream.value(null);
    return _firestore
        .collection('schools/$_schoolId/submissions')
        .where('homeworkId', isEqualTo: homeworkId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return HomeworkSubmission.fromFirestore(snapshot.docs.first);
        });
  }

  /// Watch all submissions for a student (parent view - all homeworks)
  Stream<Map<String, HomeworkSubmission>> watchAllStudentSubmissions(String studentId) {
    return _firestore
        .collection('schools/$_schoolId/submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final map = <String, HomeworkSubmission>{};
          for (final doc in snapshot.docs) {
            final submission = HomeworkSubmission.fromFirestore(doc);
            map[submission.homeworkId] = submission;
          }
          return map;
        });
  }

  // ==================== QUERIES ====================

  /// Get submissions for a homework
  Future<List<HomeworkSubmission>> getHomeworkSubmissions(String homeworkId) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/submissions')
        .where('homeworkId', isEqualTo: homeworkId)
        .where('sentToTeacher', isEqualTo: true)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => HomeworkSubmission.fromFirestore(doc))
        .toList();
  }

  /// Get student's submission for a homework
  Future<HomeworkSubmission?> getStudentSubmission({
    required String homeworkId,
    required String studentId,
  }) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/submissions')
        .where('homeworkId', isEqualTo: homeworkId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return HomeworkSubmission.fromFirestore(snapshot.docs.first);
  }

  /// Get submission count for homework
  Future<int> getSubmissionCount(String homeworkId) async {
    final snapshot = await _firestore
        .collection('schools/$_schoolId/submissions')
        .where('homeworkId', isEqualTo: homeworkId)
        .where('sentToTeacher', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get average score for homework
  Future<double> getAverageScore(String homeworkId) async {
    final submissions = await getHomeworkSubmissions(homeworkId);
    
    if (submissions.isEmpty) return 0.0;

    final scores = submissions
        .where((s) => s.teacherScore != null || s.aiReview != null)
        .map((s) => s.teacherScore ?? s.aiReview!.scoreSuggestion.suggestedScore)
        .toList();

    if (scores.isEmpty) return 0.0;

    final sum = scores.reduce((a, b) => a + b);
    return sum / scores.length;
  }

  /// Check if student has submitted
  Future<bool> hasStudentSubmitted({
    required String homeworkId,
    required String studentId,
  }) async {
    final submission = await getStudentSubmission(
      homeworkId: homeworkId,
      studentId: studentId,
    );
    return submission != null && submission.sentToTeacher;
  }
}
