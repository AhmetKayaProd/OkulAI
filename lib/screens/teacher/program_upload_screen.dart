import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:kresai/services/ai_config_store.dart';
import 'package:kresai/services/ai_schedule_service.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/services/program_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/models/program.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/ai_settings_screen.dart';
import 'package:kresai/screens/teacher/today_plan_screen.dart';

/// Program Upload Screen - Teacher uploads and parses school programs via AI
class ProgramUploadScreen extends StatefulWidget {
  const ProgramUploadScreen({super.key});

  @override
  State<ProgramUploadScreen> createState() => _ProgramUploadScreenState();
}

class _ProgramUploadScreenState extends State<ProgramUploadScreen> {
  final _programTextController = TextEditingController();
  final _aiConfigStore = AiConfigStore();
  final _aiService = AiScheduleService();
  final _programStore = ProgramStore();
  final _registrationStore = RegistrationStore();
  final _activityLogStore = ActivityLogStore();
  final _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isParsing = false;
  bool _isSaving = false;
  PeriodType _selectedPeriod = PeriodType.weekly;
  SchoolType _schoolType = SchoolType.preschool;
  String? _classId;
  List<ProgramBlock> _parsedBlocks = [];
  File? _selectedImage;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _aiConfigStore.load();
    await _programStore.load();
    await _registrationStore.load();
    await _activityLogStore.load();

    final config = AppConfigStore().config;
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();

