import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF332B32);
  static const muted = Color(0xFF887D85);
  static const rose = Color(0xFFB95F78);
  static const roseLight = Color(0xFFF5E5E9);
  static const cream = Color(0xFFFCF9F6);
  static const sage = Color(0xFF64836F);
  static const sageLight = Color(0xFFE8F0E9);
  static const border = Color(0xFFF0E9E5);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.rose,
          surface: AppColors.cream,
          onSurface: AppColors.ink,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          titleLarge: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14),
        ),
      );
}
