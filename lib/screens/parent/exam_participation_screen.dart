import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kresai/models/exam.dart';
import 'package:kresai/models/exam_submission.dart';
import 'package:kresai/services/exam_submission_store.dart';
import 'package:kresai/services/exam_ai_service.dart';
import 'package:kresai/theme/tokens.dart';

/// Exam Participation Screen - Interactive exam taking experience
class ExamParticipationScreen extends StatefulWidget {
  final Exam exam;
  final String studentId;
  final String parentId;

  const ExamParticipationScreen({
    super.key,
    required this.exam,
    required this.studentId,
    required this.parentId,
  });

  @override
  State<ExamParticipationScreen> createState() => _ExamParticipationScreenState();
}

class _ExamParticipationScreenState extends State<ExamParticipationScreen> {
  final _submissionStore = ExamSubmissionStore();
  final _aiService = ExamAIService();

  // Exam state
  bool _hasStarted = false;
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  String? _submissionId;
  
  // Timer
  late DateTime _startTime;
  Timer? _autoSaveTimer;
  Timer? _elapsedTimer;
  int _elapsedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingSubmission() async {
    final existing = await _submissionStore.getStudentSubmission(
      examId: widget.exam.id,
      studentId: widget.studentId,
    );

    if (existing != null && mounted) {
      setState(() {
        _submissionId = existing.id;
        _answers = Map.from(existing.answers);
        _elapsedMinutes = existing.elapsedMinutes;
        
        if (existing.status == SubmissionStatus.inProgress) {
          _hasStarted = true;
          _startTime = existing.startedAt;
          _startElapsedTimer();
        }
      });
    }
  }

