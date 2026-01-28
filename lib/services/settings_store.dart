import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/school_settings.dart';

/// Settings Store - Singleton pattern
/// Okul ayarlarını local storage'da persist eder
class SettingsStore {
  static final SettingsStore _instance = SettingsStore._internal();
  factory SettingsStore() => _instance;
  SettingsStore._internal();

  static const String _settingsKey = 'school_settings';
  
  SchoolSettings _settings = SchoolSettings.defaultSettings;
  bool _isLoaded = false;

  /// Mevcut ayarları al
  SchoolSettings get settings => _settings;

  /// Ayarlar yüklenmiş mi
  bool get isLoaded => _isLoaded;

  /// Ayarları shared_preferences'tan yükle
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = SchoolSettings.fromJson(json);
      } else {
        _settings = SchoolSettings.defaultSettings;
      }
      
      _isLoaded = true;
    } catch (e) {
      // Hata durumunda default settings kullan
      _settings = SchoolSettings.defaultSettings;
      _isLoaded = true;
    }
  }

  /// Ayarları kaydet
  Future<bool> save(SchoolSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(newSettings.toJson());
      final success = await prefs.setString(_settingsKey, jsonString);
      
      if (success) {
        _settings = newSettings;
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Ayarları temizle (reset)
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_settingsKey);
      
      if (success) {
        _settings = SchoolSettings.defaultSettings;
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }
}
