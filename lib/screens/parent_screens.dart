import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/announcement_store.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/models/announcement.dart';
import 'package:kresai/screens/parent/announcement_detail_screen.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent placeholder screens
class ParentTodayScreen extends StatelessWidget {
  const ParentTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bugün (Veli)'),
      ),
      body: const Center(
        child: Text('Parent Bugün Ekranı'),
      ),
    );
  }
}

/// Parent Feed Screen - Gerçek Feed (consent filtering ile)
class ParentFeedScreen extends StatefulWidget {
  const ParentFeedScreen({super.key});

  @override
  State<ParentFeedScreen> createState() => _ParentFeedScreenState();
}

class _ParentFeedScreenState extends State<ParentFeedScreen> {
  final _feedStore = FeedStore();
  final _registrationStore = RegistrationStore();
  bool _isLoading = true;
  List<FeedItem> _feedItems = [];
  bool _parentConsent = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    await _feedStore.load();
    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      // Parent consent = photoConsent (ClassRosterItem'daki aynı bilgi)
      _parentConsent = parentReg.photoConsent;
      
      // Feed items - className bilgisine göre filter
      setState(() {
        _feedItems = _feedStore.listForParent(
          parentId: parentReg.id,
          classId: parentReg.className, // Veli'nin kayıtlı olduğu sınıf
          parentConsentGranted: _parentConsent,
        );
        _isLoading = false;
      });
    } else {
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
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadFeed,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  itemCount: _feedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                  itemBuilder: (context, index) {
                    final item = _feedItems[index];
                    
                    // Consent check: requiresConsent=true ve parent consent=false ise placeholder
                    if (item.requiresConsent && !_parentConsent) {
                      return Card(
                        color: Colors.grey.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.spacing16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: AppTokens.textSecondaryLight,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Bu içerik için fotoğraf izni gerekli',
                                  style: TextStyle(
                                    color: AppTokens.textSecondaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Normal rendering
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
                              ],
                            ),
                            if (item.textContent != null) ...[
                              const SizedBox(height: AppTokens.spacing12),
                              Text(
                                item.textContent!,
                                style: const TextStyle(fontSize: 14),
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

class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar (Veli)'),
      ),
      body: const Center(
        child: Text('Parent Mesajlar Ekranı'),
      ),
    );
  }
}

class ParentHomeworkScreen extends StatelessWidget {
  const ParentHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödevler (Veli)'),
      ),
      body: const Center(
        child: Text('Parent Ödevler Ekranı'),
      ),
    );
  }
}

class ParentAnnouncementsScreen extends StatefulWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  State<ParentAnnouncementsScreen> createState() =>
      _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState extends State<ParentAnnouncementsScreen> {
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

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      setState(() {
        _className = parentReg.className;
        _announcements = _announcementStore.listForClass(parentReg.className);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _openDetail(Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcementId: announcement.id,
        ),
      ),
    );
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
                        child: InkWell(
                          onTap: () => _openDetail(announcement),
                          borderRadius: BorderRadius.circular(12),
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
                                          borderRadius:
                                              BorderRadius.circular(4),
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

                                // İçerik önizleme
                                Text(
                                  announcement.content.length > 100
                                      ? '${announcement.content.substring(0, 100)}...'
                                      : announcement.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),

                                // Tarih ve detay butonu
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
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
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
