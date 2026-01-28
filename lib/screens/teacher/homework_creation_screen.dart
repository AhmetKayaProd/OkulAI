import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/models/homework.dart';
import 'package:kresai/services/homework_ai_service.dart';
import 'package:kresai/services/homework_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE
// Note: GenerativeAIException is part of homework_ai_service.dart import

/// Homework Creation Screen - Teacher generates homework with AI
class HomeworkCreationScreen extends StatefulWidget {
  const HomeworkCreationScreen({super.key});

  @override
  State<HomeworkCreationScreen> createState() => _HomeworkCreationScreenState();
}

class _HomeworkCreationScreenState extends State<HomeworkCreationScreen> {
  final _topicsController = TextEditingController();
  final _aiService = HomeworkAIService();
  final _homeworkStore = HomeworkStore();
  final _registrationStore = RegistrationStore();
  final String? _currentTeacherId = FirebaseAuth.instance.currentUser?.uid;

  GradeBand _selectedGrade = GradeBand.anaokulu;
  TimeWindow _selectedTime = TimeWindow.gunluk;
  Difficulty _selectedDifficulty = Difficulty.orta;
  int _estimatedMinutes = 15;
  List<HomeworkFormat> _selectedFormats = [
    HomeworkFormat.mcq,
    HomeworkFormat.drawing,
    HomeworkFormat.photoWorksheet,
  ];

  bool _isLoading = false;
  bool _isGenerating = false;
  List<HomeworkOption>? _generatedOptions;
  String? _summaryForTeacher;
  int? _selectedOptionIndex;

  String? _classContext;

  @override
  void initState() {
    super.initState();
    _loadClassContext();
  }

