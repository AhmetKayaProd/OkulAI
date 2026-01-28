import 'package:flutter/material.dart';
import 'package:kresai/models/school_settings.dart';
import 'package:kresai/services/settings_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Admin Okul Ayarları Ekranı - Gerçek Implementation
class AdminSchoolSettingsScreen extends StatefulWidget {
  const AdminSchoolSettingsScreen({super.key});

  @override
  State<AdminSchoolSettingsScreen> createState() => _AdminSchoolSettingsScreenState();
}

class _AdminSchoolSettingsScreenState extends State<AdminSchoolSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsStore = SettingsStore();
  
  late TextEditingController _schoolNameController;
  late TextEditingController _sloganController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsStore.load();
    final settings = _settingsStore.settings;
    
    _schoolNameController = TextEditingController(text: settings.schoolName);
    _sloganController = TextEditingController(text: settings.slogan);
    _startTime = settings.startTime;
    _endTime = settings.endTime;
    
    _schoolNameController.addListener(_onChanged);
    _sloganController.addListener(_onChanged);
    
    setState(() {
      _isLoading = false;
    });
  }

  void _onChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTokens.surfaceLight,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTokens.surfaceLight,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newSettings = SchoolSettings(
      schoolName: _schoolNameController.text.trim(),
      slogan: _sloganController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
    );

    final success = await _settingsStore.save(newSettings);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasChanges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi'),
          backgroundColor: AppTokens.primaryLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaydetme hatası'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okul Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Okul Bilgileri Kartı
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Okul Bilgileri',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            
                            // Okul Adı
                            TextFormField(
                              controller: _schoolNameController,
                              decoration: const InputDecoration(
                                labelText: 'Okul Adı *',
                                hintText: 'Örn: Atatürk İlkokulu',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Okul adı gereklidir';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            
                            // Slogan
                            TextFormField(
                              controller: _sloganController,
                              decoration: const InputDecoration(
                                labelText: 'Slogan',
                                hintText: 'Örn: Geleceği parlak çocuklar yetiştiriyoruz',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            
                            // Logo (Placeholder)
                            Container(
                              padding: const EdgeInsets.all(AppTokens.spacing16),
                              decoration: BoxDecoration(
                                color: AppTokens.backgroundLight,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                border: Border.all(
                                  color: AppTokens.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTokens.surfaceLight,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                      border: Border.all(color: AppTokens.borderLight),
                                    ),
                                    child: const Icon(
                                      Icons.school,
                                      size: 32,
                                      color: AppTokens.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.spacing16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Logo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTokens.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Yakında eklenecek',
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTokens.spacing16),
                    
                    // Aktif Saatler Kartı
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Günlük Aktif Saat Aralığı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            
                            Row(
                              children: [
                                // Başlangıç Saati
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectStartTime,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                    child: Container(
                                      padding: const EdgeInsets.all(AppTokens.spacing16),
                                      decoration: BoxDecoration(
                                        color: AppTokens.surfaceLight,
                                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                        border: Border.all(color: AppTokens.borderLight),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Başlangıç',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.textSecondaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 20,
                                                color: AppTokens.primaryLight,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTokens.textPrimaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: AppTokens.spacing16),
                                
                                // Bitiş Saati
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectEndTime,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                    child: Container(
                                      padding: const EdgeInsets.all(AppTokens.spacing16),
                                      decoration: BoxDecoration(
                                        color: AppTokens.surfaceLight,
                                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                        border: Border.all(color: AppTokens.borderLight),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bitiş',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTokens.textSecondaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 20,
                                                color: AppTokens.primaryLight,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTokens.textPrimaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTokens.spacing24),
                    
                    // Kaydet Butonu
                    ElevatedButton(
                      onPressed: (_hasChanges && _schoolNameController.text.trim().isNotEmpty)
                          ? _saveSettings
                          : null,
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
