import 'package:flutter/material.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Exam Result Screen - Display student's exam results with feedback
class ExamResultScreen extends StatelessWidget {
  final String examId;
  final String studentId;

  const ExamResultScreen({
    super.key,
    required this.examId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final submissionStore = ExamSubmissionStore();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Sonucu'),
      ),
      body: StreamBuilder<ExamSubmission?>(
        stream: submissionStore.watchStudentSubmission(
          examId: examId,
          studentId: studentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final submission = snapshot.data;
          if (submission == null) {
            return const Center(
              child: Text('Sonuç bulunamadı'),
            );
          }

          if (submission.status != SubmissionStatus.graded) {
            return _buildPendingView(submission);
          }

          final grade = submission.grade!;
          final finalScore = grade.teacherScore ?? grade.score;

          return ListView(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            children: [
              _buildHeroSection(finalScore, grade.maxScore),
              const SizedBox(height: AppTokens.spacing24),
              
              if (grade.parentFeedback != null)
                _buildFeedbackCard(grade.parentFeedback!),
              
              const SizedBox(height: AppTokens.spacing24),
              
              _buildQuestionBreakdown(grade.perQuestion),
              
              if (grade.isTeacherOverride)
                ...[
                  const SizedBox(height: AppTokens.spacing24),
                  _buildTeacherNote(grade),
                ],
              
              const SizedBox(height: AppTokens.spacing24),
              
              _buildMetadata(submission),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingView(ExamSubmission submission) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending,
              size: 80,
              color: AppTokens.textSecondaryLight,
            ),
            const SizedBox(height: AppTokens.spacing16),
            Text(
              submission.status == SubmissionStatus.submitted
                  ? 'Puanlanıyor...'
                  : 'Sınav devam ediyor',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              submission.status == SubmissionStatus.submitted
                  ? 'Sonucunuz hazır olduğunda burada görüntülenecek'
                  : 'Sınavı tamamlayın ve gönderin',
              style: TextStyle(
                fontSize: 14,
                color: AppTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(int score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    
    // Determine emoji and color based on score
    String emoji;
    Color color;
    String message;
    
    if (percentage >= 80) {
      emoji = '😊';
      color = AppTokens.successLight;
      message = 'Harika!';
    } else if (percentage >= 60) {
      emoji = '🙂';
      color = Colors.blue;
      message = 'İyi iş!';
    } else {
      emoji = '😐';
      color = Colors.orange;
      message = 'Devam et!';
    }

    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: AppTokens.spacing16),
            Text(
              message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  ' / $maxScore',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing8),
            LinearProgressIndicator(
              value: score / maxScore,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(ParentFeedback feedback) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Geri Bildirim',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            
            Text(
              feedback.summary,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            if (feedback.strengths.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacing16),
              Text(
                'Güçlü Yönler',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.successLight,
                ),
              ),
              const SizedBox(height: 8),
              ...feedback.strengths.map((strength) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppTokens.successLight),
                      const SizedBox(width: 8),
                      Expanded(child: Text(strength)),
                    ],
                  ),
                );
              }),
            ],
            
            if (feedback.improvements.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacing16),
              Text(
                'Gelişim Alanları',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...feedback.improvements.map((improvement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(improvement)),
                    ],
                  ),
                );
              }),
            ],
            
            if (feedback.hintsWithoutSolutions.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacing16),
              Text(
                'İpuçları',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTokens.primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              ...feedback.hintsWithoutSolutions.map((hint) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(child: Text(hint)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBreakdown(List<QuestionGrade> perQuestion) {
    return Card(
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Icon(Icons.list_alt, color: AppTokens.primaryLight),
          title: const Text(
            'Soru Detayları',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${perQuestion.length} soru',
            style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
          ),
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: perQuestion.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final question = perQuestion[index];
                return _buildQuestionItem(question, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(QuestionGrade question, int number) {
    IconData icon;
    Color color;
    
    switch (question.status) {
      case GradeStatus.correct:
        icon = Icons.check_circle;
        color = AppTokens.successLight;
        break;
      case GradeStatus.wrong:
        icon = Icons.cancel;
        color = AppTokens.errorLight;
        break;
      case GradeStatus.uncertain:
        icon = Icons.help;
        color = Colors.orange;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text('Soru $number'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${question.earned}/${question.max} puan',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (question.topicTag != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    question.topicTag!,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                ),
              ],
            ],
          ),
          if (question.hint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTokens.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, size: 14, color: AppTokens.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.hint!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherNote(ExamGrade grade) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTokens.primaryLight,
                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Öğretmen Notu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Öğretmen Puanı: '),
                      Text(
                        '${grade.teacherScore}/${grade.maxScore}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (grade.teacherFeedback != null) ...[
                    const SizedBox(height: 8),
                    Text(grade.teacherFeedback!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(ExamSubmission submission) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sınav Bilgileri',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.schedule, 'Süre', '${submission.elapsedMinutes} dakika'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.send,
              'Gönderilme',
              submission.submittedAt != null
                  ? '${submission.submittedAt!.day}/${submission.submittedAt!.month}/${submission.submittedAt!.year}'
                  : '-',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.done_all,
              'Puanlandı',
              submission.gradedAt != null
                  ? '${submission.gradedAt!.day}/${submission.gradedAt!.month}/${submission.gradedAt!.year}'
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTokens.textSecondaryLight),
        const SizedBox(width: 8),
        Text('$label: '),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
