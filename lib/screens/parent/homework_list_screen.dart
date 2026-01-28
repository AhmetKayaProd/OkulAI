import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app.dart';
import '../../models/homework.dart';
import '../../models/homework_submission.dart';
import '../../services/homework_store.dart';
import '../../services/submission_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import 'homework_submission_screen.dart';

class ParentHomeworkListScreen extends StatefulWidget {
  const ParentHomeworkListScreen({super.key});

  @override
  State<ParentHomeworkListScreen> createState() => _ParentHomeworkListScreenState();
}

class _ParentHomeworkListScreenState extends State<ParentHomeworkListScreen> {
  final HomeworkStore _homeworkStore = HomeworkStore();
  final SubmissionStore _submissionStore = SubmissionStore();
  final String? _currentUserId = TEST_LAB_MODE ? 'mock_parent_id' : FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın')),
      );
    }

    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Ödevler'),
      ),
      body: StreamBuilder<List<Homework>>(
        stream: _homeworkStore.watchAllPublishedHomeworks(),
        builder: (context, homeworkSnapshot) {
          if (homeworkSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (homeworkSnapshot.hasError) {
            return Center(child: Text('Hata: ${homeworkSnapshot.error}'));
          }

          final homeworks = homeworkSnapshot.data ?? [];

          if (homeworks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTokens.spacing20),
            itemCount: homeworks.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing16),
            itemBuilder: (context, index) {
              final homework = homeworks[index];
              
              return StreamBuilder<HomeworkSubmission?>(
                stream: _submissionStore.watchStudentSubmission(homeworkId: homework.id, studentId: _currentUserId!),
                builder: (context, submSnapshot) {
                  final submission = submSnapshot.data;
                  return _buildHomeworkCard(homework, submission);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.assignment_outlined, size: 64, color: AppTokens.primaryLight),
          ),
          const SizedBox(height: AppTokens.spacing24),
          const Text(
            'Henüz ödev yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
          ),
          const SizedBox(height: AppTokens.spacing8),
          const Text(
            'Öğretmen ödev gönderdiğinde burada görünecek',
            style: TextStyle(color: AppTokens.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework, HomeworkSubmission? submission) {
    final now = DateTime.now();
    final daysUntilDue = homework.dueDate != null ? homework.dueDate!.difference(now).inDays : null;
    
    String dueText = 'Süresiz';
    Color dueColor = AppTokens.textSecondaryLight;
    IconData dueIcon = Icons.event_outlined;
    
    if (daysUntilDue != null) {
      if (daysUntilDue < 0) {
        dueText = 'Süresi doldu';
        dueColor = AppTokens.errorLight;
        dueIcon = Icons.event_busy_rounded;
      } else if (daysUntilDue == 0) {
        dueText = 'Bugün';
        dueColor = AppTokens.warningLight;
        dueIcon = Icons.today_rounded;
      } else if (daysUntilDue <= 3) {
        dueText = '$daysUntilDue gün kaldı';
        dueColor = AppTokens.warningLight;
        dueIcon = Icons.schedule_rounded;
      } else {
        dueText = '$daysUntilDue gün kaldı';
        dueColor = AppTokens.textSecondaryLight;
        dueIcon = Icons.event_outlined;
      }
    }

    String statusText = 'Başlanmadı';
    Color statusColor = AppTokens.textTertiaryLight;
    IconData statusIcon = Icons.radio_button_unchecked_rounded;

    if (submission != null) {
      if (submission.submittedAt != null) {
        statusText = 'Gönderildi';
        statusColor = AppTokens.infoLight;
        statusIcon = Icons.check_circle_outline_rounded;
      } else {
        statusText = 'Devam ediyor';
        statusColor = AppTokens.warningLight;
        statusIcon = Icons.pending_outlined;
      }
    }

    return ModernCard(
      onTap: () {
        // Ödev gönderim ekranı henüz uyarlanmadı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödev gönderimi yakında aktif olacak')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTokens.primaryLightSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined, color: AppTokens.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    homework.option.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    homework.option.goal,
                    style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(dueIcon, size: 16, color: dueColor),
              const SizedBox(width: 6),
              Text(dueText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dueColor)),
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
