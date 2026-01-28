import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';
import 'package:kresai/services/firebase_monitoring.dart';
import 'package:kresai/services/firestore_retry_helper.dart';

/// Notification Store - Singleton with Firestore + Cache
/// Bildirimleri Firestore'da persist eder ve local cache tutar
class NotificationStore {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  static const String _notificationsKey = 'notifications';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRateLimiter _rateLimiter = FirestoreRateLimiter();
  final FirebaseMonitoring _monitoring = FirebaseMonitoring();

  List<NotificationItem> _notifications = [];
  bool _isLoaded = false;

  /// Getters
  List<NotificationItem> get notifications => _notifications;
  bool get isLoaded => _isLoaded;

  /// Tüm verileri yükle (Firestore + Cache)
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      // 1. Cache'den yükle
      await _loadFromCache();

      // 2. Firestore'dan çek
      await _loadFromFirestore();

      _isLoaded = true;
    } catch (e) {
      print('DEBUG NotificationStore.load error: $e');
      _isLoaded = true;
    }
  }

  /// Cache'den yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      if (notificationsJson != null) {
        final list = jsonDecode(notificationsJson) as List;
        _notifications = list
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        print('DEBUG NotificationStore: Loaded ${_notifications.length} from cache');
      }
    } catch (e) {
      print('DEBUG NotificationStore._loadFromCache error: $e');
    }
  }

  /// Firestore'dan yükle
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationItem.fromJson(doc.data()))
          .toList();

      print('DEBUG NotificationStore: Loaded ${_notifications.length} from Firestore');
      _monitoring.recordRead('notifications');

      await _saveToCache();
    } catch (e) {
      print('DEBUG NotificationStore._loadFromFirestore error: $e');
      _monitoring.recordError('loadFromFirestore', e);
    }
  }

  /// Cache'e kaydet
  Future<bool> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      return await prefs.setString(_notificationsKey, notificationsJson);
    } catch (e) {
      print('DEBUG NotificationStore._saveToCache error: $e');
      return false;
    }
  }

  /// Yeni bildirim ekle (Firestore + Cache)
  Future<bool> addNotification(NotificationItem notification) async {
    // Load kontrolü
    if (!_isLoaded) {
      await load();
    }

    try {
      // Duplicate check (ID bazlı)
      final duplicate = _notifications.any((n) => n.id == notification.id);
      if (duplicate) {
        print('DEBUG NotificationStore: Duplicate notification ${notification.id}, skipping');
        return false;
      }

      // 1. Rate limiting kontrolü
      if (!await _rateLimiter.canWrite('notifications')) {
        print('⚠️ Rate limit exceeded for notifications');
        _monitoring.recordError('addNotification', 'Rate limit exceeded');
        return false;
      }

      // 2. Firestore'a yaz (retry logic ile)
      final success = await FirestoreRetryHelper.executeWithRetry<bool>(
        operation: () async {
          await _firestore
              .collection('notifications')
              .doc(notification.id)
              .set(notification.toJson());
          return true;
        },
        operationName: 'addNotification',
      );

      if (success != true) {
        _monitoring.recordError('addNotification', 'Firestore write failed after retries');
        return false;
      }

      print('DEBUG NotificationStore: Created notification ${notification.id} in Firestore');
      _monitoring.recordWrite('notifications');

      // 3. Local cache'i güncelle
      _notifications.insert(0, notification);
      await _saveToCache();

      return true;
    } catch (e) {
      print('DEBUG NotificationStore.addNotification error: $e');
      _monitoring.recordError('addNotification', e);
      return false;
    }
  }

  /// Belirli kullanıcı ve rol için bildirimleri listele
  List<NotificationItem> listForUser({
    required String targetId,
    required String targetRole,
  }) {
    return _notifications
        .where((n) => n.targetId == targetId && n.targetRole == targetRole)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Backward compatibility alias
  List<NotificationItem> listFor({
    required String targetId,
    required String targetRole,
  }) {
    return listForUser(targetId: targetId, targetRole: targetRole);
  }

  /// Okunmamış bildirim sayısı
  int getUnseenCount({
    required String targetId,
    required String targetRole,
  }) {
    return _notifications
        .where((n) =>
            n.targetId == targetId &&
            n.targetRole == targetRole &&
            !n.seen)
        .length;
  }

  /// Backward compatibility alias
  int unreadCount({
    required String targetId,
    required String targetRole,
  }) {
    return getUnseenCount(targetId: targetId, targetRole: targetRole);
  }

  /// Bildirimi okundu olarak işaretle
  Future<bool> markAsSeen(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return false;

      final updated = _notifications[index].copyWith(seen: true);
      _notifications[index] = updated;

      // Rate limiting kontrolü
      if (!await _rateLimiter.canWrite('notifications')) {
        print('⚠️ Rate limit exceeded for notifications');
        _monitoring.recordError('markAsSeen', 'Rate limit exceeded');
        // Cache'i güncelle ama Firestore'a yazma
        await _saveToCache();
        return true; // Local update başarılı
      }

      // Firestore'u güncelle (retry logic ile)
      final success = await FirestoreRetryHelper.executeWithRetry<bool>(
        operation: () async {
          await _firestore
              .collection('notifications')
              .doc(notificationId)
              .update({'seen': true});
          return true;
        },
        operationName: 'markAsSeen',
      );

      if (success == true) {
        _monitoring.recordWrite('notifications');
      } else {
        _monitoring.recordError('markAsSeen', 'Firestore update failed after retries');
      }

      await _saveToCache();
      return true;
    } catch (e) {
      print('DEBUG NotificationStore.markAsSeen error: $e');
      _monitoring.recordError('markAsSeen', e);
      return false;
    }
  }
}
