import 'package:flutter_test/flutter_test.dart';
import 'package:kresai/models/exam_submission.dart';

void main() {
  group('ExamSubmission Model Tests', () {
    test('ExamSubmission toFirestore serialization', () {
      final submission = ExamSubmission(
        id: 'sub_123',
        examId: 'exam_456',
        studentId: 'student_789',
        parentId: 'parent_012',
        classId: 'class_1',
        answers: {
          'q1': 'A',
          'q2': 'Doğru',
          'q3': {'pair1': 'match1'},
        },
        photoUrls: ['https://example.com/photo1.jpg'],
        status: SubmissionStatus.graded,
        grade: ExamGrade(
          score: 8,
          maxScore: 10,
          confidence: 0.85,
          perQuestion: [
            QuestionGrade(
              qid: 'q1',
              earned: 1,
              max: 1,
              status: GradeStatus.correct,
            ),
          ],
          flags: [],
          parentFeedback: ParentFeedback(
            summary: 'Harika bir çaba!',
            strengths: ['Renk sorularında çok başarılı'],
            improvements: ['Sayma sorularını tekrar gözden geçirin'],
            hintsWithoutSolutions: ['3. soruda küçükten büyüğe sıralama yapın'],
          ),
        ),
        needsTeacherReview: false,
        startedAt: DateTime(2024, 1, 20, 10, 0),
        submittedAt: DateTime(2024, 1, 20, 10, 15),
        gradedAt: DateTime(2024, 1, 20, 10, 30),
        elapsedMinutes: 15,
      );

      final firestoreData = submission.toFirestore();

      expect(firestoreData['examId'], 'exam_456');
      expect(firestoreData['studentId'], 'student_789');
      expect(firestoreData['status'], 'graded');
      expect(firestoreData['answers']['q1'], 'A');
      expect(firestoreData['grade']['score'], 8);
      expect(firestoreData['elapsedMinutes'], 15);
    });

    test('ExamSubmission copyWith method', () {
      final original = ExamSubmission(
        id: 'sub_001',
        examId: 'exam_001',
        studentId: 'student_001',
        parentId: 'parent_001',
        classId: 'class_1',
        answers: {},
        status: SubmissionStatus.inProgress,
        startedAt: DateTime(2024, 1, 20),
      );

      final updated = original.copyWith(
        status: SubmissionStatus.submitted,
        submittedAt: DateTime(2024, 1, 20, 15, 30),
      );

      expect(updated.id, 'sub_001'); // Unchanged
      expect(updated.status, SubmissionStatus.submitted); // Changed
      expect(updated.submittedAt, DateTime(2024, 1, 20, 15, 30)); // Changed
      expect(updated.examId, 'exam_001'); // Unchanged
    });

    test('QuestionGrade JSON serialization', () {
      final questionGrade = QuestionGrade(
        qid: 'q1',
        earned: 1,
        max: 1,
        status: GradeStatus.correct,
        hint: 'Bu soru doğru!',
        topicTag: 'Renkler',
      );

      final json = questionGrade.toJson();

      expect(json['qid'], 'q1');
      expect(json['earned'], 1);
      expect(json['status'], 'correct');
      expect(json['hint'], 'Bu soru doğru!');
      expect(json['topicTag'], 'Renkler');

      final reconstructed = QuestionGrade.fromJson(json);

      expect(reconstructed.qid, questionGrade.qid);
      expect(reconstructed.status, questionGrade.status);
    });

    test('ParentFeedback JSON serialization', () {
      final feedback = ParentFeedback(
        summary: 'Çok iyi!',
        strengths: ['Güzel çalıştı'],
        improvements: ['Daha dikkatli ol'],
        hintsWithoutSolutions: ['Şu konuyu tekrar et'],
      );

      final json = feedback.toJson();

      expect(json['summary'], 'Çok iyi!');
      expect(json['strengths'], ['Güzel çalıştı']);
      expect(json['improvements'], ['Daha dikkatli ol']);

      final reconstructed = ParentFeedback.fromJson(json);

      expect(reconstructed.summary, feedback.summary);
      expect(reconstructed.strengths, feedback.strengths);
    });

    test('ExamGrade JSON serialization', () {
      final grade = ExamGrade(
        score: 7,
        maxScore: 10,
        confidence: 0.9,
        perQuestion: [
          QuestionGrade(
            qid: 'q1',
            earned: 1,
            max: 1,
            status: GradeStatus.correct,
          ),
        ],
        flags: ['low_confidence'],
        parentFeedback: ParentFeedback(
          summary: 'Test',
          strengths: [],
          improvements: [],
          hintsWithoutSolutions: [],
        ),
        teacherScore: 8,
        teacherFeedback: 'Öğretmen notu',
        isTeacherOverride: true,
      );

      final json = grade.toJson();

      expect(json['score'], 7);
      expect(json['maxScore'], 10);
      expect(json['confidence'], 0.9);
      expect(json['flags'], ['low_confidence']);
      expect(json['teacherScore'], 8);
      expect(json['isTeacherOverride'], true);

      final reconstructed = ExamGrade.fromJson(json);

      expect(reconstructed.score, grade.score);
      expect(reconstructed.teacherScore, grade.teacherScore);
      expect(reconstructed.isTeacherOverride, grade.isTeacherOverride);
    });

    test('ExamSubmission with empty answers', () {
      final submission = ExamSubmission(
        id: 'sub_empty',
        examId: 'exam_001',
        studentId: 'student_001',
        parentId: 'parent_001',
        classId: 'class_1',
        answers: {},
        status: SubmissionStatus.inProgress,
        startedAt: DateTime(2024, 1, 20),
      );

      expect(submission.answers.isEmpty, true);
      expect(submission.grade, isNull);
      expect(submission.submittedAt, isNull);
    });

    test('ExamSubmission with photo answers', () {
      final submission = ExamSubmission(
        id: 'sub_photo',
        examId: 'exam_001',
        studentId: 'student_001',
        parentId: 'parent_001',
        classId: 'class_1',
        answers: {},
        photoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
        ],
        status: SubmissionStatus.submitted,
        startedAt: DateTime(2024, 1, 20),
        submittedAt: DateTime(2024, 1, 20, 10, 30),
      );

      expect(submission.photoUrls, isNotNull);
      expect(submission.photoUrls!.length, 2);
    });
  });

  group('Enum Tests', () {
    test('SubmissionStatus enum values', () {
      expect(SubmissionStatus.inProgress.name, 'inProgress');
      expect(SubmissionStatus.submitted.name, 'submitted');
      expect(SubmissionStatus.graded.name, 'graded');
    });

    test('GradeStatus enum values', () {
      expect(GradeStatus.correct.name, 'correct');
      expect(GradeStatus.wrong.name, 'wrong');
      expect(GradeStatus.uncertain.name, 'uncertain');
    });

    test('GradeFlag enum values', () {
      expect(GradeFlag.lowConfidence.name, 'lowConfidence');
      expect(GradeFlag.suspectedHelp.name, 'suspectedHelp');
      expect(GradeFlag.unreadablePhoto.name, 'unreadablePhoto');
      expect(GradeFlag.incompleteAnswers.name, 'incompleteAnswers');
    });

    test('SubmissionStatus labels', () {
      expect(SubmissionStatus.inProgress.label, 'Devam Ediyor');
      expect(SubmissionStatus.submitted.label, 'Gönderildi');
      expect(SubmissionStatus.graded.label, 'Notlandı');
    });

    test('GradeStatus labels', () {
      expect(GradeStatus.correct.label, 'Doğru');
      expect(GradeStatus.wrong.label, 'Yanlış');
      expect(GradeStatus.uncertain.label, 'Belirsiz');
    });
  });

  group('Teacher Review Scenarios', () {
    test('Submission needing teacher review', () {
      final submission = ExamSubmission(
        id: 'sub_review',
        examId: 'exam_001',
        studentId: 'student_001',
        parentId: 'parent_001',
        classId: 'class_1',
        answers: {'q1': 'Belirsiz cevap'},
        status: SubmissionStatus.graded,
        grade: ExamGrade(
          score: 0,
          maxScore: 10,
          confidence: 0.3, // Low confidence
          perQuestion: [],
          flags: ['low_confidence', 'unreadable_photo'],
        ),
        needsTeacherReview: true,
        startedAt: DateTime(2024, 1, 20),
        submittedAt: DateTime(2024, 1, 20),
        gradedAt: DateTime(2024, 1, 20),
      );

      expect(submission.needsTeacherReview, true);
      expect(submission.grade!.confidence, lessThan(0.6));
      expect(submission.grade!.flags, contains('low_confidence'));
    });

    test('Teacher override scenario', () {
      final submission = ExamSubmission(
        id: 'sub_override',
        examId: 'exam_001',
        studentId: 'student_001',
        parentId: 'parent_001',
        classId: 'class_1',
        answers: {},
        status: SubmissionStatus.graded,
        grade: ExamGrade(
          score: 5, // AI score
          maxScore: 10,
          confidence: 0.7,
          perQuestion: [],
          flags: [],
          teacherScore: 7, // Teacher override
          teacherFeedback: 'Çabaya göre ek puan',
          isTeacherOverride: true,
        ),
        startedAt: DateTime(2024, 1, 20),
      );

      expect(submission.grade!.isTeacherOverride, true);
      expect(submission.grade!.teacherScore, greaterThan(submission.grade!.score));
      expect(submission.grade!.teacherFeedback, isNotNull);
    });
  });
}
