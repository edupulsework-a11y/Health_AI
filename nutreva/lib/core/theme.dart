import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED); // Vibrant Violet
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFFED3AC1); // Logo Pink
  static const Color accent = Color(0xFF3AC4ED); // Logo Cyan
  static const Color orange = Color(0xFFED6D3A); // Logo Orange
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textBody = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color error = Color(0xFFEF4444);

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFED3AC1), Color(0xFF3AC4ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textBody,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
