import 'package:flutter/material.dart';

/// Okul ayarları model sınıfı
class SchoolSettings {
  final String schoolName;
  final String slogan;
  final String? logoPath; // Şimdilik null, ileride dosya yolu
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const SchoolSettings({
    required this.schoolName,
    this.slogan = '',
    this.logoPath,
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.endTime = const TimeOfDay(hour: 16, minute: 0),
  });

  /// JSON'dan model oluştur
  factory SchoolSettings.fromJson(Map<String, dynamic> json) {
    return SchoolSettings(
      schoolName: json['schoolName'] as String? ?? '',
      slogan: json['slogan'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 9,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 16,
        minute: json['endMinute'] as int? ?? 0,
      ),
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'schoolName': schoolName,
      'slogan': slogan,
      'logoPath': logoPath,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

  /// Varsayılan ayarlar
  static const SchoolSettings defaultSettings = SchoolSettings(
    schoolName: '',
    slogan: '',
  );

  /// Copy with method
  SchoolSettings copyWith({
    String? schoolName,
    String? slogan,
    String? logoPath,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return SchoolSettings(
      schoolName: schoolName ?? this.schoolName,
      slogan: slogan ?? this.slogan,
      logoPath: logoPath ?? this.logoPath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Saat aralığını formatted string olarak döndür
  String get activeHoursFormatted {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start–$end';
  }
}
