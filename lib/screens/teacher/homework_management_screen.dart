import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/services/homework_store.dart';
import 'package:kresai/services/submission_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/homework_creation_screen.dart';
import 'package:kresai/screens/teacher/homework_report_screen.dart';
import 'package:kresai/app.dart'; // for TEST_LAB_MODE

/// Homework Management Screen - Real-time list of published homeworks
class HomeworkManagementScreen extends StatefulWidget {
  const HomeworkManagementScreen({super.key});

  @override
  State<HomeworkManagementScreen> createState() => _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState extends State<HomeworkManagementScreen> {
  final HomeworkStore _homeworkStore = HomeworkStore();
  final SubmissionStore _submissionStore = SubmissionStore();

  // Smart ID: Use real User check OR Test Mode bypass
  String? get _teacherId {
    if (TEST_LAB_MODE) return 'test_teacher_id_123';
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_teacherId == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödevlerim'),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeworkCreationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Yeni Ödev'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primaryLight,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Homework>>(
        stream: _homeworkStore.watchTeacherHomeworks(_teacherId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          final homeworks = snapshot.data ?? [];
          
          if (homeworks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            itemCount: homeworks.length,
            itemBuilder: (context, index) {
              return _buildHomeworkCard(homeworks[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 100,
              color: AppTokens.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: AppTokens.spacing24),
            const Text(
              'Henüz ödev yok!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            Text(
              'Öğrencilerinize ilk ödevi vermek için\nAI yardımıyla hızlıca başlayın!',
              style: TextStyle(
                fontSize: 14,
                color: AppTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeworkCreationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI ile Hızlıca Oluştur'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeworkCreationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manuel Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    final now = DateTime.now();
    final daysUntilDue = homework.dueDate != null
        ? homework.dueDate!.difference(now).inDays
        : null;
    
    String dueText = 'Süresiz';
    Color? dueColor;
    if (daysUntilDue != null) {
      if (daysUntilDue < 0) {
        dueText = 'Süresi doldu';
        dueColor = AppTokens.errorLight;
      } else if (daysUntilDue == 0) {
        dueText = 'Bugün';
        dueColor = Colors.orange;
      } else {
        dueText = '$daysUntilDue gün kaldı';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: homework.status == HomeworkStatus.published
                  ? AppTokens.primaryLight
                  : AppTokens.textSecondaryLight,
              child: Icon(
                homework.option.format == HomeworkFormat.drawing
                    ? Icons.draw
                    : homework.option.format == HomeworkFormat.mcq
                        ? Icons.quiz
                        : Icons.assignment,
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
                    Icon(Icons.event, size: 14, color: dueColor ?? AppTokens.textSecondaryLight),
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
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: homework.status == HomeworkStatus.published
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: homework.status == HomeworkStatus.published
                      ? Colors.green
                      : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: homework.status == HomeworkStatus.published
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    homework.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: homework.status == HomeworkStatus.published
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Real-time Stats from SubmissionStore
          StreamBuilder<List<HomeworkSubmission>>(
            stream: _submissionStore.watchHomeworkSubmissions(homework.id),
            builder: (context, submSnapshot) {
              final submissions = submSnapshot.data ?? [];
              final total = submissions.length;
              final graded = submissions.where((s) => s.teacherScore != null).length;
              final avgScore = graded > 0
                  ? (submissions
                      .where((s) => s.teacherScore != null)
                      .fold<double>(0, (sum, s) => sum + s.teacherScore!) / graded)
                      .toStringAsFixed(1)
                  : '-';
              final pending = total - graded;

              return Container(
                padding: const EdgeInsets.all(AppTokens.spacing12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Teslim', '$graded', Icons.inbox),
                    _buildStat('Ortalama', avgScore, Icons.star),
                    _buildStat('Bekleyen', '$pending', Icons.pending),
                  ],
                ),
              );
            },
          ),
          
          // Actions with hierarchy
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Primary action
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Navigate to review screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İnceleme ekranı yakında...')),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Gönderilenleri Gör'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Secondary action
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeworkReportScreen(homework: homework),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Rapor'),
                ),
                const SizedBox(width: 8),
                // More menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'close':
                        _showCloseDialog(homework);
                        break;
                      case 'share':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaşma yakında...')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 18),
                          SizedBox(width: 12),
                          Text('Paylaş'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.close, size: 18),
                          SizedBox(width: 12),
                          Text('Ödevi Kapat'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTokens.primaryLight),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  void _showCloseDialog(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödevi Kapat'),
        content: const Text(
          'Bu ödevi kapatmak istediğinize emin misiniz? '
          'Artık yeni teslim alınmayacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _homeworkStore.closeHomework(homework.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ödev kapatıldı')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
