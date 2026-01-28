import 'package:flutter/material.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/services/exam_store.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/screens/parent/exam_participation_screen.dart';
import 'package:kresai/screens/parent/exam_result_screen.dart';
import 'package:kresai/theme/tokens.dart';

/// Exam List Screen - Parent view of available and completed exams
class ExamListScreen extends StatefulWidget {
  final String studentId;
  final String parentId;
  final String classId;

  const ExamListScreen({
    super.key,
    required this.studentId,
    required this.parentId,
    required this.classId,
  });

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> with SingleTickerProviderStateMixin {
  final _examStore = ExamStore();
  final _submissionStore = ExamSubmissionStore();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınavlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bekliyor', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Gönderildi', icon: Icon(Icons.send)),
            Tab(text: 'Notlandı', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, ExamSubmission>>(
        stream: _submissionStore.watchAllStudentSubmissions(widget.studentId),
        builder: (context, submissionSnapshot) {
          final submissionMap = submissionSnapshot.data ?? {};

          return StreamBuilder<List<Exam>>(
            stream: _examStore.watchStudentExams(
              classId: widget.classId,
              studentId: widget.studentId,
            ),
            builder: (context, examSnapshot) {
              if (examSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (examSnapshot.hasError) {
                return Center(
                  child: Text('Hata: ${examSnapshot.error}'),
                );
              }

              final exams = examSnapshot.data ?? [];

              // Filter exams by status
              final pendingExams = exams.where((exam) {
                final submission = submissionMap[exam.id];
                return submission == null || submission.status == SubmissionStatus.inProgress;
              }).toList();

              final submittedExams = exams.where((exam) {
                final submission = submissionMap[exam.id];
                return submission?.status == SubmissionStatus.submitted;
              }).toList();

              final gradedExams = exams.where((exam) {
                final submission = submissionMap[exam.id];
                return submission?.status == SubmissionStatus.graded;
              }).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildExamList(pendingExams, submissionMap, 'pending'),
                  _buildExamList(submittedExams, submissionMap, 'submitted'),
                  _buildExamList(gradedExams, submissionMap, 'graded'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExamList(
    List<Exam> exams,
    Map<String, ExamSubmission> submissionMap,
    String category,
  ) {
    if (exams.isEmpty) {
      return _buildEmptyState(category);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final submission = submissionMap[exam.id];
        return _buildExamCard(exam, submission, category);
      },
    );
  }

  Widget _buildEmptyState(String category) {
    String message;
    IconData icon;

    switch (category) {
      case 'pending':
        message = 'Bekleyen sınav yok';
        icon = Icons.check_circle_outline;
        break;
      case 'submitted':
        message = 'Puanlanan sınav yok';
        icon = Icons.pending_actions;
        break;
      case 'graded':
        message = 'Notlandırılmış sınav yok';
        icon = Icons.star_outline;
        break;
      default:
        message = 'Sınav bulunamadı';
        icon = Icons.quiz_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTokens.textSecondaryLight,
          ),
          const SizedBox(height: AppTokens.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Exam exam, ExamSubmission? submission, String category) {
    final now = DateTime.now();
    final daysUntilDue = exam.dueDate != null
        ? exam.dueDate!.difference(now).inDays
        : null;

    Color? urgencyColor;
    String dueText = 'Süresiz';
    
    if (daysUntilDue != null) {
      if (daysUntilDue < 0) {
        dueText = 'Süresi doldu';
        urgencyColor = AppTokens.errorLight;
      } else if (daysUntilDue == 0) {
        dueText = 'Bugün';
        urgencyColor = Colors.orange;
      } else if (daysUntilDue == 1) {
        dueText = 'Yarın';
        urgencyColor = Colors.orange;
      } else {
        dueText = '$daysUntilDue gün kaldı';
      }
    }

    // Determine status badge
    String statusText;
    Color statusColor;
    
    if (submission == null) {
      statusText = 'Başlanmadı';
      statusColor = Colors.grey;
    } else {
      switch (submission.status) {
        case SubmissionStatus.inProgress:
          statusText = 'Devam ediyor';
          statusColor = Colors.blue;
          break;
        case SubmissionStatus.submitted:
          statusText = 'Puanlanıyor';
          statusColor = Colors.orange;
          break;
        case SubmissionStatus.graded:
          final score = submission.grade!.teacherScore ?? submission.grade!.score;
          final maxScore = submission.grade!.maxScore;
          statusText = '$score/$maxScore';
          statusColor = AppTokens.successLight;
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: InkWell(
        onTap: () => _handleExamTap(exam, submission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz,
                      color: AppTokens.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.topics.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTokens.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(statusText),
                    backgroundColor: statusColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTokens.spacing12),
              
              // Info row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.quiz,
                    '${exam.questions.length} soru',
                  ),
                  _buildInfoChip(
                    Icons.schedule,
                    '~${exam.estimatedMinutes} dk',
                  ),
                  if (exam.dueDate != null)
                    _buildInfoChip(
                      Icons.event,
                      dueText,
                      color: urgencyColor,
                    ),
                ],
              ),
              
              // Progress indicator for in-progress exams
              if (submission != null && submission.status == SubmissionStatus.inProgress) ...[
                const SizedBox(height: AppTokens.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: submission.answers.length / exam.questions.length,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(AppTokens.primaryLight),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${submission.answers.length}/${exam.questions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? AppTokens.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color ?? AppTokens.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  void _handleExamTap(Exam exam, ExamSubmission? submission) {
    if (submission?.status == SubmissionStatus.graded) {
      // Navigate to result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamResultScreen(
            examId: exam.id,
            studentId: widget.studentId,
          ),
        ),
      );
    } else {
      // Navigate to participation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamParticipationScreen(
            exam: exam,
            studentId: widget.studentId,
            parentId: widget.parentId,
          ),
        ),
      );
    }
  }
}