  Future<void> _loadClassContext() async {
    await _registrationStore.load();
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      setState(() {
        _classContext = '${teacherReg.className}, ${teacherReg.classSize} öğrenci';
      });
    }
  }

  Future<void> _generateHomework() async {
    if (_topicsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen konu girin')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedOptions = null;
      _selectedOptionIndex = null;
    });

    try {
      final result = await _aiService.generateHomework(
        gradeBand: _selectedGrade,
        classContext: _classContext ?? 'Sınıf bilgisi yok',
        timeWindow: _selectedTime,
        topics: _topicsController.text.trim(),
        estimatedMinutes: _estimatedMinutes,
        difficulty: _selectedDifficulty,
        formatsAllowed: _selectedFormats,
        teacherStyle: 'Eğlenceli, kısa talimatlar',
      );

      if (mounted) {
        setState(() {
          _generatedOptions = result.options;
          _summaryForTeacher = result.summaryForTeacher;
          _isGenerating = false;
        });
      }
    } on GenerativeAIException catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showErrorDialog('Beklenmeyen bir hata: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üzgünüz 😔'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishHomework() async {
    if (_selectedOptionIndex == null || _generatedOptions == null) {
      return;
    }
    
    // In Test Lab, we might not have a logged in user
    if (_currentTeacherId == null && !TEST_LAB_MODE) {
      return;
    }

    final selectedOption = _generatedOptions![_selectedOptionIndex!];

    // Show confirmation dialog with due date picker
    final dueDate = await _showPublishDialog();
    if (dueDate == null) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Create homework (draft)
      // Extract classId from _classContext (format: "ClassName, N öğrenci")
      final classId = _classContext?.split(',').first.trim() ?? 'default_class';
      
      final teacherId = _currentTeacherId ?? (TEST_LAB_MODE ? 'mock_teacher_id' : null);
      if (teacherId == null) return;

      final homeworkId = await _homeworkStore.createHomework(
        classId: classId,
        teacherId: teacherId,
        selectedOption: selectedOption,
        targetStudentIds: [], // Will be populated by teacher or class assignment logic
      );

      // Step 2: Publish immediately
      await _homeworkStore.publishHomework(
        homeworkId: homeworkId,
        dueDate: dueDate,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ödev yayınlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to management screen
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTokens.errorLight,
          ),
        );
      }
    }
  }

  Future<DateTime?> _showPublishDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    
    return showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödevi Yayınla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Son teslim tarihi:'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) => InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih Seç',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedDate),
            child: const Text('Yayınla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Ödev Oluştur'),
        bottom: _isGenerating
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        children: [
          // Input Form
          _buildInputForm(),
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateHomework,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Üretiliyor...' : 'AI ile Ödev Üret'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Generated Options
          if (_generatedOptions != null) ...[
            Text(
              'Ödev Seçenekleri (${_generatedOptions!.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            
            if (_summaryForTeacher != null)
              Card(
                color: AppTokens.primaryLight.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing12),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _summaryForTeacher!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            ..._generatedOptions!.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return _buildOptionCard(index, option);
            }),
          ],
        ],
      ),
      floatingActionButton: _selectedOptionIndex != null
          ? FloatingActionButton.extended(
              onPressed: _publishHomework,
              icon: const Icon(Icons.send),
              label: const Text('Yayınla'),
              backgroundColor: AppTokens.primaryLight,
            )
          : null,
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade Band
            Text(
              'Düzey',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<GradeBand>(
              segments: GradeBand.values.map((g) {
                return ButtonSegment(
                  value: g,
                  label: Text(g.label),
                );
              }).toList(),
              selected: {_selectedGrade},
              onSelectionChanged: (Set<GradeBand> selection) {
                setState(() => _selectedGrade = selection.first);
              },
            ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            // Topics
            TextField(
              controller: _topicsController,
              decoration: const InputDecoration(
                labelText: 'Konular',
                hintText: 'Örn: Renkler, şekiller, sayılar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            // Time Window
            DropdownButtonFormField<TimeWindow>(
              value: _selectedTime,
              decoration: const InputDecoration(
                labelText: 'Zaman Aralığı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: TimeWindow.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTime = value);
                }
              },
            ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            // Estimated Minutes
            Row(
              children: [
                Text(
                  'Süre: $_estimatedMinutes dk',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_estimatedMinutes > 5) {
                      setState(() => _estimatedMinutes -= 5);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: () {
                    if (_estimatedMinutes < 60) {
                      setState(() => _estimatedMinutes += 5);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            // Difficulty
            Text(
              'Zorluk: ${_selectedDifficulty.label}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: Difficulty.values.indexOf(_selectedDifficulty).toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              label: _selectedDifficulty.label,
              onChanged: (value) {
                setState(() => _selectedDifficulty = Difficulty.values[value.toInt()]);
              },
            ),
            
            const SizedBox(height: AppTokens.spacing16),
            
            // Formats
            Text(
              'Format Seçenekleri',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HomeworkFormat.values.map((format) {
                final isSelected = _selectedFormats.contains(format);
                return FilterChip(
                  label: Text(format.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFormats.add(format);
                      } else {
                        if (_selectedFormats.length > 1) {
                          _selectedFormats.remove(format);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index, HomeworkOption option) {
    final isSelected = _selectedOptionIndex == index;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTokens.primaryLight.withOpacity(0.1) : null,
      margin: const EdgeInsets.only(bottom: AppTokens.spacing16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTokens.primaryLight,
              child: Text('${index + 1}'),
            ),
            title: Text(
              option.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${option.format.label} • ${option.estimatedMinutes} dk'),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppTokens.primaryLight)
                : Icon(Icons.circle_outlined, color: AppTokens.textSecondaryLight),
            onTap: () {
              setState(() {
                _selectedOptionIndex = isSelected ? null : index;
              });
            },
          ),
          
          // Expandable details
          if (isSelected) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hedef',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(option.goal),
                  
                  const SizedBox(height: AppTokens.spacing12),
                  
                  Text(
                    'Malzemeler',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...option.materials.map((m) => Text('• $m')),
                  
                  const SizedBox(height: AppTokens.spacing12),
                  
                  Text(
                    'Öğrenci Talimatları',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...option.studentInstructions.asMap().entries.map((e) {
                    return Text('${e.key + 1}. ${e.value}');
                  }),
                  
                  const SizedBox(height: AppTokens.spacing12),
                  
                  Row(
                    children: [
                      Chip(
                        label: Text('Puan: ${option.gradingRubric.maxScore}'),
                        backgroundColor: AppTokens.successLight.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(option.submissionType.label),
                        backgroundColor: AppTokens.primaryLight.withOpacity(0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _topicsController.dispose();
    super.dispose();
  }
}
