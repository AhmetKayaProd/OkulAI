import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/services/homework_store.dart';
import 'package:kresai/services/submission_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/parent/homework_submission_screen.dart';

/// Parent Homework List Screen - Real-time view
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

          return ListView.builder(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            itemCount: homeworks.length,
            itemBuilder: (context, index) {
              final homework = homeworks[index];
              
              // For each homework, stream student's submission
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
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppTokens.textSecondaryLight,
          ),
          const SizedBox(height: AppTokens.spacing16),
          Text(
            'Henüz ödev yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spacing8),
          const Text(
            'Öğretmen ödev gönderdiğinde burada görünecek',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework, HomeworkSubmission? submission) {
    final now = DateTime.now();
    final daysUntilDue = homework.dueDate != null
        ? homework.dueDate!.difference(now).inDays
        : null;
    
    String dueText = 'Süresiz';
    Color? dueColor;
    IconData dueIcon = Icons.event;
    
    if (daysUntilDue != null) {
      if (daysUntilDue < 0) {
        dueText = 'Süresi doldu';
        dueColor = AppTokens.errorLight;
        dueIcon = Icons.event_busy;
      } else if (daysUntilDue == 0) {
        dueText = 'Bugün';
        dueColor = Colors.orange;
        dueIcon = Icons.event;
      } else if (daysUntilDue == 1) {
        dueText = 'Yarın';
        dueColor = Colors.orange;
      } else {
        dueText = '$daysUntilDue gün kaldı';
      }
    }

    // Determine status
    String statusText = 'Teslim edilmedi';
    Color statusColor = AppTokens.textSecondaryLight;
    IconData statusIcon = Icons.pending;
    String actionLabel = 'Başla';
    
    if (submission != null) {
      if (submission.sentToTeacher) {
        statusText = 'Gönderildi';
        statusColor = AppTokens.successLight;
        statusIcon = Icons.check_circle;
        actionLabel = 'Görüntüle';
        
        if (submission.teacherScore != null) {
          statusText = 'Puanlandı: ${submission.teacherScore}/${homework.option.gradingRubric.maxScore}';
        }
      } else if (submission.aiReview != null) {
        statusText = 'AI incelemede';
        statusColor = Colors.orange;
        statusIcon = Icons.auto_awesome;
        actionLabel = 'Devam Et';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(
                _getFormatIcon(homework.option.format),
                color: Colors.white,
              ),
            ),
            title: Text(
              homework.option.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppTokens.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${homework.option.estimatedMinutes} dk',
                      style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
                    ),
                    const SizedBox(width: 12),
                    Icon(dueIcon, size: 14, color: dueColor ?? AppTokens.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(
                      dueText,
                      style: TextStyle(
                        fontSize: 12,
                        color: dueColor ?? AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: submission != null && submission.aiReview != null
                ? Chip(
                    label: Text(
                      submission.aiReview!.verdict.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: _getVerdictColor(submission.aiReview!.verdict),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
          
          // Action button
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeworkSubmissionScreen(
                        homework: homework,
                        existingSubmission: submission,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  submission != null && submission.sentToTeacher
                      ? Icons.visibility
                      : Icons.edit,
                ),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: submission != null && submission.sentToTeacher
                      ? AppTokens.textSecondaryLight
                      : AppTokens.primaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFormatIcon(HomeworkFormat format) {
    switch (format) {
      case HomeworkFormat.drawing:
        return Icons.draw;
      case HomeworkFormat.mcq:
      case HomeworkFormat.trueFalse:
        return Icons.quiz;
      case HomeworkFormat.photoWorksheet:
        return Icons.photo;
      case HomeworkFormat.handsOn:
        return Icons.build;
      default:
        return Icons.assignment;
    }
  }

  Color _getVerdictColor(SubmissionVerdict verdict) {
    switch (verdict) {
      case SubmissionVerdict.readyToSend:
        return AppTokens.successLight.withOpacity(0.2);
      case SubmissionVerdict.needsRevision:
        return Colors.orange.withOpacity(0.2);
      case SubmissionVerdict.uncertain:
        return AppTokens.errorLight.withOpacity(0.2);
    }
  }
}
