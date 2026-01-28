import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/announcement_store.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/models/announcement.dart';
import 'package:kresai/screens/teacher/create_announcement_screen.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher placeholder screens
class TeacherTodayScreen extends StatelessWidget {
  const TeacherTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün (Öğretmen)'),
      ),
      body: const Center(
        child: Text('Teacher Bugün Ekranı'),
      ),
    );
  }
}

/// Teacher Feed Screen - Gerçek Feed
class TeacherFeedScreen extends StatefulWidget {
  const TeacherFeedScreen({super.key});

  @override
  State<TeacherFeedScreen> createState() => TeacherFeedScreenState();
}

class TeacherFeedScreenState extends State<TeacherFeedScreen> {
  final _feedStore = FeedStore();
  final _registrationStore = RegistrationStore();
  bool _isLoading = true;
  List<FeedItem> _feedItems = [];

  @override
  void initState() {
    super.initState();
    refreshFeed();
  }

  Future<void> refreshFeed() async {
    print('DEBUG TeacherFeedScreen: refreshFeed called');
    await _feedStore.load();
    await _registrationStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      final items = _feedStore.listForTeacher(teacherReg.className);
      print('DEBUG TeacherFeedScreen: Loaded ${items.length} items for class ${teacherReg.className}');
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    } else {
      print('DEBUG TeacherFeedScreen: No teacher registration found');
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(FeedItemType type) {
    switch (type) {
      case FeedItemType.photo:
        return Icons.photo;
      case FeedItemType.video:
        return Icons.videocam;
      case FeedItemType.activity:
        return Icons.directions_run;
      case FeedItemType.text:
        return Icons.text_snippet;
    }
  }

  String _getTypeLabel(FeedItemType type) {
    switch (type) {
      case FeedItemType.photo:
        return 'Fotoğraf';
      case FeedItemType.video:
        return 'Video';
      case FeedItemType.activity:
        return 'Aktivite';
      case FeedItemType.text:
        return 'Metin';
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Uint8List? _decodeBase64Image(String? mediaUrl) {
    if (mediaUrl == null || !mediaUrl.startsWith('data:image')) return null;
    try {
      final base64String = mediaUrl.split(',').last;
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _feedItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dynamic_feed_outlined,
                      size: 64,
                      color: AppTokens.textSecondaryLight,
                    ),
                    const SizedBox(height: AppTokens.spacing16),
                    Text(
                      'Henüz paylaşım yok',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing8),
                    Text(
                      'Paylaş butonuna basarak ilk paylaşımınızı yapın',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: refreshFeed,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  itemCount: _feedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                  itemBuilder: (context, index) {
                    final item = _feedItems[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                                  child: Icon(
                                    _getIcon(item.type),
                                    color: AppTokens.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getTypeLabel(item.type),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTokens.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.requiresConsent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'İzin Gerekli',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (item.textContent != null) ...[
                              const SizedBox(height: AppTokens.spacing12),
                              Text(
                                item.textContent!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                            if (item.mediaUrl != null) ...[
                              const SizedBox(height: AppTokens.spacing12),
                              Builder(
                                builder: (context) {
                                  final imageBytes = _decodeBase64Image(item.mediaUrl);
                                  if (imageBytes != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        imageBytes,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}

class TeacherHomeworkAIScreen extends StatelessWidget {
  const TeacherHomeworkAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÖdevAI (Öğretmen)'),
      ),
      body: const Center(
        child: Text('Teacher ÖdevAI Ekranı'),
      ),
    );
  }
}

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  final _announcementStore = AnnouncementStore();
  final _registrationStore = RegistrationStore();

  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String _className = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    await _announcementStore.load();
    await _registrationStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      setState(() {
        _className = teacherReg.className;
        _announcements = _announcementStore.listForClass(teacherReg.className);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAnnouncement() async {
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAnnouncementScreen(
          teacherId: teacherReg.id,
          className: teacherReg.className,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadAnnouncements(); // Yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyurular'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(
                  child: Text('Henüz duyuru yok'),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = _announcements[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: announcement.urgent
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık ve acil badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      announcement.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (announcement.urgent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ACİL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // İçerik
                              Text(
                                announcement.content,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),

                              // Tarih
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(announcement.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAnnouncement,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Duyuru'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class TeacherMessagesScreen extends StatelessWidget {
  const TeacherMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar (Öğretmen)'),
      ),
      body: const Center(
        child: Text('Teacher Mesajlar Ekranı'),
      ),
    );
  }
}