    if (mounted) {
      setState(() {
        _schoolType = config?.schoolType ?? SchoolType.preschool;
        _classId = teacherReg?.className;
        _isLoading = false;
      });

      // Check if API key is configured
      if (!_aiConfigStore.hasApiKey) {
        _showApiKeyWarning();
      }

      // Load existing template if exists
      if (_classId != null) {
        final template = _programStore.getTemplate(_classId!);
        if (template != null) {
          _programTextController.text = template.rawText;
          _selectedPeriod = template.periodType;
          // Load blocks
          final blocks = _programStore.blocks
              .where((b) => b.templateId == template.id)
              .toList();
          setState(() => _parsedBlocks = blocks);
        }
      }
    }
  }

  void _showApiKeyWarning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API Key Gerekli'),
            content: const Text(
              'AI özelliklerini kullanmak için Gemini API key yapılandırmanız gerekiyor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiSettingsScreen(),
                    ),
                  );
                },
                child: const Text('Ayarlara Git'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final bytes = await File(image.path).readAsBytes();
        final base64 = base64Encode(bytes);

        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBase64 = base64;
          _programTextController.clear(); // Clear text if image selected
        });

        // Auto-parse after selecting image
        await _parseProgramFromImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görüntü seçme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _parseProgramFromImage() async {
    if (_selectedImageBase64 == null) return;
    if (_classId == null) return;

    setState(() => _isParsing = true);

    try {
      final templateId = 'template_${_classId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final blocks = await _aiService.parseProgramFromImage(
        base64Image: _selectedImageBase64!,
        periodType: _selectedPeriod,
        schoolType: _schoolType,
        templateId: templateId,
      );

      if (mounted) {
        setState(() {
          _parsedBlocks = blocks;
          _isParsing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${blocks.length} program bloğu fotoğraftan parse edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isParsing = false);

        final errorMessage = e.toString();
        if (errorMessage.contains('not configured')) {
          _showApiKeyWarning();
        } else if (errorMessage.contains('wait')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.replaceAll('Exception: ', '')),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Görüntü parse hatası: ${errorMessage.replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _parseProgram() async {
    final rawText = _programTextController.text.trim();

    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen program metnini girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sınıf bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isParsing = true);

    try {
      final templateId = 'template_${_classId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final blocks = await _aiService.parseProgram(
        rawText: rawText,
        periodType: _selectedPeriod,
        schoolType: _schoolType,
        templateId: templateId,
      );

      if (mounted) {
        setState(() {
          _parsedBlocks = blocks;
          _isParsing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${blocks.length} program bloğu başarıyla parse edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isParsing = false);

        final errorMessage = e.toString();
        if (errorMessage.contains('not configured')) {
          _showApiKeyWarning();
        } else if (errorMessage.contains('wait')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.replaceAll('Exception: ', '')),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parse hatası: ${errorMessage.replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProgram() async {
    if (_parsedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce programı parse edin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_classId == null) return;

    setState(() => _isSaving = true);

    try {
      final teacherReg = _registrationStore.getCurrentTeacherRegistration();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Create template
      final template = ProgramTemplate(
        id: _parsedBlocks.first.templateId,
        classId: _classId!,
        periodType: _selectedPeriod,
        rawText: _programTextController.text,
        createdByTeacherId: teacherReg?.id ?? 'unknown',
        createdAt: now,
        lastParsedAt: now,
        version: 1,
      );

      // Save template and blocks
      final success = await _programStore.saveTemplate(template);
      if (success) {
        await _programStore.saveParsedBlocks(template.id, _parsedBlocks);
        
        // Log activity
        await _activityLogStore.addEvent(ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          type: ActivityEventType.dailyUpdated,
          description: 'Program yüklendi: ${_selectedPeriod == PeriodType.weekly ? 'Haftalık' : 'Aylık'}',
          actorRole: ActorRole.teacher,
          actorId: teacherReg?.id ?? 'unknown',
          classId: _classId,
        ));
      }

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Başarılı'),
              content: const Text('Program kaydedildi. Şimdi bugünkü planı oluşturabilirsiniz.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Kapat'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TodayPlanScreen(),
                      ),
                    );
                  },
                  child: const Text('Bugünkü Plana Git'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Yükle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Card
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Nasıl Kullanılır?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spacing12),
                          Text(
                            '1. Haftalık veya aylık program metninizi aşağıya yapıştırın\n'
                            '2. Dönem tipini seçin (Haftalık/Aylık)\n'
                            '3. "Parse Et" butonuna tıklayın\n'
                            '4. AI tarafından analiz edilen program bloklarını kontrol edin\n'
                            '5. "Kaydet" butonuna tıklayın',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTokens.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing16),

                  // School Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacing12,
                      vertical: AppTokens.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _schoolType == SchoolType.primaryPrivate
                              ? Icons.school
                              : Icons.child_care,
                          color: AppTokens.primaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _schoolType == SchoolType.primaryPrivate
                              ? 'Özel İlkokul'
                              : 'Kreş/Anaokulu',
                          style: TextStyle(
                            color: AppTokens.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing16),

                  // Input Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Program Metni',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing12),
                          
                          // Image picker buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isParsing || _isSaving
                                      ? null
                                      : () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Fotoğraf Çek'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isParsing || _isSaving
                                      ? null
                                      : () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galeriden Seç'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spacing12),

                          // Image preview
                          if (_selectedImage != null) ...[
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.red,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImage = null;
                                            _selectedImageBase64 = null;
                                            _parsedBlocks = [];
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing12),
                            const Divider(),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('VEYA', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spacing12),
                          ],

                          TextField(
                            controller: _programTextController,
                            decoration: const InputDecoration(
                              hintText: 'Programınızı buraya yapıştırın...\n\nÖrnek:\nPazartesi\n09:00-10:00 Matematik\n10:00-11:00 Türkçe',
                              border: OutlineInputBorder(),
                              filled: true,
                            ),
                            maxLines: 12,
                            enabled: !_isParsing && !_isSaving,
                          ),
                          const SizedBox(height: AppTokens.spacing16),

                          // Period Type Selector
                          const Text(
                            'Dönem Tipi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing8),
                          SegmentedButton<PeriodType>(
                            segments: const [
                              ButtonSegment(
                                value: PeriodType.weekly,
                                label: Text('Haftalık'),
                                icon: Icon(Icons.calendar_view_week),
                              ),
                              ButtonSegment(
                                value: PeriodType.monthly,
                                label: Text('Aylık'),
                                icon: Icon(Icons.calendar_month),
                              ),
                            ],
                            selected: {_selectedPeriod},
                            onSelectionChanged: _isParsing || _isSaving
                                ? null
                                : (Set<PeriodType> newSelection) {
                                    setState(() {
                                      _selectedPeriod = newSelection.first;
                                    });
                                  },
                          ),
                          const SizedBox(height: AppTokens.spacing16),

                          // Parse Button
                          SizedBox(
                            width: double.infinity,
                            height: AppTokens.buttonHeight,
                            child: ElevatedButton.icon(
                              onPressed: _isParsing || _isSaving ? null : _parseProgram,
                              icon: _isParsing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(_isParsing ? 'Parsing...' : 'AI ile Parse Et'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Parsed Blocks Preview
                  if (_parsedBlocks.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spacing16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  '${_parsedBlocks.length} Program Bloğu',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spacing12),
                            ...List.generate(_parsedBlocks.length, (index) {
                              final block = _parsedBlocks[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: AppTokens.backgroundLight,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTokens.primaryLight,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${block.startTime}-${block.endTime}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              block.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (block.dayOfWeek != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _getDayName(block.dayOfWeek!),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      if (block.dateKey != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            block.dateKey!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                      if (block.notes != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            block.notes!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.textSecondaryLight,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: AppTokens.spacing16),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: AppTokens.buttonHeight,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveProgram,
                                icon: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[dayOfWeek - 1];
  }

  @override
  void dispose() {
    _programTextController.dispose();
    super.dispose();
  }
}
