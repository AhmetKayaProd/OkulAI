import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kresai/models/ai_config.dart';
import 'package:kresai/config/api_config.dart';

/// AI Config Store - Singleton
/// Gemini API key persist (plaintext for V1, production'da encrypt edilmeli)
class AiConfigStore {
  static final AiConfigStore _instance = AiConfigStore._internal();
  factory AiConfigStore() => _instance;
  AiConfigStore._internal();

  static const String _configKey = 'ai_config';

  AiConfig? _config;
  bool _isLoaded = false;

  /// Getters
  AiConfig? get config => _config;
  bool get isLoaded => _isLoaded;
  bool get hasApiKey => _config?.geminiApiKey != null && _config!.geminiApiKey!.isNotEmpty;

  /// Load config
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final map = jsonDecode(configJson) as Map<String, dynamic>;
        _config = AiConfig.fromJson(map);
      } else {
        // Auto-initialize with API key from environment/config
        _config = AiConfig(
          geminiApiKey: ApiConfig.geminiApiKey,
          enabled: true,
        );
        // Save the default config
        await _save();
      }

      _isLoaded = true;
    } catch (e) {
      _isLoaded = true;
    }
  }

  /// Set API key
  Future<bool> setApiKey(String apiKey) async {
    try {
      _config = (_config ?? const AiConfig()).copyWith(
        geminiApiKey: apiKey.trim(),
        enabled: apiKey.trim().isNotEmpty,
      );
      
      return await _save();
    } catch (e) {
      return false;
    }
  }

  /// Clear API key
  Future<bool> clearApiKey() async {
    try {
      _config = const AiConfig(enabled: false);
      return await _save();
    } catch (e) {
      return false;
    }
  }

  /// Save
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
