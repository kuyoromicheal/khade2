import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const _serifFamily = 'Georgia';
  static const _sansFamily = 'Segoe UI';

  static TextStyle serif(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(fontFamily: _serifFamily, fontSize: size, fontWeight: weight, color: color ?? AppColors.dark);

  static TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(fontFamily: _sansFamily, fontSize: size, fontWeight: weight, color: color ?? AppColors.dark);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: _sansFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.matcha,
        primary: AppColors.matcha,
        surface: AppColors.cream,
      ),
      dividerColor: AppColors.border,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        titleTextStyle: serif(22, color: AppColors.dark),
      ),
    );
  }
}
