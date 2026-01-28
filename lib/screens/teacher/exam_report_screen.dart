import 'package:flutter/material.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/models/exam_report.dart';
import 'package:kresai/services/exam_store.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/services/exam_report_service.dart';
import 'package:kresai/theme/tokens.dart';
import 'dart:math' as math;

/// Exam Report Screen - Visual analytics for exam performance
class ExamReportScreen extends StatefulWidget {
  final String examId;

  const ExamReportScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends State<ExamReportScreen> {
  final _examStore = ExamStore();
  final _submissionStore = ExamSubmissionStore();
  final _reportService = ExamReportService();

  bool _isGenerating = false;
  ExamReport? _cachedReport;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    print('[ExamReportScreen] Starting report generation for examId: ${widget.examId}');
    setState(() => _isGenerating = true);
    try {
      final report = await _reportService.generateExamReport(widget.examId);
      print('[ExamReportScreen] Report generated successfully: ${report.submittedCount} submissions');
      if (mounted) {
        setState(() {
          _cachedReport = report;
          _isGenerating = false;
        });
      }
    } catch (e, stackTrace) {
      print('[ExamReportScreen] Error generating report: $e');
      print('[ExamReportScreen] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor oluşturulamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Raporu'),
        actions: [
          IconButton(
            onPressed: _generateReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rapor hazırlanıyor...'),
                ],
              ),
            )
          : FutureBuilder<Exam?>(
              future: _examStore.getExam(widget.examId),
              builder: (context, examSnapshot) {
                if (!examSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final exam = examSnapshot.data!;

                return RefreshIndicator(
                  onRefresh: _generateReport,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.spacing16),
                    children: [
                      _buildHeader(exam),
                      const SizedBox(height: AppTokens.spacing24),
                      
                      if (_cachedReport != null) ...[
                        if (_cachedReport!.aiInsights != null) ...[
                          _buildAIInsightsSection(_cachedReport!.aiInsights!),
                          const SizedBox(height: AppTokens.spacing24),
                        ],
                        _buildParticipationSection(_cachedReport!, exam),
                        const SizedBox(height: AppTokens.spacing24),
                        
                        _buildScoreDistributionSection(_cachedReport!),
                        const SizedBox(height: AppTokens.spacing24),
                        
                        _buildQuestionBreakdownSection(_cachedReport!),
                        
                        if (_cachedReport!.topicAccuracy.isNotEmpty) ...[
                          const SizedBox(height: AppTokens.spacing24),
                          _buildTopicAccuracySection(_cachedReport!),
                        ],
                      ] else ...[
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Rapor verisi yok'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader(Exam exam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.quiz, '${exam.questions.length} Soru'),
                _buildInfoChip(Icons.star, '${exam.maxScore} Puan'),
                _buildInfoChip(Icons.schedule, '${exam.estimatedMinutes} dk'),
                if (exam.dueDate != null)
                  _buildInfoChip(
                    Icons.event,
                    '${exam.dueDate!.day}/${exam.dueDate!.month}/${exam.dueDate!.year}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTokens.textSecondaryLight),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildParticipationSection(ExamReport report, Exam exam) {
    final participationPercent = report.totalStudents > 0
        ? ((report.submittedCount / report.totalStudents) * 100).toInt()
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Katılım',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Donut chart
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    submitted: report.submittedCount,
                    pending: report.totalStudents - report.submittedCount,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$participationPercent%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.primaryLight,
                          ),
                        ),
                        Text(
                          'Katılım',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTokens.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTokens.primaryLight, 'Teslim Etti (${report.submittedCount})'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey, 'Bekliyor (${report.totalStudents - report.submittedCount})'),
              ],
            ),
            
            // Pending students
            if (report.pendingStudentIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Yapmayanlar (${report.pendingStudentIds.length})',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTokens.errorLight,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...report.pendingStudentIds.take(5).map((id) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 16, color: AppTokens.textSecondaryLight),
                                const SizedBox(width: 8),
                                Text(id.substring(0, 10)),
                              ],
                            ),
                          );
                        }),
                        if (report.pendingStudentIds.length > 5)
                          Text(
                            '... ve ${report.pendingStudentIds.length - 5} kişi daha',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTokens.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildScoreDistributionSection(ExamReport report) {
    final distribution = report.scoreDistribution;
    final counts = [
      distribution['0-2'] ?? 0,
      distribution['3-5'] ?? 0,
      distribution['6-8'] ?? 0,
      distribution['9-10'] ?? 0,
    ];
    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Puan Dağılımı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Ortalama: ${report.averageScore.toStringAsFixed(1)}/10',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTokens.primaryLight,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Horizontal bar chart
            Column(
              children: [
                _buildDistributionBar('0-2 (Zayıf)', distribution['0-2'] ?? 0, maxCount, AppTokens.errorLight),
                const SizedBox(height: 12),
                _buildDistributionBar('3-5 (Orta)', distribution['3-5'] ?? 0, maxCount, Colors.orange),
                const SizedBox(height: 12),
                _buildDistributionBar('6-8 (İyi)', distribution['6-8'] ?? 0, maxCount, Colors.blue),
                const SizedBox(height: 12),
                _buildDistributionBar('9-10 (Mükemmel)', distribution['9-10'] ?? 0, maxCount, AppTokens.successLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, int maxCount, Color color) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBreakdownSection(ExamReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Soru Analizi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.questionBreakdown.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final question = report.questionBreakdown[index];
                return _buildQuestionAnalysisItem(question, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalysisItem(QuestionAnalysis question, int number) {
    final total = question.correctCount + question.wrongCount + question.uncertainCount;
    final correctPercent = total > 0 ? ((question.correctCount / total) * 100).toInt() : 0;

    Color statusColor;
    if (correctPercent >= 80) {
      statusColor = AppTokens.successLight;
    } else if (correctPercent >= 60) {
      statusColor = Colors.blue;
    } else {
      statusColor = AppTokens.errorLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru $number',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Başarı: %$correctPercent',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '✓${question.correctCount} ✗${question.wrongCount} ?${question.uncertainCount}',
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.textSecondaryLight,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? question.correctCount / total : 0,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(statusColor),
            minHeight: 8,
          ),
        ),
        
        // Common errors
        if (question.commonErrors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Yaygın Hatalar (${question.commonErrors.length})',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              ...question.commonErrors.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTopicAccuracySection(ExamReport report) {
    final sortedTopics = report.topicAccuracy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Konu Başarısı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedTopics.map((entry) {
                final percent = (entry.value * 100).toInt();
                final color = percent >= 80
                    ? AppTokens.successLight
                    : percent >= 60
                        ? Colors.blue
                        : AppTokens.errorLight;
                
                return Chip(
                  label: Text('${entry.key}: %$percent'),
                  backgroundColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsSection(AIInsights insights) {
    return Card(
      color: Colors.purple.withOpacity(0.05),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insights.summary,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            
            if (insights.keyMisconceptions.isNotEmpty) ...[
              const Text('⚠️ Yaygın Kavram Yanılgıları:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...insights.keyMisconceptions.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],

            if (insights.recommendationsForTeacher.isNotEmpty) ...[
              const Text('💡 Öğretmen İçin Öneriler:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...insights.recommendationsForTeacher.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
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
}

/// Custom painter for donut chart
class _DonutChartPainter extends CustomPainter {
  final int submitted;
  final int pending;

  _DonutChartPainter({
    required this.submitted,
    required this.pending,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = submitted + pending;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.3;

    final submittedAngle = (submitted / total) * 2 * math.pi;

    // Submitted arc
    final submittedPaint = Paint()
      ..color = AppTokens.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      submittedAngle,
      false,
      submittedPaint,
    );

    // Pending arc
    if (pending > 0) {
      final pendingPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2 + submittedAngle,
        (pending / total) * 2 * math.pi,
        false,
        pendingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.submitted != submitted || oldDelegate.pending != pending;
  }
}
