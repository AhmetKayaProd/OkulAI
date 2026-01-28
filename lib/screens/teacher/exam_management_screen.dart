import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/services/exam_store.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/exam_creation_screen.dart';
import 'package:kresai/screens/teacher/exam_report_screen.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

/// Exam Management Screen - Real-time list of published exams
class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> with SingleTickerProviderStateMixin {
  final ExamStore _examStore = ExamStore();
  final ExamSubmissionStore _submissionStore = ExamSubmissionStore();
  final String? _currentTeacherId = TEST_LAB_MODE 
      ? 'test-teacher-id' // Mock teacher ID for testing
      : FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTeacherId == null) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapın')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınavlarım'),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExamCreationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sınav'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primaryLight,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif', icon: Icon(Icons.schedule)),
            Tab(text: 'Arşiv', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamList([ExamStatus.draft, ExamStatus.published]),
          _buildExamList([ExamStatus.closed]),
        ],
      ),
    );
  }

  Widget _buildExamList(List<ExamStatus> statuses) {
    return StreamBuilder<List<Exam>>(
      stream: _examStore.watchTeacherExams(_currentTeacherId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final allExams = snapshot.data ?? [];
        final filteredExams = allExams.where((e) => statuses.contains(e.status)).toList();
        
        if (filteredExams.isEmpty) {
          return _buildEmptyState(statuses.contains(ExamStatus.closed));
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh by rebuilding stream
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            itemCount: filteredExams.length,
            itemBuilder: (context, index) {
              return _buildExamCard(filteredExams[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isArchive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchive ? Icons.archive_outlined : Icons.quiz_outlined,
              size: 100,
              color: AppTokens.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: AppTokens.spacing24),
            Text(
              isArchive ? 'Henüz arşivlenmiş sınav yok' : 'Henüz sınav yok!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            if (!isArchive) ...[
              Text(
                'İlk sınavınızı oluşturmak sadece birkaç dakika sürer.\nAI yardımıyla hızlıca başlayın!',
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
                      builder: (_) => const ExamCreationScreen(),
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
                      builder: (_) => const ExamCreationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Manuel Oluştur'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Exam exam) {
    final now = DateTime.now();
    final daysUntilDue = exam.dueDate != null
        ? exam.dueDate!.difference(now).inDays
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
              backgroundColor: exam.status == ExamStatus.published
                  ? AppTokens.primaryLight
                  : exam.status == ExamStatus.draft
                      ? Colors.orange
                      : AppTokens.textSecondaryLight,
              child: Icon(
                exam.status == ExamStatus.draft
                    ? Icons.edit
                    : Icons.quiz,
                color: Colors.white,
              ),
            ),
            title: Text(
              exam.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  exam.topics.join(', '),
                  style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppTokens.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.estimatedMinutes} dk • ${exam.questions.length} soru',
                      style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
                    ),
                    const SizedBox(width: 12),
                    if (exam.dueDate != null) ...[
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
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: exam.status == ExamStatus.published
                    ? Colors.green.withOpacity(0.15)
                    : exam.status == ExamStatus.draft
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: exam.status == ExamStatus.published
                      ? Colors.green
                      : exam.status == ExamStatus.draft
                          ? Colors.orange
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
                      color: exam.status == ExamStatus.published
                          ? Colors.green
                          : exam.status == ExamStatus.draft
                              ? Colors.orange
                              : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    exam.status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: exam.status == ExamStatus.published
                          ? Colors.green.shade800
                          : exam.status == ExamStatus.draft
                              ? Colors.orange.shade800
                              : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Real-time Stats from ExamSubmissionStore
          if (exam.status != ExamStatus.draft)
            StreamBuilder<List<ExamSubmission>>(
              stream: _submissionStore.watchExamSubmissions(exam.id),
              builder: (context, submSnapshot) {
                final submissions = submSnapshot.data ?? [];
                final total = exam.totalStudents;
                final submitted = submissions.length;
                final graded = submissions.where((s) => s.status == SubmissionStatus.graded).length;
                
                // Calculate average score
                final gradedSubmissions = submissions.where((s) => s.grade != null).toList();
                final avgScore = gradedSubmissions.isNotEmpty
                    ? (gradedSubmissions
                        .fold<double>(0, (sum, s) => sum + (s.grade!.teacherScore ?? s.grade!.score)) / gradedSubmissions.length)
                        .toStringAsFixed(1)
                    : '-';
                
                final pending = total - submitted;
                final participationPercent = total > 0 ? ((submitted / total) * 100).toInt() : 0;

                return Container(
                  padding: const EdgeInsets.all(AppTokens.spacing12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: total > 0 ? submitted / total : 0,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(AppTokens.primaryLight),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '%$participationPercent',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTokens.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Katılım', '$submitted/$total', Icons.people),
                          _buildStat('Ortalama', avgScore, Icons.star),
                          _buildStat('Bekleyen', '$pending', Icons.pending),
                        ],
                      ),
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
                if (exam.status != ExamStatus.draft)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamReportScreen(examId: exam.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('Sonuçları Gör'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.primaryLight,
                      ),
                    ),
                  ),
                if (exam.status == ExamStatus.draft)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to edit screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Düzenleme yakında...')),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Düzenle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.primaryLight,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Secondary action
                if (exam.status != ExamStatus.draft)
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to review screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İnceleme yakında...')),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('İncele'),
                  ),
                const SizedBox(width: 8),
                // More menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'close':
                        _showCloseDialog(exam);
                        break;
                      case 'delete':
                        _showDeleteDialog(exam);
                        break;
                      case 'share':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaşma yakında...')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (exam.status == ExamStatus.published)
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
                    if (exam.status == ExamStatus.published)
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 18),
                            SizedBox(width: 12),
                            Text('Sınavı Kapat'),
                          ],
                        ),
                      ),
                    if (exam.status == ExamStatus.draft)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Sil', style: TextStyle(color: Colors.red)),
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

  void _showCloseDialog(Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınavı Kapat'),
        content: const Text(
          'Bu sınavı kapatmak istediğinize emin misiniz? '
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
                await _examStore.closeExam(exam.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sınav kapatıldı')),
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

  void _showDeleteDialog(Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taslağı Sil'),
        content: const Text(
          'Bu taslak sınavı silmek istediğinize emin misiniz? '
          'Bu işlem geri alınamaz.',
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
                await _examStore.deleteExam(exam.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Taslak silindi')),
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
            style: TextButton.styleFrom(foregroundColor: AppTokens.errorLight),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
