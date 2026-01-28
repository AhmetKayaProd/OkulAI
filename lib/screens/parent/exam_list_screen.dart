import 'package:flutter/material.dart';
import '../../models/exam.dart';
import '../../models/exam_submission.dart';
import '../../services/exam_store.dart';
import '../../services/exam_submission_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import 'exam_participation_screen.dart';
import 'exam_result_screen.dart';

class ParentExamListScreen extends StatefulWidget {
  const ParentExamListScreen({super.key});

  @override
  State<ParentExamListScreen> createState() => _ParentExamListScreenState();
}

class _ParentExamListScreenState extends State<ParentExamListScreen> with SingleTickerProviderStateMixin {
  final _examStore = ExamStore();
  final _submissionStore = ExamSubmissionStore();
  late TabController _tabController;

  final String _studentId = 'mock_student_id';
  final String _classId = 'global';

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
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Sınavlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bekliyor'),
            Tab(text: 'Gönderildi'),
            Tab(text: 'Notlandı'),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, ExamSubmission>>(
        stream: _submissionStore.watchAllStudentSubmissions(_studentId),
        builder: (context, submissionSnapshot) {
          final submissionMap = submissionSnapshot.data ?? {};

          return StreamBuilder<List<Exam>>(
            stream: _examStore.watchStudentExams(classId: _classId, studentId: _studentId),
            builder: (context, examSnapshot) {
              if (examSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (examSnapshot.hasError) {
                return Center(child: Text('Hata: ${examSnapshot.error}'));
              }

              final exams = examSnapshot.data ?? [];

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

  Widget _buildExamList(List<Exam> exams, Map<String, ExamSubmission> submissionMap, String category) {
    if (exams.isEmpty) {
      return _buildEmptyState(category);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.spacing20),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing16),
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
        icon = Icons.pending_actions_outlined;
        break;
      case 'submitted':
        message = 'Gönderilmiş sınav yok';
        icon = Icons.send_outlined;
        break;
      case 'graded':
        message = 'Notlandırılmış sınav yok';
        icon = Icons.star_outline_rounded;
        break;
      default:
        message = 'Sınav bulunamadı';
        icon = Icons.quiz_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing24),
            decoration: const BoxDecoration(
              color: AppTokens.primaryLightSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppTokens.primaryLight),
          ),
          const SizedBox(height: AppTokens.spacing24),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Exam exam, ExamSubmission? submission, String category) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (category == 'pending') {
      statusColor = AppTokens.warningLight;
      statusIcon = Icons.pending_outlined;
      statusText = 'Bekliyor';
    } else if (category == 'submitted') {
      statusColor = AppTokens.infoLight;
      statusIcon = Icons.send_outlined;
      statusText = 'Gönderildi';
    } else {
      statusColor = AppTokens.successLight;
      statusIcon = Icons.star_rounded;
      statusText = 'Notlandı';
    }

    return ModernCard(
      onTap: () {
        if (category == 'graded' && submission != null) {
          // Sonuç ekranı henüz uyarlanmadı
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sınav sonuçları yakında görüntülenebilecek')),
          );
        } else {
          // Katılım ekranı henüz uyarlanmadı
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sınav katılımı yakında aktif olacak')),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz_outlined, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exam.questions.length} soru',
                      style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 16, color: AppTokens.textSecondaryLight),
              const SizedBox(width: 6),
              Text('${exam.questions.length} soru', style: const TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight)),
              const Spacer(),
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}
