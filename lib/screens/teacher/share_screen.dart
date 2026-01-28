import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher Share Screen
class TeacherShareScreen extends StatefulWidget {
  const TeacherShareScreen({super.key});

  @override
  State<TeacherShareScreen> createState() => _TeacherShareScreenState();
}

class _TeacherShareScreenState extends State<TeacherShareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _feedStore = FeedStore();
  final _registrationStore = RegistrationStore();

  FeedItemType _selectedType = FeedItemType.text;
  bool _isSubmitting = false;
  Uint8List? _selectedImageBytes;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // FeedItem oluştur
    String? mediaUrl;
    if (_selectedImageBytes != null) {
      // Base64 encode
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
      textContent: _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
      mediaUrl: mediaUrl,
    );

    await _feedStore.load();
    final success = await _feedStore.createFeedItem(item);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşım oluşturuldu'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Refresh için true dön
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu paylaşım zaten mevcut'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşım Oluştur'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          children: [
            const Text(
              'Paylaşım Türü',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Metin'),
                  selected: _selectedType == FeedItemType.text,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = FeedItemType.text);
                  },
                ),
                ChoiceChip(
                  label: const Text('Aktivite'),
                  selected: _selectedType == FeedItemType.activity,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = FeedItemType.activity);
                  },
                ),
                ChoiceChip(
                  label: const Text('Fotoğraf'),
                  selected: _selectedType == FeedItemType.photo,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = FeedItemType.photo);
                  },
                ),
                ChoiceChip(
                  label: const Text('Video'),
                  selected: _selectedType == FeedItemType.video,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = FeedItemType.video);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing24),
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Paylaşımınızı yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen bir açıklama girin';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.spacing16),
            if (_selectedType == FeedItemType.photo || _selectedType == FeedItemType.video) ...[
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(_selectedImageBytes == null ? 'Fotoğraf Seç' : 'Fotoğrafı Değiştir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_selectedImageBytes != null) ...[
                const SizedBox(height: AppTokens.spacing12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.spacing12),
              Container(
                padding: const EdgeInsets.all(AppTokens.spacing12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu içerik için fotoğraf izni gerekli. İzni olmayan veliler göremez.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTokens.spacing24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Paylaş'),
            ),
          ],
        ),
      ),
    );
  }
}
