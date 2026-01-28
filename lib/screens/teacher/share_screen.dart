import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/feed_item.dart';
import '../../services/feed_store.dart';
import '../../services/registration_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';

class TeacherShareScreen extends StatefulWidget {
  const TeacherShareScreen({super.key});

  @override
  State<TeacherShareScreen> createState() => _TeacherShareScreenState();
}

class _TeacherShareScreenState extends State<TeacherShareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feedStore = FeedStore();
  final _registrationStore = RegistrationStore();

  FeedItemType _selectedType = FeedItemType.photo;
  bool _isSubmitting = false;
  Uint8List? _selectedImageBytes;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilemedi: $e'),
          backgroundColor: AppTokens.errorLight,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await _registrationStore.load();
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();

    if (teacherReg == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öğretmen kaydı bulunamadı'),
          backgroundColor: AppTokens.errorLight,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    String? mediaUrl;
    if (_selectedImageBytes != null) {
      mediaUrl = 'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
    }

    final item = FeedItem(
      id: '${teacherReg.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      classId: teacherReg.className,
      createdByTeacherId: teacherReg.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      visibility: FeedVisibility.approvedParentsOnly,
      requiresConsent: _selectedType == FeedItemType.photo || _selectedType == FeedItemType.video,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      mediaUrl: mediaUrl,
    );

    await _feedStore.load();
    final success = await _feedStore.createFeedItem(item);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paylaşım oluşturuldu'),
          backgroundColor: AppTokens.successLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bu paylaşım zaten mevcut'),
          backgroundColor: AppTokens.warningLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Yeni Paylaşım'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spacing20),
          children: [
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paylaşım Türü',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
                  ),
                  const SizedBox(height: AppTokens.spacing12),
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildTypeChip(FeedItemType.photo, 'Fotoğraf', Icons.photo_library_rounded),
                      _buildTypeChip(FeedItemType.video, 'Video', Icons.videocam_rounded),
                      _buildTypeChip(FeedItemType.activity, 'Etkinlik', Icons.celebration_rounded),
                      _buildTypeChip(FeedItemType.text, 'Metin', Icons.text_snippet_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacing20),
            if (_selectedType == FeedItemType.photo) ...[
              ModernCard(
                onTap: _pickImage,
                color: _selectedImageBytes != null ? AppTokens.primaryLightSoft : AppTokens.surfaceLight,
                child: _selectedImageBytes != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                            child: Image.memory(_selectedImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTokens.successLight, size: 18),
                              SizedBox(width: 8),
                              Text('Fotoğraf seçildi • Değiştirmek için tıklayın', style: TextStyle(fontSize: 13, color: AppTokens.textSecondaryLight)),
                            ],
                          ),
                        ],
                      )
                    : const Column(
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTokens.primaryLight),
                          SizedBox(height: 12),
                          Text('Fotoğraf Seç', style: TextStyle(fontWeight: FontWeight.w600, color: AppTokens.primaryLight)),
                          Text('Galeriden bir fotoğraf seçin', style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight)),
                        ],
                      ),
              ),
              const SizedBox(height: AppTokens.spacing20),
            ],
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      hintText: 'Örn: Bugünkü Etkinliğimiz',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Başlık gerekli' : null,
                  ),
                  const Divider(),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (İsteğe bağlı)',
                      hintText: 'Paylaşımınız hakkında detay ekleyin...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacing32),
            ModernButton(
              label: 'Paylaş',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(FeedItemType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? AppTokens.primaryLight : AppTokens.textSecondaryLight),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = type);
      },
      backgroundColor: AppTokens.surfaceLight,
      selectedColor: AppTokens.primaryLightSoft,
      side: BorderSide(color: isSelected ? AppTokens.primaryLight : AppTokens.borderLight),
    );
  }
}
