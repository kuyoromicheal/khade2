import 'package:flutter/material.dart';

/// Khade palette — matcha green, ivory, soft gold. Simple luxury.
abstract final class AppColors {
  static const matcha = Color(0xFF3D6B4F);
  static const matchaLight = Color(0xFF5C8F6E);
  static const matchaPale = Color(0xFFE6EFE9);
  static const matchaDeep = Color(0xFF1E3D2B);
  static const matchaMuted = Color(0xFF8FAF98);

  static const gold = Color(0xFFB8954A);
  static const goldLight = Color(0xFFF0E6CC);
  static const goldMuted = Color(0xFFD4BC82);

  static const cream = Color(0xFFFAF9F6);
  static const ivory = Color(0xFFFFFFF8);
  static const surface = Color(0xFFFFFFFF);

  static const dark = Color(0xFF1C1C1C);
  static const mid = Color(0xFF5A5A5A);
  static const soft = Color(0xFF9A9A9A);
  static const border = Color(0xFFE8E6E0);
  static const borderLight = Color(0xFFF0EDE6);

  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFC45C4A);
  static const green = Color(0xFF2E6B45);
  static const greenBg = Color(0xFFE8F2EB);
  static const redBg = Color(0xFFFAEEEC);
  static const redDark = Color(0xFFA83D32);

  static const navInactive = Color(0xFFB8B8B8);

  static LinearGradient get matchaGradient => const LinearGradient(
        colors: [matchaDeep, matcha],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get luxuryCard => const LinearGradient(
        colors: [Color(0xFF1E3D2B), Color(0xFF2D5240)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
