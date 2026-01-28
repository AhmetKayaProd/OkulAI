import 'package:flutter/material.dart';
import 'package:kresai/models/announcement.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/services/announcement_store.dart';
import 'package:kresai/services/notification_store.dart';
import 'package:kresai/services/registration_store.dart';

/// Öğretmen Duyuru Oluşturma Ekranı
class CreateAnnouncementScreen extends StatefulWidget {
  final String teacherId;
  final String className;

  const CreateAnnouncementScreen({
    super.key,
    required this.teacherId,
    required this.className,
  });

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _announcementStore = AnnouncementStore();
  final _notificationStore = NotificationStore();
  final _registrationStore = RegistrationStore();

  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Duyuru oluştur
      final announcement = Announcement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        className: widget.className,
        teacherId: widget.teacherId,
        createdAt: DateTime.now(),
        urgent: _isUrgent,
      );

      final success = await _announcementStore.createAnnouncement(announcement);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Duyuru oluşturulamadı')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Sınıftaki tüm velilere bildirim gönder
      await _registrationStore.load();
      final allParents = _registrationStore.parentRegistrations;
      final classParents =
          allParents.where((p) => p.className == widget.className).toList();

      for (final parent in classParents) {
        final notification = NotificationItem(
          id:
              '${announcement.id}_${parent.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.announcement,
          targetRole: 'parent',
          targetId: parent.id,
          seen: false,
          createdAt: DateTime.now(),
        );
        await _notificationStore.addNotification(notification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Duyuru oluşturuldu ve ${classParents.length} veliye bildirim gönderildi',
            ),
          ),
        );
        Navigator.pop(context, true); // Başarı ile geri dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Duyuru'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sınıf bilgisi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.class_, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Sınıf: ${widget.className}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Başlık
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        hintText: 'Duyuru başlığı',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Başlık gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // İçerik
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'İçerik',
                        hintText: 'Duyuru içeriği',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'İçerik gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Acil duyuru checkbox
                    CheckboxListTile(
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() => _isUrgent = value ?? false);
                      },
                      title: const Text('Acil Duyuru'),
                      subtitle: const Text(
                        'Acil duyurular öne çıkarılır',
                        style: TextStyle(fontSize: 12),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 24),

                    // Paylaş butonu
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Duyuruyu Paylaş'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
