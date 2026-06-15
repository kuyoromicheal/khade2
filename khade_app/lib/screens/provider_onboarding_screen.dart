import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  int _step = 0;
  String _category = 'makeup';
  String _visitTypes = 'both';
  String _area = 'Wuse II';
  final _bio = TextEditingController();
  bool _loading = false;

  static const _categories = {
    'makeup': 'Makeup',
    'nails': 'Nails',
    'spa': 'Spa',
    'barbing': 'Barbing',
    'hair': 'Hair',
    'skincare': 'Skincare',
    'braids': 'Braids',
  };

  static const _defaultServices = {
    'makeup': [{'name': 'Soft Glam', 'duration': '60 mins', 'price': 8000}],
    'nails': [{'name': 'Gel Manicure', 'duration': '60 mins', 'price': 8500}],
    'spa': [{'name': 'Swedish Massage', 'duration': '60 mins', 'price': 15000}],
    'barbing': [{'name': 'Classic Cut', 'duration': '30 mins', 'price': 4000}],
    'hair': [{'name': 'Wash & Blow', 'duration': '45 mins', 'price': 5000}],
    'skincare': [{'name': 'Express Facial', 'duration': '45 mins', 'price': 10000}],
    'braids': [{'name': 'Box Braids', 'duration': '180 mins', 'price': 12000}],
  };

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await khadeApi.onboardProvider(
        categorySlug: _category,
        services: _defaultServices[_category]!,
        visitTypes: _visitTypes,
        area: _area,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      );
      if (mounted) context.go('/provider-dash');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provider setup', style: AppTheme.serif(28)),
              Text('Step ${_step + 1} of 3 — Khade takes 10%, not 20% like Fresha', style: AppTheme.sans(12, color: AppColors.soft)),
              const SizedBox(height: 24),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    _stepCategory(),
                    _stepLocation(),
                    _stepBio(),
                  ],
                ),
              ),
              PrimaryButton(
                label: _loading ? 'Saving...' : (_step < 2 ? 'Continue' : 'Submit for review'),
                onPressed: _loading ? null : () {
                  if (_step < 2) {
                    setState(() => _step++);
                  } else {
                    _submit();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCategory() {
    return ListView(
      children: [
        Text('Your category', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.entries.map((e) {
            final active = _category == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: active,
              onSelected: (_) => setState(() => _category = e.key),
              selectedColor: AppColors.matchaPale,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepLocation() {
    return ListView(
      children: [
        Text('Service location', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 12),
        for (final v in ['home', 'salon', 'both'])
          RadioListTile<String>(
            title: Text(v == 'home' ? 'Home visits only' : v == 'salon' ? 'At salon only' : 'Both home & salon'),
            value: v,
            groupValue: _visitTypes,
            onChanged: (x) => setState(() => _visitTypes = x!),
            activeColor: AppColors.matcha,
          ),
        const SizedBox(height: 12),
        Text('Primary area', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _area,
          items: ['Wuse II', 'Maitama', 'Garki', 'Asokoro', 'Gwarinpa', 'Utako']
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) => setState(() => _area = v ?? _area),
          decoration: InputDecoration(filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _stepBio() {
    return ListView(
      children: [
        Text('Tell clients about you', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Years of experience, specialties, brands you use...',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(12)),
          child: Text('Your profile goes under review. Once approved, you appear in Explore and can receive bookings.', style: AppTheme.sans(12, color: AppColors.matchaDeep)),
        ),
      ],
    );
  }
}
