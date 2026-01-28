import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/live_session.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';
import 'package:kresai/services/firebase_monitoring.dart';
import 'package:kresai/services/firestore_retry_helper.dart';

/// Live Store - Singleton
/// Canlı oturum yönetimi ve persist
class LiveStore {
  static final LiveStore _instance = LiveStore._internal();
  factory LiveStore() => _instance;
  LiveStore._internal();

  static const String _sessionsKey = 'live_sessions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRateLimiter _rateLimiter = FirestoreRateLimiter();
  final FirebaseMonitoring _monitoring = FirebaseMonitoring();

  List<LiveSession> _sessions = [];
  bool _isLoaded = false;

  /// Getters
  List<LiveSession> get sessions => _sessions;
  bool get isLoaded => _isLoaded;

  /// Tüm verileri yükle
  Future<void> load() async {
    await _loadFromCache();
    await _loadFromFirestore();
    _isLoaded = true;
  }

  /// Cache'den yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson != null) {
        final list = jsonDecode(sessionsJson) as List;
        _sessions = list
            .map((e) => LiveSession.fromJson(e as Map<String, dynamic>))
            .toList();
        print('DEBUG LiveStore: Loaded ${_sessions.length} from cache');
      }
    } catch (e) {
      print('DEBUG LiveStore: Cache load error: $e');
    }
  }

  /// Firestore'dan yükle
  Future<void> _loadFromFirestore() async {
    try {
      final snapshot = await _firestore
          .collection('live')
          .orderBy('startedAt', descending: true)
          .get();

      _sessions = snapshot.docs
          .map((doc) => LiveSession.fromJson(doc.data()))
          .toList();

      print('DEBUG LiveStore: Loaded ${_sessions.length} from Firestore');
      await _saveToCache();
    } catch (e) {
      print('DEBUG LiveStore: Firestore load error: $e');
    }
  }

  /// Cache'e kaydet
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _sessions.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_sessionsKey, jsonString);
    } catch (e) {
      print('DEBUG LiveStore: Cache save error: $e');
    }
  }

  /// Session başlat
  /// GUARD: Aynı classId için active session varsa mevcut session'ı döndür (NO-OP)
  Future<LiveSession?> startSession({
    required String classId,
    required String teacherId,
    String? title,
    bool requiresConsent = true,
  }) async {
    try {
      // Active session var mı?
      final existingActive = getActiveSession(classId);
      if (existingActive != null) {
        return existingActive; // Zaten var, NO-OP
      }

      // Yeni session oluştur
      final session = LiveSession(
        id: '${classId}_${DateTime.now().millisecondsSinceEpoch}',
        classId: classId,
        startedByTeacherId: teacherId,
        startedAt: DateTime.now().millisecondsSinceEpoch,
        endedAt: null,
        status: LiveSessionStatus.live,
        title: title ?? 'Canlı Yayın',
        requiresConsent: requiresConsent,
      );

      // Firestore'a yaz
      await _firestore
          .collection('live')
          .doc(session.id)
          .set(session.toJson());
      print('DEBUG LiveStore: Created session ${session.id} in Firestore');

      _sessions.add(session);
      await _saveToCache();
      final success = true;
      
      if (success) {
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.liveStarted,
          actorRole: ActorRole.teacher,
          actorId: teacherId,
          classId: classId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Canlı başlatıldı: ${session.title}',
        );
        await ActivityLogStore().addEvent(event);
      }

      return session;
    } catch (e) {
      return null;
    }
  }

  /// Session bitir
  Future<bool> endSession(String sessionId) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index == -1) return false;

      final session = _sessions[index];
      if (session.status == LiveSessionStatus.ended) {
        return true; // Zaten bitmiş
      }

      final updatedSession = session.copyWith(
        status: LiveSessionStatus.ended,
        endedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Firestore'u güncelle
      await _firestore
          .collection('live')
          .doc(sessionId)
          .update(updatedSession.toJson());
      print('DEBUG LiveStore: Ended session $sessionId in Firestore');

      _sessions[index] = updatedSession;
      await _saveToCache();
      final success = true;
      
      if (success) {
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.liveEnded,
          actorRole: ActorRole.teacher,
          actorId: session.startedByTeacherId,
          classId: session.classId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Canlı bitirildi',
        );
        await ActivityLogStore().addEvent(event);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Active session getir (classId için)
  LiveSession? getActiveSession(String classId) {
    try {
      return _sessions.firstWhere(
        (s) => s.classId == classId && s.status == LiveSessionStatus.live,
      );
    } catch (e) {
      return null;
    }
  }

  /// Session geçmişi (classId için, en yeni üstte, limit)
  List<LiveSession> listHistory(String classId, {int limit = 20}) {
    final filtered = _sessions.where((s) => s.classId == classId).toList();
    filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt)); // En yeni üstte
    return filtered.take(limit).toList();
  }


}
