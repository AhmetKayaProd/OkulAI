import 'package:flutter/material.dart';
import 'tokens.dart';

/// OkulAI Modern Material 3 ThemeData
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter', // Modern sans-serif font (varsayılan olarak sistem fontu kullanılır)
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        surface: AppTokens.surfaceLight,
        primary: AppTokens.primaryLight,
        secondary: AppTokens.secondaryLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppTokens.textPrimaryLight,
        onSurfaceVariant: AppTokens.textSecondaryLight,
        outline: AppTokens.borderLight,
        error: AppTokens.errorLight,
        background: AppTokens.backgroundLight,
      ),
      
      scaffoldBackgroundColor: AppTokens.backgroundLight,
      
      // AppBar Theme (Clean & Minimal)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.surfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppTokens.textPrimaryLight, size: 24),
      ),
      
      // Card Theme (Flat with subtle border)
      cardTheme: CardTheme(
        color: AppTokens.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          side: const BorderSide(color: AppTokens.borderLight, width: 1),
        ),
      ),
      
      // Elevated Button Theme (Modern & Bold)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primaryLight,
          minimumSize: const Size(double.infinity, AppTokens.buttonHeight),
          side: const BorderSide(color: AppTokens.borderLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme (Clean & Accessible)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceLight,
        hintStyle: const TextStyle(color: AppTokens.textTertiaryLight, fontSize: 15),
        labelStyle: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.errorLight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacing20,
          vertical: AppTokens.spacing16,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppTokens.surfaceLight,
        selectedItemColor: AppTokens.primaryLight,
        unselectedItemColor: AppTokens.textTertiaryLight,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.primaryLightSoft,
        labelStyle: const TextStyle(color: AppTokens.primaryLight, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSmall)),
      ),
    );
  }
}
