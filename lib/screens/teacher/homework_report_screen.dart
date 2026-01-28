import 'package:flutter/material.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/models/homework_submission.dart';
import 'package:kresai/models/homework_report.dart';
import 'package:kresai/services/submission_store.dart';
import 'package:kresai/services/homework_ai_service.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

/// Homework Report Screen - Real-time assignment analytics
class HomeworkReportScreen extends StatefulWidget {
  final Homework homework;

  const HomeworkReportScreen({
    super.key,
    required this.homework,
  });

  @override
  State<HomeworkReportScreen> createState() => _HomeworkReportScreenState();
}

class _HomeworkReportScreenState extends State<HomeworkReportScreen> {
  final _submissionStore = SubmissionStore();
  final _aiService = HomeworkAIService();
  
  AIHomeworkInsights? _aiInsights;
  bool _isGeneratingAI = false;
  bool _aiAttempted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödev Raporu'),
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
          final report = _generateReport(submissions);

          // Auto-trigger AI for TEST_LAB_MODE if not done yet and we have data
          if (TEST_LAB_MODE && !_aiAttempted && report.completion.done > 0 && !_isGeneratingAI) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _analyzeClass(report, submissions);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
              children: [
                if (_aiInsights != null) _buildAIInsightsSection(_aiInsights!),
                if (_isGeneratingAI) 
                  const Card(
                     child: Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Center(child: Column(
                         children: [
                           CircularProgressIndicator(),
                           SizedBox(height: 8),
                           Text("Yapay Zeka Sınıfı Analiz Ediyor..."),
                         ],
                       )),
                     )
                  ),
                _buildAssignmentReport(report),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _analyzeClass(AssignmentReport report, List<HomeworkSubmission> submissions) async {
    if (_isGeneratingAI) return;
    
    setState(() {
      _isGeneratingAI = true;
      _aiAttempted = true;
    });

    try {
      final insights = await _aiService.generateClassInsights(
        homework: widget.homework,
        averageScore: report.averageScore,
        commonIssues: report.commonIssues,
      );
      
      if (mounted) {
        setState(() {
          _aiInsights = insights;
        });
      }
    } catch (e) {
      print("AI Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  AssignmentReport _generateReport(List<HomeworkSubmission> submissions) {
    final totalStudents = widget.homework.targetStudentIds.isEmpty
        ? 20 // TODO: Get from class size
        : widget.homework.targetStudentIds.length;

    final sentSubmissions = submissions.where((s) => s.sentToTeacher).toList();
    final doneCount = sentSubmissions.length;

    // Calculate average score
    double avgScore = 0.0;
    if (doneCount > 0) {
      final scores = sentSubmissions
          .where((s) => s.teacherScore != null || s.aiReview != null)
          .map((s) => s.teacherScore ?? s.aiReview!.scoreSuggestion.suggestedScore);
      if (scores.isNotEmpty) {
        avgScore = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    // Score distribution (for max score 10)
    final maxScore = widget.homework.option.gradingRubric.maxScore;
    Map<String, int> scoreDistribution = {
      '0-2': 0,
      '3-4': 0,
      '5-6': 0,
      '7-8': 0,
      '9-10': 0,
    };

    for (final s in sentSubmissions) {
      final score = s.teacherScore ?? s.aiReview?.scoreSuggestion.suggestedScore;
      if (score != null) {
        final normalized = (score / maxScore * 10).round();
        if (normalized <= 2) scoreDistribution['0-2'] = scoreDistribution['0-2']! + 1;
        else if (normalized <= 4) scoreDistribution['3-4'] = scoreDistribution['3-4']! + 1;
        else if (normalized <= 6) scoreDistribution['5-6'] = scoreDistribution['5-6']! + 1;
        else if (normalized <= 8) scoreDistribution['7-8'] = scoreDistribution['7-8']! + 1;
        else scoreDistribution['9-10'] = scoreDistribution['9-10']! + 1;
      }
    }

    // Common issues from AI flags
    Map<String, int> flagCounts = {};
    for (final s in sentSubmissions) {
      if (s.aiReview != null) {
        for (final flag in s.aiReview!.flags) {
          flagCounts[flag] = (flagCounts[flag] ?? 0) + 1;
        }
      }
    }

    final commonIssues = flagCounts.entries
        .where((e) => e.value >= 2) // At least 2 occurrences
        .map((e) => '${e.key} (${e.value} öğrenci)')
        .toList();

    // Students needing attention (low scores or multiple revisions)
    final needsAttention = sentSubmissions
        .where((s) {
          final score = s.teacherScore ?? s.aiReview?.scoreSuggestion.suggestedScore;
          return (score != null && score < maxScore * 0.5) || s.reviewCount > 2;
        })
        .map((s) => AttentionNeeded(
              studentId: s.studentId,
              reason: s.reviewCount > 2
                  ? '${s.reviewCount} kez denedi'
                  : 'Düşük puan',
            ))
        .toList();

    // Pending students
    final submittedIds = submissions.map((s) => s.studentId).toSet();
    final pendingIds = List<String>.from(
      widget.homework.targetStudentIds.where((id) => !submittedIds.contains(id)),
    );

    return AssignmentReport(
      assignmentId: widget.homework.id,
      completion: CompletionStats(done: doneCount, total: totalStudents),
      averageScore: avgScore,
      scoreDistribution: scoreDistribution,
      commonIssues: commonIssues,
      needsAttention: needsAttention,
      pendingStudentIds: pendingIds,
    );
  }

  Widget _buildAIInsightsSection(AIHomeworkInsights insights) {
    return Card(
      color: Colors.purple.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'AI Sınıf Analizi',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.purple
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insights.summary,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            
            // Misconceptions
            if (insights.keyMisconceptions.isNotEmpty) ...[
              const Text(
                '⚠️ Yaygın Kavram Yanılgıları',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...insights.keyMisconceptions.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.red)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Recommendations
            if (insights.recommendationsForTeacher.isNotEmpty) ...[
              const Text(
                '💡 Öğretmen İçin Öneriler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...insights.recommendationsForTeacher.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓ ', style: TextStyle(color: Colors.green)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentReport(AssignmentReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Completion Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tamamlanma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTokens.spacing12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.completion.done}/${report.completion.total}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${report.completion.percentage.toStringAsFixed(0)}% tamamlandı',
                            style: TextStyle(
                              color: AppTokens.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: report.completion.percentage / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppTokens.primaryLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppTokens.spacing16),
        
        // Score Distribution Card
        if (report.completion.done > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Puan Dağılımı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ort: ${report.averageScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTokens.successLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  ...report.scoreDistribution.entries.map((entry) {
                    return _buildScoreBar(entry.key, entry.value, report.completion.done);
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
        ],
        
        // Common Issues Card
        if (report.commonIssues.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Sık Karşılaşılan Sorunlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  ...report.commonIssues.map((issue) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(child: Text(issue)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
        ],
        
        // Needs Attention Card
        if (report.needsAttention.isNotEmpty) ...[ 
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.priority_high, color: AppTokens.errorLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Dikkat Gerektiren Öğrenciler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  ...report.needsAttention.map((attention) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.person, color: AppTokens.primaryLight),
                      title: Text('Öğrenci ${attention.studentId}'),
                      subtitle: Text(attention.reason),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreBar(String range, int count, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(range),
              Text('$count öğrenci'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppTokens.primaryLight),
          ),
        ],
      ),
    );
  }
}
