import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/announcement.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';
import 'package:kresai/services/firebase_monitoring.dart';
import 'package:kresai/services/firestore_retry_helper.dart';

/// Announcement Store - Singleton with Firestore + Cache
/// Duyuruları Firestore'da persist eder ve local cache tutar
class AnnouncementStore {
  static final AnnouncementStore _instance = AnnouncementStore._internal();
  factory AnnouncementStore() => _instance;
  AnnouncementStore._internal();

  static const String _announcementsKey = 'announcements';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRateLimiter _rateLimiter = FirestoreRateLimiter();
  final FirebaseMonitoring _monitoring = FirebaseMonitoring();

  List<Announcement> _announcements = [];
  bool _isLoaded = false;

  /// Getters
  List<Announcement> get announcements => _announcements;
  bool get isLoaded => _isLoaded;

  /// Tüm verileri yükle (Firestore + Cache)
  Future<void> load() async {
    try {
      // 1. Cache'den yükle (hızlı başlangıç)
      await _loadFromCache();

      // 2. Firestore'dan çek (güncel veri)
      await _loadFromFirestore();

      _isLoaded = true;
    } catch (e) {
      print('DEBUG AnnouncementStore.load error: $e');
      _isLoaded = true;
    }
  }

  /// Cache'den yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final announcementsJson = prefs.getString(_announcementsKey);
      if (announcementsJson != null) {
        final list = jsonDecode(announcementsJson) as List;
        _announcements = list
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList();
        print('DEBUG AnnouncementStore: Loaded ${_announcements.length} from cache');
      }
    } catch (e) {
      print('DEBUG AnnouncementStore._loadFromCache error: $e');
    }
  }

  /// Firestore'dan yükle
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      _announcements = snapshot.docs
          .map((doc) => Announcement.fromJson(doc.data()))
          .toList();

      print('DEBUG AnnouncementStore: Loaded ${_announcements.length} from Firestore');
      _monitoring.recordRead('announcements');

      // Cache'i güncelle
      await _saveToCache();
    } catch (e) {
      print('DEBUG AnnouncementStore._loadFromFirestore error: $e');
      _monitoring.recordError('loadFromFirestore', e);
      // Firestore hatası varsa cache'deki veriyi kullan
    }
  }

  /// Cache'e kaydet
  Future<bool> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final announcementsJson =
          jsonEncode(_announcements.map((a) => a.toJson()).toList());
      return await prefs.setString(_announcementsKey, announcementsJson);
    } catch (e) {
      print('DEBUG AnnouncementStore._saveToCache error: $e');
      return false;
    }
  }

  /// Yeni duyuru oluştur (Firestore + Cache)
  Future<bool> createAnnouncement(Announcement announcement) async {
    try {
      // 1. Rate limiting kontrolü
      if (!await _rateLimiter.canWrite('announcements')) {
        print('⚠️ Rate limit exceeded for announcements');
        _monitoring.recordError('createAnnouncement', 'Rate limit exceeded');
        return false;
      }

      // 2. Firestore'a yaz (retry logic ile)
      final success = await FirestoreRetryHelper.executeWithRetry<bool>(
        operation: () async {
          await _firestore
              .collection('announcements')
              .doc(announcement.id)
              .set(announcement.toJson());
          return true;
        },
        operationName: 'createAnnouncement',
      );

      if (success != true) {
        _monitoring.recordError('createAnnouncement', 'Firestore write failed after retries');
        return false;
      }

      print('DEBUG AnnouncementStore: Created announcement ${announcement.id} in Firestore');
      _monitoring.recordWrite('announcements');

      // 3. Local cache'i güncelle
      _announcements.insert(0, announcement);
      await _saveToCache();

      return true;
    } catch (e) {
      print('DEBUG AnnouncementStore.createAnnouncement error: $e');
      _monitoring.recordError('createAnnouncement', e);
      return false;
    }
  }

  /// Sınıfa özel duyuruları listele
  List<Announcement> listForClass(String className) {
    return _announcements
        .where((a) => a.className == className)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Tüm duyuruları listele
  List<Announcement> listAll() {
    return List.from(_announcements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// ID ile duyuru getir
  Announcement? getById(String id) {
    try {
      return _announcements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
