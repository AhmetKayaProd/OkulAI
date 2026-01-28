import 'package:flutter/material.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/services/submission_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Homework Review Screen - Teacher reviews student submissions (Real-time)
class HomeworkReviewScreen extends StatefulWidget {
  final Homework homework;

  const HomeworkReviewScreen({
    super.key,
    required this.homework,
  });

  @override
  State<HomeworkReviewScreen> createState() => _HomeworkReviewScreenState();
}

class _HomeworkReviewScreenState extends State<HomeworkReviewScreen> {
  final _submissionStore = SubmissionStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homework.option.title),
      ),
      body: StreamBuilder<List<HomeworkSubmission>>(
        stream: _submissionStore.watchHomeworkSubmissions(widget.homework.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final submissions = snapshot.data ?? [];
          final completedCount = submissions.where((s) => s.sentToTeacher).length;
          final totalStudents = widget.homework.targetStudentIds.isEmpty
              ? 20 // TODO: Get from class size
              : widget.homework.targetStudentIds.length;

          double averageScore = 0.0;
          if (completedCount > 0) {
            final scores = submissions
                .where((s) => s.sentToTeacher && (s.teacherScore != null || s.aiReview != null))
                .map((s) => s.teacherScore ?? s.aiReview!.scoreSuggestion.suggestedScore);
            if (scores.isNotEmpty) {
              averageScore = scores.reduce((a, b) => a + b) / scores.length;
            }
          }

          return Column(
            children: [
              // Stats Card
              _buildStatsCard(completedCount, totalStudents, averageScore),
              
              // Submission List
              Expanded(
                child: submissions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        itemCount: submissions.length,
                        itemBuilder: (context, index) {
                          return _buildSubmissionCard(submissions[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(int completedCount, int totalStudents, double averageScore) {
    return Card(
      margin: const EdgeInsets.all(AppTokens.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Teslim',
                  '$completedCount/$totalStudents',
                  Icons.inbox,
                  AppTokens.primaryLight,
                ),
                _buildStatItem(
                  'Ortalama',
                  completedCount > 0 ? averageScore.toStringAsFixed(1) : '-',
                  Icons.star,
                  AppTokens.successLight,
                ),
                _buildStatItem(
                  'Bekleyen',
                  '${totalStudents - completedCount}',
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
            
            if (completedCount > 0) ...[ 
              const SizedBox(height: AppTokens.spacing16),
              LinearProgressIndicator(
                value: completedCount / totalStudents,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppTokens.primaryLight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppTokens.textSecondaryLight,
          ),
          const SizedBox(height: AppTokens.spacing16),
          Text(
            'Henüz teslim yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spacing8),
          const Text(
            'Öğrenciler ödev teslim ettiğinde burada görünecek',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(HomeworkSubmission submission) {
    final aiScore = submission.aiReview?.scoreSuggestion.suggestedScore;
    final finalScore = submission.teacherScore ?? aiScore;
    final confidence = submission.aiReview?.confidence ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: submission.sentToTeacher
                  ? AppTokens.successLight
                  : Colors.orange,
              child: Text(
                submission.studentId.substring(0, 2).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              'Öğrenci ${submission.studentId}', // TODO: Get student name
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
                      _formatDate(submission.submittedAt),
                      style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
                    ),
                    const SizedBox(width: 12),
                    if (submission.reviewCount > 1) ...[ 
                      Icon(Icons.refresh, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${submission.reviewCount}. deneme',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
                if (submission.aiReview != null && submission.aiReview!.flags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: submission.aiReview!.flags.map((flag) {
                        return Chip(
                          label: Text(flag, style: const TextStyle(fontSize: 10)),
                          backgroundColor: AppTokens.errorLight.withOpacity(0.2),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (finalScore != null) ...[
                  Text(
                    '$finalScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(finalScore, widget.homework.option.gradingRubric.maxScore),
                    ),
                  ),
                  Text(
                    '/${widget.homework.option.gradingRubric.maxScore}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  if (confidence < 0.7)
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange,
                    ),
                ],
              ],
            ),
          ),
          
          if (submission.sentToTeacher) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submission content preview
                  if (submission.textContent != null)
                    Text(
                      submission.textContent!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (submission.photoUrls != null && submission.photoUrls!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.photo, size: 16, color: AppTokens.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '${submission.photoUrls!.length} fotoğraf',
                          style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight),
                        ),
                      ],
                    ),
                  
                  // AI reasoning bullets
                  if (submission.aiReview != null) ...[
                    const SizedBox(height: AppTokens.spacing8),
                    Text(
                      'AI Değerlendirmesi:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                    ...submission.aiReview!.scoreSuggestion.reasoningBullets.take(2).map((bullet) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '• $bullet',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            OverflowBar(
              children: [
                TextButton.icon(
                  onPressed: () => _showSubmissionDetail(submission),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Detay'),
                ),
                TextButton.icon(
                  onPressed: () => _showScoreDialog(submission),
                  icon: const Icon(Icons.edit),
                  label: const Text('Puanla'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score, int maxScore) {
    final percentage = score / maxScore;
    if (percentage >= 0.8) return AppTokens.successLight;
    if (percentage >= 0.6) return Colors.orange;
    return AppTokens.errorLight;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showSubmissionDetail(HomeworkSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teslim Detayı',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing16),
                
                // Full submission content
                if (submission.textContent != null) ...[
                  const Text('İçerik:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(submission.textContent!),
                  const SizedBox(height: AppTokens.spacing16),
                ],
                
                if (submission.aiReview != null) ...[
                  const Divider(),
                  const Text(
                    'AI Analizi & Veli Geri Bildirimi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  
                  // Score Reasoning
                  ...submission.aiReview!.scoreSuggestion.reasoningBullets.map((bullet) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $bullet', style: const TextStyle(fontStyle: FontStyle.italic)),
                    );
                  }),
                  const SizedBox(height: 8),

                  // Good Points
                  if (submission.aiReview!.feedbackToParent.whatIsGood.isNotEmpty) ...[
                    const Text('✅ İyi Yönler:', style: TextStyle(fontWeight: FontWeight.w500)),
                    ...submission.aiReview!.feedbackToParent.whatIsGood.map((item) => Text('  • $item')),
                    const SizedBox(height: 8),
                  ],

                  // Improvements
                  if (submission.aiReview!.feedbackToParent.whatToImprove.isNotEmpty) ...[
                    const Text('🛠️ Geliştirilmeli:', style: TextStyle(fontWeight: FontWeight.w500)),
                    ...submission.aiReview!.feedbackToParent.whatToImprove.map((item) => Text('  • $item')),
                    const SizedBox(height: 8),
                  ],

                  // Hints
                  if (submission.aiReview!.feedbackToParent.hintsWithoutSolution.isNotEmpty) ...[
                    const Text('💡 İpuçları:', style: TextStyle(fontWeight: FontWeight.w500)),
                    ...submission.aiReview!.feedbackToParent.hintsWithoutSolution.map((item) => Text('  • $item')),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScoreDialog(HomeworkSubmission submission) {
    final controller = TextEditingController(
      text: (submission.teacherScore ?? submission.aiReview?.scoreSuggestion.suggestedScore)?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puan Ver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submission.aiReview != null)
              Text(
                'AI önerisi: ${submission.aiReview!.scoreSuggestion.suggestedScore}/${widget.homework.option.gradingRubric.maxScore}',
                style: TextStyle(color: AppTokens.textSecondaryLight),
              ),
            const SizedBox(height: AppTokens.spacing16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Puan (max ${widget.homework.option.gradingRubric.maxScore})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            on

Pressed: () async {
              final score = int.tryParse(controller.text);
              if (score == null || score < 0 || score > widget.homework.option.gradingRubric.maxScore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçersiz puan')),
                );
                return;
              }

              try {
                // Update submission with teacher score
                final updatedSubmission = submission.copyWith(
                  teacherScore: score,
                  gradedAt: DateTime.now(),
                );
                await _submissionStore.updateSubmission(updatedSubmission);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Puan kaydedildi'),
                      backgroundColor: Colors.green,
                    ),
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
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
