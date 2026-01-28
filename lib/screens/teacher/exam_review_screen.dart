import 'package:flutter/material.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/services/exam_store.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Exam Review Screen - Teacher reviews student submissions
class ExamReviewScreen extends StatefulWidget {
  final String examId;

  const ExamReviewScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  final _examStore = ExamStore();
  final _submissionStore = ExamSubmissionStore();

  String _filterStatus = 'all'; // all, flagged, graded, pending

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teslimler'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterStatus,
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tümü')),
              const PopupMenuItem(value: 'flagged', child: Text('Bayraklı')),
              const PopupMenuItem(value: 'graded', child: Text('Notlandı')),
              const PopupMenuItem(value: 'pending', child: Text('İncelenmeli')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Exam?>(
        future: _examStore.getExam(widget.examId),
        builder: (context, examSnapshot) {
          if (!examSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final exam = examSnapshot.data!;

          return Column(
            children: [
              // Header stats
              _buildHeader(exam),
              
              // Submissions list
              Expanded(
                child: StreamBuilder<List<ExamSubmission>>(
                  stream: _submissionStore.watchExamSubmissions(widget.examId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    var submissions = snapshot.data ?? [];

                    // Filter submissions
                    if (_filterStatus != 'all') {
                      submissions = submissions.where((s) {
                        switch (_filterStatus) {
                          case 'flagged':
                            return s.needsTeacherReview;
                          case 'graded':
                            return s.status == SubmissionStatus.graded;
                          case 'pending':
                            return s.status == SubmissionStatus.submitted;
                          default:
                            return true;
                        }
                      }).toList();
                    }

                    if (submissions.isEmpty) {
                      return _buildEmptyState(_filterStatus);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      itemCount: submissions.length,
                      itemBuilder: (context, index) {
                        return _buildSubmissionCard(submissions[index], exam);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Exam exam) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: AppTokens.primaryLight.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              _buildHeaderStat(Icons.quiz, '${exam.questions.length} Soru'),
              const SizedBox(width: 16),
              _buildHeaderStat(Icons.star, '${exam.maxScore} Puan'),
              const SizedBox(width: 16),
              StreamBuilder<List<ExamSubmission>>(
                stream: _submissionStore.watchExamSubmissions(widget.examId),
                builder: (context, snapshot) {
                  final submissions = snapshot.data ?? [];
                  final flaggedCount = submissions.where((s) => s.needsTeacherReview).length;
                  return _buildHeaderStat(
                    Icons.flag,
                    '$flaggedCount Bayraklı',
                    color: flaggedCount > 0 ? AppTokens.errorLight : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppTokens.textSecondaryLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color ?? AppTokens.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String filterStatus) {
    String message;
    switch (filterStatus) {
      case 'flagged':
        message = 'Bayraklı tesim yok';
        break;
      case 'graded':
        message = 'Notlandırılmış teslim yok';
        break;
      case 'pending':
        message = 'İncelenmesi gereken teslim yok';
        break;
      default:
        message = 'Henüz teslim yok';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: AppTokens.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: AppTokens.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(ExamSubmission submission, Exam exam) {
    final grade = submission.grade;
    final aiScore = grade?.score ?? 0;
    final aiConfidence = grade?.confidence ?? 0.0;
    final finalScore = grade?.teacherScore ?? aiScore;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: submission.needsTeacherReview
                ? AppTokens.errorLight
                : AppTokens.primaryLight,
            child: Text(
              '${submission.studentId.substring(0, 2).toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            'Öğrenci ${submission.studentId.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  // Status badge
                  Chip(
                    label: Text(submission.status.label),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: submission.status == SubmissionStatus.graded
                        ? AppTokens.successLight.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                  ),
                  
                  if (submission.needsTeacherReview) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('İncelemeli'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTokens.errorLight.withOpacity(0.2),
                      avatar: Icon(Icons.flag, size: 16, color: AppTokens.errorLight),
                    ),
                  ],
                ],
              ),
              
              if (grade != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'AI Puanı: $aiScore/${grade.maxScore}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Güven: ${(aiConfidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: aiConfidence < 0.6 ? AppTokens.errorLight : Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Confidence meter
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: aiConfidence,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                    aiConfidence < 0.6 ? AppTokens.errorLight : Colors.green,
                  ),
                  minHeight: 4,
                ),
              ],
            ],
          ),
          trailing: grade?.isTeacherOverride == true
              ? const Icon(Icons.verified, color: Colors.blue)
              : null,
          children: [
            _buildSubmissionDetails(submission, exam),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionDetails(ExamSubmission submission, Exam exam) {
    final grade = submission.grade;
    if (grade == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Henüz puanlanmadı'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flags
          if (grade.flags.isNotEmpty) ...[
            Text(
              'Bayraklar',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTokens.errorLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grade.flags.map((flag) {
                return Chip(
                  label: Text(_flagLabel(flag)),
                  backgroundColor: AppTokens.errorLight.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Per-question breakdown
          Text(
            'Soru Detayları',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          
          DataTable(
            columnSpacing: 12,
            horizontalMargin: 0,
            headingRowHeight: 32,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 48,
            columns: const [
              DataColumn(label: Text('Soru', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Durum', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Puan', style: TextStyle(fontSize: 12))),
            ],
            rows: grade.perQuestion.map((q) {
              return DataRow(
                cells: [
                  DataCell(Text(q.qid, style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Icon(
                      q.status == GradeStatus.correct
                          ? Icons.check_circle
                          : q.status == GradeStatus.wrong
                              ? Icons.cancel
                              : Icons.help,
                      size: 16,
                      color: q.status == GradeStatus.correct
                          ? Colors.green
                          : q.status == GradeStatus.wrong
                              ? AppTokens.errorLight
                              : Colors.orange,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${q.earned}/${q.max}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Teacher override section
          _buildTeacherOverrideSection(submission),
        ],
      ),
    );
  }

  Widget _buildTeacherOverrideSection(ExamSubmission submission) {
    final grade = submission.grade;
    if (grade == null) return const SizedBox();

    if (grade.isTeacherOverride) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Öğretmen Puanı: ${grade.teacherScore}/${grade.maxScore}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (grade.teacherFeedback != null) ...[
              const SizedBox(height: 8),
              Text(
                grade.teacherFeedback!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    // Override form
    return _TeacherOverrideForm(
      submission: submission,
      onSave: (score, feedback) async {
        await _submissionStore.overrideGrade(
          submissionId: submission.id,
          teacherScore: score,
          teacherFeedback: feedback,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puan güncellendi')),
          );
        }
      },
    );
  }

  String _flagLabel(String flag) {
    switch (flag) {
      case 'lowConfidence':
        return 'Düşük Güven';
      case 'suspectedHelp':
        return 'Şüpheli Yardım';
      case 'unreadablePhoto':
        return 'Okunamaz Fotoğraf';
      case 'incompleteAnswers':
        return 'Eksik Cevaplar';
      default:
        return flag;
    }
  }
}

/// Teacher override form widget
class _TeacherOverrideForm extends StatefulWidget {
  final ExamSubmission submission;
  final Future<void> Function(int score, String? feedback) onSave;

  const _TeacherOverrideForm({
    required this.submission,
    required this.onSave,
  });

  @override
  State<_TeacherOverrideForm> createState() => _TeacherOverrideFormState();
}

class _TeacherOverrideFormState extends State<_TeacherOverrideForm> {
  late int _score;
  final _feedbackController = TextEditingController();
  bool _isExpanded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _score = widget.submission.grade?.score ?? 0;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return TextButton.icon(
        onPressed: () => setState(() => _isExpanded = true),
        icon: const Icon(Icons.edit),
        label: const Text('Manuel Puan Ver'),
      );
    }

    final maxScore = widget.submission.grade?.maxScore ?? 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manuel Puanlama',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text('Puan: '),
              Expanded(
                child: Slider(
                  value: _score.toDouble(),
                  min: 0,
                  max: maxScore.toDouble(),
                  divisions: maxScore,
                  label: '$_score',
                  onChanged: (value) {
                    setState(() => _score = value.toInt());
                  },
                ),
              ),
              Text(
                '$_score/$maxScore',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              labelText: 'Geri Bildirim (İsteğe bağlı)',
              border: OutlineInputBorder(),
              hintText: 'Öğrenciye notunuz...',
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isExpanded = false),
                child: const Text('İptal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.primaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _score,
        _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
