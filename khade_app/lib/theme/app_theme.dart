import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const _serifFamily = 'Georgia';
  static const _sansFamily = 'Segoe UI';

  static TextStyle serif(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(fontFamily: _serifFamily, fontSize: size, fontWeight: weight, color: color ?? AppColors.dark, height: 1.2);

  static TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(fontFamily: _sansFamily, fontSize: size, fontWeight: weight, color: color ?? AppColors.dark, height: 1.35);

  static TextStyle labelCaps(String text) => sans(10, color: AppColors.soft, weight: FontWeight.w500).copyWith(letterSpacing: 1.2);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.matcha,
      primary: AppColors.matcha,
      onPrimary: AppColors.white,
      secondary: AppColors.gold,
      surface: AppColors.cream,
      onSurface: AppColors.dark,
      outline: AppColors.border,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: _sansFamily,
      colorScheme: scheme,
      dividerColor: AppColors.border,
      cardColor: AppColors.surface,
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.matchaPale,
        selectedColor: AppColors.matcha,
        labelStyle: sans(11),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.matcha,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: serif(22, color: AppColors.dark),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ivory,
        selectedItemColor: AppColors.matcha,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
