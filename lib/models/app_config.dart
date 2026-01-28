import 'package:flutter/material.dart';

/// School Type
enum SchoolType {
  preschool,      // Kreş
  kindergarten,   // Anaokulu
  primaryPrivate, // Özel İlkokul
}

/// App Configuration
class AppConfig {
  final SchoolType schoolType;
  final int setAt; // epoch milliseconds
  final bool locked;

  const AppConfig({
    required this.schoolType,
    required this.setAt,
    this.locked = true,
  });

  /// JSON'dan model oluştur
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      schoolType: SchoolType.values.firstWhere(
        (e) => e.name == json['schoolType'],
      ),
      setAt: json['setAt'] as int,
      locked: json['locked'] as bool? ?? true,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'schoolType': schoolType.name,
      'setAt': setAt,
      'locked': locked,
    };
  }
}

/// Feature Flags based on SchoolType
class FeatureFlags {
  final SchoolType schoolType;

  const FeatureFlags(this.schoolType);

  // Common features (tüm tipler için aktif)
  bool get hasFeed => true;
  bool get hasDaily => true;
  bool get hasLive => true;
  bool get hasConsent => true;
  bool get hasActivityLog => true;
  bool get hasDashboards => true;

  // Label değişiklikleri
  String get dailyActivityLabel {
    switch (schoolType) {
      case SchoolType.primaryPrivate:
        return 'Ders/Kazanım';
      case SchoolType.preschool:
      case SchoolType.kindergarten:
        return 'Etkinlik';
    }
  }

  IconData get dailyActivityIcon {
    switch (schoolType) {
      case SchoolType.primaryPrivate:
        return Icons.book;
      case SchoolType.preschool:
      case SchoolType.kindergarten:
        return Icons.palette;
    }
  }

  String get todaySummaryTitle {
    switch (schoolType) {
      case SchoolType.primaryPrivate:
        return 'Bugün (Ders Özeti)';
      case SchoolType.preschool:
      case SchoolType.kindergarten:
        return 'Bugünkü Özet';
    }
  }
}
