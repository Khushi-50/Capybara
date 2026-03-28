import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF090D19);
  static const surface = Color(0xFF131A2A);
  static const surfaceMuted = Color(0xFF1C2235);
  static const text = Color(0xFFF5F7FF);
  static const textMuted = Color(0xFF9EA7C0);
  static const cyan = Color(0xFF24D7FF);
  static const purple = Color(0xFF9B4DFF);
  static const green = Color(0xFF52E6A4);
  static const yellow = Color(0xFFF6C445);
  static const red = Color(0xFFFF646C);
  static const border = Color(0xFF2B3147);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
