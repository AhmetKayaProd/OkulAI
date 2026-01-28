import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kresai/models/daily_log.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/services/firestore_rate_limiter.dart';
import 'package:kresai/services/firebase_monitoring.dart';
import 'package:kresai/services/firestore_retry_helper.dart';

/// Daily Log Store - Singleton
/// Günlük durum loglarını persist eder ve yönetir
class DailyLogStore {
  static final DailyLogStore _instance = DailyLogStore._internal();
  factory DailyLogStore() => _instance;
  DailyLogStore._internal();

  static const String _logsKey = 'daily_logs';
  static const String _childrenKey = 'children';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRateLimiter _rateLimiter = FirestoreRateLimiter();
  final FirebaseMonitoring _monitoring = FirebaseMonitoring();

  List<DailyLogItem> _logs = [];
  List<Child> _children = [];
  bool _isLoaded = false;

  /// Getters
  List<DailyLogItem> get logs => _logs;
  List<Child> get children => _children;
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

      // Logs
      final logsJson = prefs.getString(_logsKey);
      if (logsJson != null) {
        final list = jsonDecode(logsJson) as List;
        _logs = list
            .map((e) => DailyLogItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Children
      final childrenJson = prefs.getString(_childrenKey);
      if (childrenJson != null) {
        final list = jsonDecode(childrenJson) as List;
        _children = list
            .map((e) => Child.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      print('DEBUG DailyLogStore: Loaded ${_logs.length} logs, ${_children.length} children from cache');
    } catch (e) {
      print('DEBUG DailyLogStore: Cache load error: $e');
    }
  }

  /// Firestore'dan yükle
  Future<void> _loadFromFirestore() async {
    try {
      // Logs
      final logsSnapshot = await _firestore
          .collection('dailyLogs')
          .orderBy('createdAt', descending: true)
          .get();

      _logs = logsSnapshot.docs
          .map((doc) => DailyLogItem.fromJson(doc.data()))
          .toList();

      // Children
      final childrenSnapshot = await _firestore
          .collection('children')
          .get();

      _children = childrenSnapshot.docs
          .map((doc) => Child.fromJson(doc.data()))
          .toList();

      print('DEBUG DailyLogStore: Loaded ${_logs.length} logs, ${_children.length} children from Firestore');
      await _saveToCache();
    } catch (e) {
      print('DEBUG DailyLogStore: Firestore load error: $e');
    }
  }

  /// Cache'e kaydet
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Logs
      final logsJson = jsonEncode(
        _logs.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_logsKey, logsJson);

      // Children
      final childrenJson = jsonEncode(
        _children.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_childrenKey, childrenJson);
    } catch (e) {
      print('DEBUG DailyLogStore: Cache save error: $e');
    }
  }

  /// Log upsert (aynı childId+dateKey+type varsa overwrite)
  Future<bool> upsertLog(DailyLogItem log) async {
    try {
      // Mevcut log var mı kontrol et
      final existingIndex = _logs.indexWhere(
        (l) =>
            l.childId == log.childId &&
            l.dateKey == log.dateKey &&
            l.type == log.type,
      );

      if (existingIndex != -1) {
        // Overwrite
        _logs[existingIndex] = log;
      } else {
        // Yeni ekle
        _logs.add(log);
      }

      // Firestore'a yaz
      await _firestore
          .collection('dailyLogs')
          .doc('${log.childId}_${log.dateKey}_${log.type.name}')
          .set(log.toJson());
      print('DEBUG DailyLogStore: Upserted log for ${log.childId}');

      await _saveToCache();
      final success = true;
      
      if (success) {
        // Activity log
        final event = ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: ActivityEventType.dailyUpdated,
          actorRole: ActorRole.teacher,
          actorId: log.createdByTeacherId,
          classId: log.classId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          description: 'Günlük: ${log.childId} ${log.type.name}=${log.status.name}',
        );
        await ActivityLogStore().addEvent(event);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Class ve tarih için logları getir (Map<childId, List<DailyLogItem>>)
  Map<String, List<DailyLogItem>> listByClassAndDate(
    String classId,
    String dateKey,
  ) {
    final filtered = _logs.where(
      (l) => l.classId == classId && l.dateKey == dateKey,
    );

    final grouped = <String, List<DailyLogItem>>{};
    for (final log in filtered) {
      grouped.putIfAbsent(log.childId, () => []).add(log);
    }

    return grouped;
  }

  /// Child için tarih aralığındaki logları getir
  List<DailyLogItem> listByChildRange(
    String childId,
    String startDateKey,
    String endDateKey,
  ) {
    return _logs.where((l) {
      if (l.childId != childId) return false;
      return l.dateKey.compareTo(startDateKey) >= 0 &&
          l.dateKey.compareTo(endDateKey) <= 0;
    }).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey)); // En yeni üstte
  }

  /// Parent için özet (sadece belirtilen tarih)
  Map<DailyLogType, DailyLogItem?> summaryForParent(
    String childId,
    String dateKey,
  ) {
    final logsForDay = _logs.where(
      (l) => l.childId == childId && l.dateKey == dateKey,
    );

    final summary = <DailyLogType, DailyLogItem?>{
      DailyLogType.meal: null,
      DailyLogType.nap: null,
      DailyLogType.toilet: null,
      DailyLogType.activity: null,
    };

    for (final log in logsForDay) {
      if (log.type != DailyLogType.note) {
        summary[log.type] = log;
      }
    }

    return summary;
  }

  /// Notları getir (child + date)
  List<DailyLogItem> getNotesForDay(String childId, String dateKey) {
    return _logs
        .where(
          (l) =>
              l.childId == childId &&
              l.dateKey == dateKey &&
              l.type == DailyLogType.note,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni üstte
  }

  /// Child ekle/güncelle
  Future<bool> upsertChild(Child child) async {
    try {
      final existingIndex = _children.indexWhere((c) => c.id == child.id);

      if (existingIndex != -1) {
        _children[existingIndex] = child;
      } else {
        _children.add(child);
      }

      // Firestore'a yaz
      await _firestore
          .collection('children')
          .doc(child.id)
          .set(child.toJson());
      print('DEBUG DailyLogStore: Upserted child ${child.id}');

      await _saveToCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Class children listesi
  List<Child> getChildrenByClass(String classId) {
    return _children.where((c) => c.classId == classId).toList()
      ..sort((a, b) => a.name.compareTo(b.name)); // Alfabetik
  }

  /// Child ID ile bul
  Child? getChildById(String childId) {
    try {
      return _children.firstWhere((c) => c.id == childId);
    } catch (e) {
      return null;
    }
  }


}
