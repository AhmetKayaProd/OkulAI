import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';
import 'package:kresai/services/firebase_monitoring.dart';
import 'package:kresai/services/firestore_retry_helper.dart';

/// Feed Store - Singleton with Firestore + Cache
class FeedStore {
  static final FeedStore _instance = FeedStore._internal();
  factory FeedStore() => _instance;
  FeedStore._internal();

  static const String _feedItemsKey = 'feed_items';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRateLimiter _rateLimiter = FirestoreRateLimiter();
  final FirebaseMonitoring _monitoring = FirebaseMonitoring();

  List<FeedItem> _feedItems = [];
  bool _isLoaded = false;

  List<FeedItem> get feedItems => _feedItems;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      await _loadFromCache();
      await _loadFromFirestore();
      _isLoaded = true;
    } catch (e) {
      print('DEBUG FeedStore.load error: $e');
      _isLoaded = true;
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedItemsJson = prefs.getString(_feedItemsKey);
      if (feedItemsJson != null) {
        final list = jsonDecode(feedItemsJson) as List;
        _feedItems = list
            .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
            .toList();
        print('DEBUG FeedStore: Loaded ${_feedItems.length} from cache');
      }
    } catch (e) {
      print('DEBUG FeedStore._loadFromCache error: $e');
    }
  }

  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .get();

      _feedItems = snapshot.docs
          .map((doc) => FeedItem.fromJson(doc.data()))
          .toList();

      print('DEBUG FeedStore: Loaded ${_feedItems.length} from Firestore');
      await _saveToCache();
    } catch (e) {
      print('DEBUG FeedStore._loadFromFirestore error: $e');
    }
  }

  Future<bool> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_feedItems.map((e) => e.toJson()).toList());
      return await prefs.setString(_feedItemsKey, jsonString);
    } catch (e) {
      print('DEBUG FeedStore._saveToCache error: $e');
      return false;
    }
  }

  Future<bool> createFeedItem(FeedItem item) async {
    try {
      print('DEBUG FeedStore: createFeedItem - type: ${item.type}, classId: ${item.classId}');

      // Duplicate check
      final duplicate = _feedItems.any(
        (f) =>
            f.classId == item.classId &&
            f.createdByTeacherId == item.createdByTeacherId &&
            f.type == item.type &&
            f.textContent == item.textContent &&
            f.mediaUrl == item.mediaUrl,
      );

      if (duplicate) {
        print('DEBUG FeedStore: Duplicate detected');
        return false;
      }

      // Firestore'a yaz
      await _firestore
          .collection('feed')
          .doc(item.id)
          .set(item.toJson());

      print('DEBUG FeedStore: Created feed item ${item.id} in Firestore');

      // Local cache güncelle
      _feedItems.insert(0, item);
      await _saveToCache();

      // Activity log
      final event = ActivityEvent(
        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
        type: ActivityEventType.feedPosted,
        actorRole: ActorRole.teacher,
        actorId: item.createdByTeacherId,
        classId: item.classId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        description: 'Paylaşım: ${item.type.name} (${item.visibility.name})',
      );
      await ActivityLogStore().addEvent(event);

      return true;
    } catch (e) {
      print('DEBUG FeedStore.createFeedItem error: $e');
      return false;
    }
  }

  List<FeedItem> listForTeacher(String classId) {
    final filtered = _feedItems.where((f) => f.classId == classId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<FeedItem> listForParent({
    required String parentId,
    required String classId,
    required bool parentConsentGranted,
  }) {
    final filtered = _feedItems.where((f) {
      if (f.classId != classId) return false;
      if (f.requiresConsent && !parentConsentGranted) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }
}
