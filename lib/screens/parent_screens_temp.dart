import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent placeholder screens
class ParentTodayScreen extends StatelessWidget {
  const ParentTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BugÃ¼n (Veli)'),
      ),
      body: const Center(
        child: Text('Parent BugÃ¼n EkranÄ±'),
      ),
    );
  }
}

/// Parent Feed Screen - GerÃ§ek Feed (consent filtering ile)
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
      // Parent consent = photoConsent (ClassRosterItem'daki aynÄ± bilgi)
      _parentConsent = parentReg.photoConsent;
      
      // Feed items - class bilgisine gÃ¶re filter (basitÃ§e: tÃ¼m items, consent filter otomatik)
      setState(() {
        _feedItems = _feedStore.listForParent(
          parentId: parentReg.id,
          classId: 'global', // Demo: tÃ¼m feed items (classroom yÃ¶netimi yok)
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
        return 'FotoÄŸraf';
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
      return 'Az Ã¶nce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika Ã¶nce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat Ã¶nce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gÃ¼n Ã¶nce';
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
                      'HenÃ¼z paylaÅŸÄ±m yok',
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
                                  'Bu iÃ§erik iÃ§in fotoÄŸraf izni gerekli',
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