  Future<void> _startExam() async {
    setState(() {
      _hasStarted = true;
      _startTime = DateTime.now();
    });

    // Create initial submission
    final submission = ExamSubmission(
      id: '',
      examId: widget.exam.id,
      studentId: widget.studentId,
      parentId: widget.parentId,
      classId: widget.exam.classId,
      answers: {},
      status: SubmissionStatus.inProgress,
      startedAt: _startTime,
    );

    _submissionId = await _submissionStore.saveSubmission(submission);
    
    // Start auto-save timer (every 10 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _autoSave();
    });

    // Start elapsed time tracker
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedMinutes = DateTime.now().difference(_startTime).inMinutes;
        });
      }
    });
  }

  Future<void> _autoSave() async {
    if (_submissionId == null) return;

    try {
      await _submissionStore.updateAnswers(
        submissionId: _submissionId!,
        answers: _answers,
        elapsedMinutes: DateTime.now().difference(_startTime).inMinutes,
      );
    } catch (e) {
      // Silent fail for auto-save
      debugPrint('Auto-save failed: $e');
    }
  }

  void _answerQuestion(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
    _autoSave(); // Save immediately on answer
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.exam.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitExam() async {
    // Check if all questions answered
    final unansweredCount = widget.exam.questions
        .where((q) => !_answers.containsKey(q.qid) || _answers[q.qid] == null || _answers[q.qid] == '')
        .length;

    if (unansweredCount > 0) {
      final shouldContinue = await _showConfirmDialog(
        'Eksik Cevaplar',
        '$unansweredCount soru cevaplanmadı. Yine de göndermek istiyor musunuz?',
      );
      if (!shouldContinue) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit for grading
      await _submissionStore.submitForGrading(_submissionId!);

      // Trigger AI grading
      final submission = await _submissionStore.getSubmission(_submissionId!);
      if (submission != null) {
        final grade = await _aiService.gradeSubmission(
          exam: widget.exam,
          submission: submission,
        );

        await _submissionStore.updateGrade(
          submissionId: _submissionId!,
          grade: grade,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sınav gönderildi ve puanlandı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTokens.errorLight,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildStartScreen();
    }

    if (_isSubmitting) {
      return _buildSubmittingScreen();
    }

    return _buildExamScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz,
                size: 80,
                color: AppTokens.primaryLight,
              ),
              const SizedBox(height: AppTokens.spacing24),
              Text(
                widget.exam.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yönergeler',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTokens.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.exam.instructions.map((instruction) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(instruction)),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoChip(
                            Icons.quiz,
                            '${widget.exam.questions.length} Soru',
                          ),
                          _buildInfoChip(
                            Icons.schedule,
                            '~${widget.exam.estimatedMinutes} dk',
                          ),
                          _buildInfoChip(
                            Icons.star,
                            '${widget.exam.maxScore} Puan',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startExam,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Sınavı Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderiliyor...'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Sınav puanlanıyor...'),
            SizedBox(height: 8),
            Text(
              'Lütfen bekleyin',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamScreen() {
    final currentQuestion = widget.exam.questions[_currentQuestionIndex];
    final totalQuestions = widget.exam.questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentQuestionIndex + 1}/$totalQuestions'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppTokens.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '$_elapsedMinutes dk',
                  style: TextStyle(color: AppTokens.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(AppTokens.primaryLight),
            minHeight: 6,
          ),
          
          // Question content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              children: [
                _buildQuestionCard(currentQuestion),
                const SizedBox(height: AppTokens.spacing24),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ExamQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Chip(
                  label: Text(question.type.label),
                  backgroundColor: AppTokens.primaryLight.withOpacity(0.2),
                ),
                const Spacer(),
                Text(
                  '${question.points} puan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTokens.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing16),
            
            // Question prompt
            Text(
              question.prompt,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTokens.spacing16),
            
            // Media (if any)
            if (question.imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: AppTokens.textSecondaryLight,
                ),
              ),
            
            if (question.imageUrl != null)
              const SizedBox(height: AppTokens.spacing16),
            
            // Answer input (type-specific)
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(ExamQuestion question) {
    final currentAnswer = _answers[question.qid];

    switch (question.type) {
      case QuestionType.mcq:
        return _buildMCQInput(question, currentAnswer);
      case QuestionType.trueFalse:
        return _buildTrueFalseInput(question, currentAnswer);
      case QuestionType.fillBlank:
        return _buildFillBlankInput(question, currentAnswer);
      case QuestionType.shortText:
        return _buildShortTextInput(question, currentAnswer);
      case QuestionType.pictureChoice:
        return _buildPictureChoiceInput(question, currentAnswer);
      default:
        return Text('Soru tipi: ${question.type.label}');
    }
  }

  Widget _buildMCQInput(ExamQuestion question, dynamic currentAnswer) {
    return Column(
      children: (question.choices ?? []).map((choice) {
        return RadioListTile<String>(
          title: Text(choice),
          value: choice,
          groupValue: currentAnswer,
          onChanged: (value) {
            if (value != null) {
              _answerQuestion(question.qid, value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseInput(ExamQuestion question, dynamic currentAnswer) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _answerQuestion(question.qid, 'Doğru'),
            icon: Icon(
              currentAnswer == 'Doğru' ? Icons.check_circle : Icons.circle_outlined,
            ),
            label: const Text('Doğru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentAnswer == 'Doğru'
                  ? AppTokens.successLight
                  : Colors.grey.withOpacity(0.2),
              foregroundColor: currentAnswer == 'Doğru'
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _answerQuestion(question.qid, 'Yanlış'),
            icon: Icon(
              currentAnswer == 'Yanlış' ? Icons.cancel : Icons.circle_outlined,
            ),
            label: const Text('Yanlış'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentAnswer == 'Yanlış'
                  ? AppTokens.errorLight
                  : Colors.grey.withOpacity(0.2),
              foregroundColor: currentAnswer == 'Yanlış'
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFillBlankInput(ExamQuestion question, dynamic currentAnswer) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Cevabınızı yazın',
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: currentAnswer ?? ''),
      onChanged: (value) => _answerQuestion(question.qid, value),
    );
  }

  Widget _buildShortTextInput(ExamQuestion question, dynamic currentAnswer) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Cevabınızı yazın',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      controller: TextEditingController(text: currentAnswer ?? ''),
      onChanged: (value) => _answerQuestion(question.qid, value),
    );
  }

  Widget _buildPictureChoiceInput(ExamQuestion question, dynamic currentAnswer) {
    // Simplified picture choice (would need actual images)
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: (question.choices ?? []).map((choice) {
        final isSelected = currentAnswer == choice;
        return GestureDetector(
          onTap: () => _answerQuestion(question.qid, choice),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTokens.primaryLight : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: AppTokens.textSecondaryLight),
                const SizedBox(height: 4),
                Text(choice, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastQuestion = _currentQuestionIndex == widget.exam.questions.length - 1;
    final answeredCount = _answers.length;

    return Column(
      children: [
        // Progress indicator
        Text(
          'Cevaplanan: $answeredCount/${widget.exam.questions.length}',
          style: TextStyle(
            fontSize: 14,
            color: AppTokens.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        
        // Navigation buttons
        Row(
          children: [
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousQuestion,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Önceki'),
                ),
              ),
            if (_currentQuestionIndex > 0)
              const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLastQuestion ? _submitExam : _nextQuestion,
                icon: Icon(isLastQuestion ? Icons.send : Icons.arrow_forward),
                label: Text(isLastQuestion ? 'Gönder' : 'İleri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastQuestion
                      ? AppTokens.successLight
                      : AppTokens.primaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTokens.primaryLight),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
