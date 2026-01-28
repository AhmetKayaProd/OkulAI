import 'package:flutter/material.dart';

/// OkulAI Modern Design Tokens
/// Minimalist, profesyonel ve modern bir görünüm için güncellenmiş tokenlar.
class AppTokens {
  AppTokens._();

  // --- Colors (Modern & Soft Palette) ---
  static const Color backgroundLight = Color(0xFFF8FAFC); // Soft Slate
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  
  // Primary: Indigo-ish Blue (Modern & Trustworthy)
  static const Color primaryLight = Color(0xFF4F46E5); 
  static const Color primaryLightSoft = Color(0xFFEEF2FF);
  
  // Secondary: Teal/Emerald (Success & Growth)
  static const Color secondaryLight = Color(0xFF10B981);
  static const Color secondaryLightSoft = Color(0xFFECFDF5);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A); // Deep Slate
  static const Color textSecondaryLight = Color(0xFF64748B); // Muted Slate
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Light Slate
  
  // Semantic Colors
  static const Color errorLight = Color(0xFFEF4444);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color successLight = Color(0xFF10B981);
  static const Color infoLight = Color(0xFF3B82F6);

  // --- Border Radius (Modern Rounded Look) ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  // --- Spacing (8pt Grid System) ---
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // --- Component Sizes ---
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
  static const double cardElevation = 0.0; // Flat design with borders
  
  // --- Shadows (Subtle & Modern) ---
  static List<BoxShadow> get shadowSubtle => [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
