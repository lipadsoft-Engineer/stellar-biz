import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF342C35);
  static const plum = Color(0xFF503D50);
  static const plumDeep = Color(0xFF3C3040);
  static const muted = Color(0xFF817781);
  static const rose = Color(0xFF9A6C80);
  static const roseLight = Color(0xFFF1E8EC);
  static const cream = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFEFC);
  static const sage = Color(0xFF6F806F);
  static const sageLight = Color(0xFFEAF0E9);
  static const border = Color(0xFFECE6E0);
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
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          surfaceTintColor: Colors.transparent,
        ),
        dividerColor: AppColors.border,
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
