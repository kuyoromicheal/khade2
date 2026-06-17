import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key, this.providerType = 'solo_pro'});
  final String providerType;

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  int _step = 0;
  String _category = 'makeup';
  late String _providerType;
  int _travelRadius = 10;
  String _area = 'Wuse II';
  final _coverageAreas = <String>{'Wuse II'};
  final _workLocations = <String>{'client_home', 'own_home', 'rented_studio'};
  final _bio = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _providerType = widget.providerType;
  }

  static const _categories = {
    'makeup': 'Makeup',
    'nails': 'Nails',
    'spa': 'Spa',
    'barbing': 'Barbing',
    'hair': 'Hair',
    'skincare': 'Skincare',
    'braids': 'Braids',
    'dental': 'Dental',
    'facials': 'Facials',
    'brows_lashes': 'Brows & Lashes',
  };

  static const _defaultServices = {
    'makeup': [{'name': 'Soft Glam', 'duration': '60 mins', 'price': 8000}],
    'nails': [{'name': 'Gel Manicure', 'duration': '60 mins', 'price': 8500}],
    'spa': [{'name': 'Swedish Massage', 'duration': '60 mins', 'price': 15000}],
    'barbing': [{'name': 'Classic Cut', 'duration': '30 mins', 'price': 4000}],
    'hair': [{'name': 'Wash & Blow', 'duration': '45 mins', 'price': 5000}],
    'skincare': [{'name': 'Express Facial', 'duration': '45 mins', 'price': 10000}],
    'braids': [{'name': 'Box Braids', 'duration': '180 mins', 'price': 12000}],
    'dental': [{'name': 'Dental Consultation', 'duration': '30 mins', 'price': 5000}],
    'facials': [{'name': 'Basic Facial', 'duration': '45 mins', 'price': 12000}],
    'brows_lashes': [{'name': 'Classic Lash Set', 'duration': '90 mins', 'price': 12000}],
  };

  String get _visitTypes {
    if (_providerType == 'salon') return 'salon';
    if (_providerType == 'mobile') return 'home';
    if (_providerType == 'solo_pro') return 'home';
    return 'both';
  }

  String get _providerSubtype => _providerType == 'solo_pro' ? 'solo_pro' : (_providerType == 'salon' ? 'salon' : 'mobile');

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await khadeApi.onboardProvider(
        categorySlug: _category,
        services: _defaultServices[_category]!,
        visitTypes: _visitTypes,
        providerType: _providerType == 'solo_pro' ? 'mobile' : _providerType,
        providerSubtype: _providerSubtype,
        workLocations: _workLocations.toList(),
        coverageAreas: _coverageAreas.toList(),
        travelRadiusKm: _travelRadius,
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
  void dispose() {
    _bio.dispose();
    super.dispose();
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
                    _stepBusinessType(),
                    _stepBio(),
                  ],
                ),
              ),
              PrimaryButton(
                label: _loading ? 'Saving...' : (_step < 2 ? 'Continue' : 'Complete setup'),
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

  Widget _stepBusinessType() {
    if (_providerType == 'solo_pro') return _soloProStep();
    return ListView(
      children: [
        Text('How do you offer your services?', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (_providerType == 'salon')
          _typeCard('salon', '🏪', 'Salon / Studio', 'Clients come to me', locked: true)
        else if (_providerType == 'mobile')
          _typeCard('mobile', '🚗', 'Mobile Pro', 'I travel to clients', locked: true),
        if (_providerType != 'salon') ...[
          const SizedBox(height: 16),
          Text('Travel radius', style: AppTheme.sans(13, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [5, 10, 20, 30].map((km) => ChoiceChip(
              label: Text('${km}km'),
              selected: _travelRadius == km,
              onSelected: (_) => setState(() => _travelRadius = km),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Base area (where you operate from)', style: AppTheme.sans(13, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _area,
            items: ['Wuse II', 'Maitama', 'Garki', 'Asokoro', 'Gwarinpa', 'Utako']
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _area = v ?? _area),
            decoration: InputDecoration(filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text('Salon area', style: AppTheme.sans(13, weight: FontWeight.w500)),
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
      ],
    );
  }

  Widget _soloProStep() {
    const locs = {
      'client_home': "At client's home/location",
      'rented_studio': 'I can rent a studio space',
      'own_home': 'At my own home',
      'hotel': 'Hotel / Airbnb visits',
      'events': 'Events & occasions',
    };
    const areas = ['Wuse II', 'Maitama', 'Garki', 'Asokoro', 'Gwarinpa', 'Utako'];
    return ListView(
      children: [
        Text("I'm a Solo Pro", style: AppTheme.serif(22)),
        Text('I have skills but no permanent space', style: AppTheme.sans(12, color: AppColors.soft)),
        const SizedBox(height: 16),
        Text('Where can you work?', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        for (final e in locs.entries)
          CheckboxListTile(
            value: _workLocations.contains(e.key),
            onChanged: (v) => setState(() {
              if (v == true) _workLocations.add(e.key); else _workLocations.remove(e.key);
            }),
            title: Text(e.value, style: AppTheme.sans(12)),
            activeColor: AppColors.matcha,
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 12),
        Text('Your coverage areas', style: AppTheme.sans(13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: areas.map((a) {
            final sel = _coverageAreas.contains(a);
            return FilterChip(
              label: Text(a),
              selected: sel,
              onSelected: (_) => setState(() {
                if (sel) _coverageAreas.remove(a); else _coverageAreas.add(a);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _typeCard(String type, String emoji, String title, String subtitle, {bool locked = false}) {
    final active = _providerType == type;
    return GestureDetector(
      onTap: locked ? null : () => setState(() => _providerType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.matchaPale : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.matcha : AppColors.border, width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.sans(13, weight: FontWeight.w600)),
                  Text(subtitle, style: AppTheme.sans(11, color: AppColors.soft)),
                ],
              ),
            ),
          ],
        ),
      ),
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
            hintText: 'Your experience, specialties, what makes you unique...',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
