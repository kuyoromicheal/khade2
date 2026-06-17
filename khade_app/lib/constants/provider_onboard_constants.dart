import 'package:flutter/material.dart';

class ProviderCraftCategory {
  const ProviderCraftCategory({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class ProviderOnboardConstants {
  ProviderOnboardConstants._();

  static const crafts = [
    ProviderCraftCategory(id: 'barbing', label: 'Barbing', icon: Icons.content_cut),
    ProviderCraftCategory(id: 'nails', label: 'Nails', icon: Icons.colorize_outlined),
    ProviderCraftCategory(id: 'makeup', label: 'Makeup', icon: Icons.brush_outlined),
    ProviderCraftCategory(id: 'spa', label: 'Spa', icon: Icons.spa_outlined),
    ProviderCraftCategory(id: 'hair', label: 'Hair', icon: Icons.dry_cleaning_outlined),
    ProviderCraftCategory(id: 'braids', label: 'Braids', icon: Icons.waves_outlined),
    ProviderCraftCategory(id: 'skincare', label: 'Skincare', icon: Icons.face_outlined),
    ProviderCraftCategory(id: 'lashes', label: 'Lashes', icon: Icons.remove_red_eye_outlined),
    ProviderCraftCategory(id: 'massage', label: 'Massage', icon: Icons.self_improvement_outlined),
    ProviderCraftCategory(id: 'facials', label: 'Facials', icon: Icons.face_retouching_natural_outlined),
    ProviderCraftCategory(id: 'dental', label: 'Dental', icon: Icons.medical_services_outlined),
    ProviderCraftCategory(id: 'pedicure', label: 'Pedicure', icon: Icons.directions_walk_outlined),
  ];

  static const abujaAreas = [
    'Maitama', 'Wuse II', 'Garki', 'Gwarinpa', 'Asokoro', 'Utako',
    'Jabi', 'Wuse', 'Kubwa', 'Nyanya', 'Lugbe', 'Karu',
  ];

}
