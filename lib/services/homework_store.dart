import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

/// Homework Store - Firestore-enabled
class HomeworkStore {
  static final HomeworkStore _instance = HomeworkStore._internal();
  factory HomeworkStore() => _instance;
  HomeworkStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _schoolId = 'default_school'; // TODO: Multi-school support

  // ==================== FIRESTORE OPERATIONS ====================

  /// Helper for Mock Data
  List<Homework> _getMockHomeworks() {
    return [
      Homework(
        id: 'mock_1',
        classId: 'mock_class',
        teacherId: 'mock_teacher',
        selectedOptionId: 'opt_1',
        option: HomeworkOption(
          optionId: 'opt_1',
          title: 'Victory Lap (Test Lab)',
          goal: 'Verification of End-to-End Flow',
          format: HomeworkFormat.handsOn,
          estimatedMinutes: 15,
          materials: ['Pencil', 'Paper', 'Determination'],
          studentInstructions: ['Step 1: Open the app.', 'Step 2: See this homework.', 'Step 3: Submit it!'],
          parentGuidance: ['Encourage the user to verify the list.'],
          submissionType: SubmissionType.photo,
          gradingRubric: const GradingRubric(maxScore: 100, criteria: []),
          teacherAnswerKey: const TeacherAnswerKey(notes: 'Ref', expectedPoints: [], sampleAnswers: []),
          adaptations: const Adaptations(easy: 'Simple', hard: 'Complex'),
        ),
        status: HomeworkStatus.published,
        targetStudentIds: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        publishedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
      )
    ];
  }

  /// Create new homework (draft)
  Future<String> createHomework({
    required String classId,
    required String teacherId,
    required HomeworkOption selectedOption,
    List<String> targetStudentIds = const [],
  }) async {
    // ⚠️ TEST LAB MOCK
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1));
      return 'mock_homework_${DateTime.now().millisecondsSinceEpoch}';
    }

    final docRef = _firestore
        .collection('schools/$_schoolId/homework')
        .doc();

    final homework = Homework(
      id: docRef.id,
      classId: classId,
      teacherId: teacherId,
      selectedOptionId: selectedOption.optionId,
      option: selectedOption,
      targetStudentIds: targetStudentIds,
      status: HomeworkStatus.draft,
      createdAt: DateTime.now(),
    );

    await docRef.set(homework.toFirestore());
    return docRef.id;
  }

  /// Publish homework to students
  Future<void> publishHomework({
    required String homeworkId,
    required DateTime dueDate,
  }) async {
    // ⚠️ TEST LAB MOCK
    if (TEST_LAB_MODE) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .update({
      'status': HomeworkStatus.published.name,
      'publishedAt': Timestamp.fromDate(DateTime.now()),
      'dueDate': Timestamp.fromDate(dueDate),
    });
  }

  /// Close homework (no more submissions)


  /// Close homework (no more submissions)
  Future<void> closeHomework(String homeworkId) async {
    if (TEST_LAB_MODE) return;
    await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .update({
      'status': HomeworkStatus.closed.name,
      'closedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update homework option (before publish)
  Future<void> updateHomework({
    required String homeworkId,
    required HomeworkOption updatedOption,
    DateTime? dueDate,
  }) async {
    if (TEST_LAB_MODE) return;
    final updateData = <String, dynamic>{
      'option': updatedOption.toJson(),
      'selectedOptionId': updatedOption.optionId,
    };

    if (dueDate != null) {
      updateData['dueDate'] = Timestamp.fromDate(dueDate);
    }

    await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .update(updateData);
  }

  /// Delete homework (only if draft)
  Future<void> deleteHomework(String homeworkId) async {
    if (TEST_LAB_MODE) return;
    await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .delete();
  }

  /// Get single homework
  Future<Homework?> getHomework(String homeworkId) async {
    if (TEST_LAB_MODE) return null; // Or return a mock object if needed
    final doc = await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .get();

    if (!doc.exists) return null;
    return Homework.fromFirestore(doc);
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Watch teacher's homeworks
  Stream<List<Homework>> watchTeacherHomeworks(String teacherId) {
    if (TEST_LAB_MODE) {
      // ⚠️ TEST LAB MOCK: Return empty list or mock data
      return Stream.value(_getMockHomeworks());
    }

    return _firestore
        .collection('schools/$_schoolId/homework')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList());
  }

  /// Watch homeworks for a class (parent view)
  Stream<List<Homework>> watchClassHomeworks(String classId) {
    if (TEST_LAB_MODE) return Stream.value(_getMockHomeworks());
    return _firestore
        .collection('schools/$_schoolId/homework')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: HomeworkStatus.published.name)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList());
  }

  Stream<List<Homework>> watchStudentHomeworks({
    required String classId,
    required String studentId,
  }) {
    if (TEST_LAB_MODE) return Stream.value(_getMockHomeworks());
    return _firestore
        .collection('schools/$_schoolId/homework')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: HomeworkStatus.published.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Homework.fromFirestore(doc))
              .where((hw) =>
                  hw.targetStudentIds.isEmpty ||
                  hw.targetStudentIds.contains(studentId))
              .toList();
        });
  }

  // ==================== QUERIES ====================

  /// Get published homeworks by class
  Future<List<Homework>> getPublishedHomeworks(String classId) async {
    if (TEST_LAB_MODE) return _getMockHomeworks();
    final snapshot = await _firestore
        .collection('schools/$_schoolId/homework')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: HomeworkStatus.published.name)
        .orderBy('publishedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList();
  }

  /// Get homework count for teacher
  Future<int> getTeacherHomeworkCount(String teacherId) async {
    if (TEST_LAB_MODE) return 5;

    final snapshot = await _firestore
        .collection('schools/$_schoolId/homework')
        .where('teacherId', isEqualTo: teacherId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Check if homework exists
  Future<bool> homeworkExists(String homeworkId) async {
    final doc = await _firestore
        .collection('schools/$_schoolId/homework')
        .doc(homeworkId)
        .get();

    return doc.exists;
  }

  /// Watch all published homeworks (for parent view)
  Stream<List<Homework>> watchAllPublishedHomeworks() {
    if (TEST_LAB_MODE) return Stream.value(_getMockHomeworks());
    return _firestore
        .collection('schools/$_schoolId/homework')
        .where('status', isEqualTo: HomeworkStatus.published.name)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Homework.fromFirestore(doc)).toList());
  }
}
