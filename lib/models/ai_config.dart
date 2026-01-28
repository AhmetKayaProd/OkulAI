/// AI Configuration
class AiConfig {
  final String? geminiApiKey;
  final bool enabled;

  const AiConfig({
    this.geminiApiKey,
    this.enabled = false,
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      geminiApiKey: json['geminiApiKey'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'geminiApiKey': geminiApiKey,
      'enabled': enabled,
    };
  }

  AiConfig copyWith({
    String? geminiApiKey,
    bool? enabled,
  }) {
    return AiConfig(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      enabled: enabled ?? this.enabled,
    );
  }
}
