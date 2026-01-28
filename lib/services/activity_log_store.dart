import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/activity_event.dart';

/// Activity Log Store - Singleton
/// Sistem aktivite loglarını persist eder
class ActivityLogStore {
  static final ActivityLogStore _instance = ActivityLogStore._internal();
  factory ActivityLogStore() => _instance;
  ActivityLogStore._internal();

  static const String _eventsKey = 'activity_events';

  List<ActivityEvent> _events = [];
  bool _isLoaded = false;

  /// Getters
  List<ActivityEvent> get events => _events;
  bool get isLoaded => _isLoaded;

  /// Tüm verileri yükle
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final list = jsonDecode(eventsJson) as List;
        _events = list
            .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// Event ekle
  Future<bool> addEvent(ActivityEvent event) async {
    try {
      _events.add(event);
      return await _save();
    } catch (e) {
      return false;
    }
  }

  /// Son N event'i getir (en yeni üstte)
  List<ActivityEvent> getLatest({int limit = 20}) {
    final sorted = List<ActivityEvent>.from(_events);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni üstte
    return sorted.take(limit).toList();
  }

  /// ClassId'ye göre event'leri getir
  List<ActivityEvent> getByClass(String classId, {int limit = 20}) {
    final filtered = _events.where((e) => e.classId == classId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList();
  }

  /// Kaydet
  Future<bool> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _events.map((e) => e.toJson()).toList(),
      );
      return await prefs.setString(_eventsKey, jsonString);
    } catch (e) {
      return false;
    }
  }
}
