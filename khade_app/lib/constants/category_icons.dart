import 'package:flutter/material.dart';

/// Maps category slugs to closest MaterialCommunityIcons names.
class CategoryIcons {
  CategoryIcons._();

  static const matcha = Color(0xFF4A7C59);

  static const Map<String, IconData> icons = {
    'all': Icons.grid_view_outlined,
    'hair': Icons.dry_cleaning_outlined,
    'nails': Icons.colorize_outlined,
    'makeup': Icons.brush_outlined,
    'brows_lashes': Icons.remove_red_eye_outlined,
    'barbing': Icons.content_cut,
    'spa': Icons.spa_outlined,
    'massage': Icons.self_improvement_outlined,
    'skincare': Icons.face_outlined,
    'braids': Icons.waves_outlined,
    'dental': Icons.medical_services_outlined,
    'facials': Icons.face_retouching_natural_outlined,
    'pedicure': Icons.directions_walk_outlined,
    'waxing': Icons.healing_outlined,
    'tattoo': Icons.draw_outlined,
    'lashes': Icons.remove_red_eye_outlined,
    'lips': Icons.brush_outlined,
  };

  static IconData forSlug(String slug) => icons[slug] ?? Icons.category_outlined;
}
