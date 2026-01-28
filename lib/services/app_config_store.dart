import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/app_config.dart';

/// App Config Store - Singleton
/// Uygulama geneli konfigurasyon yönetimi
class AppConfigStore {
  static final AppConfigStore _instance = AppConfigStore._internal();
  factory AppConfigStore() => _instance;
  AppConfigStore._internal();

  static const String _configKey = 'app_config';

  AppConfig? _config;
  bool _isLoaded = false;

  /// Getters
  AppConfig? get config => _config;
  bool get isLoaded => _isLoaded;
  bool get hasConfig => _config != null;

  /// Tüm verileri yükle
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        final map = jsonDecode(configJson) as Map<String, dynamic>;
        _config = AppConfig.fromJson(map);
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// SchoolType'ı ilk kez set et (locked)
  /// Zaten config varsa false döner
  Future<bool> setSchoolTypeOnce(SchoolType type) async {
    if (_config != null) {
      return false; // Zaten set edilmiş
    }

    try {
      _config = AppConfig(
        schoolType: type,
        setAt: DateTime.now().millisecondsSinceEpoch,
        locked: true,
      );

      return await _save();
    } catch (e) {
      return false;
    }
  }

  /// Config'i sıfırla (SADECE DEBUG)
  Future<bool> resetConfigForDev() async {
    // Debug mode check (kDebugMode veya benzeri kullanılabilir)
    const bool kDebugMode = true; // Flutter'da: import 'package:flutter/foundation.dart'; kDebugMode
    
    if (!kDebugMode) {
      return false; // Production'da izin yok
    }

    try {
      _config = null;
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_configKey);
    } catch (e) {
      return false;
    }
  }

  /// Kaydet
  Future<bool> _save() async {
    try {
      if (_config == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_config!.toJson());
      return await prefs.setString(_configKey, jsonString);
    } catch (e) {
      return false;
    }
  }
}
