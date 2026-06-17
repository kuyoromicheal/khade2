import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/provider_onboard_constants.dart';
import '../../services/location_service.dart';
import '../../services/provider_onboarding_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/provider_onboard_layout.dart';

/// Step 4 — How you work + your territory (combined).
class ProviderSignupStep4Screen extends StatefulWidget {
  const ProviderSignupStep4Screen({super.key});

  @override
  State<ProviderSignupStep4Screen> createState() => _ProviderSignupStep4ScreenState();
}

class _ProviderSignupStep4ScreenState extends State<ProviderSignupStep4Screen> {
  final _styles = <String>{};
  double _travelRadius = 10;
  String _travelFee = 'free';
  final _feeNote = TextEditingController();
  final _mapController = MapController();
  final _search = TextEditingController();
  LatLng _pin = const LatLng(defaultLat, defaultLng);
  String _address = '';
  String? _area;
  final _additionalAreas = <String>{};
  bool _geocoding = false;
  bool _locating = false;
  Timer? _debounce;

  static const _workOptions = [
    _WorkOpt('in_studio', Icons.store_outlined, 'Clients come to me', 'Salon, studio, or space I work from'),
    _WorkOpt('mobile', Icons.directions_car_outlined, 'I visit clients', 'Home visits, hotels, events'),
    _WorkOpt('virtual', Icons.laptop_outlined, 'Virtual / Online', 'Tutorials, consultations online'),
  ];

  bool get _virtualOnly =>
      _styles.isNotEmpty && !_styles.contains('in_studio') && !_styles.contains('mobile');

  @override
  void initState() {
    super.initState();
    final d = ProviderOnboardingController.instance.data;
    _styles.addAll(d.workStyles);
    _travelRadius = d.travelRadius.toDouble();
    _travelFee = d.travelFeeType;
    _feeNote.text = d.travelFeeNote ?? '';
    _pin = LatLng(d.latitude, d.longitude);
    _address = d.address ?? '';
    _area = d.area;
    _additionalAreas.addAll(d.additionalAreas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_virtualOnly && _styles.isNotEmpty) {
        _mapController.move(_pin, 15);
        if (_address.isEmpty) _reverseGeocode(_pin);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _feeNote.dispose();
    _search.dispose();
    super.dispose();
  }

  void _toggleWork(String id) {
    setState(() {
      if (_styles.contains(id)) {
        _styles.remove(id);
      } else {
        _styles.add(id);
      }
    });
  }

  void _onMapMoved() {
    final center = _mapController.camera.center;
    setState(() => _pin = center);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _reverseGeocode(center));
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _geocoding = true);
    final geo = await reverseGeocodeAt(point.latitude, point.longitude);
    if (!mounted) return;
    setState(() {
      _geocoding = false;
      _address = geo.address;
      _area ??= _matchArea(geo.label);
    });
  }

  String? _matchArea(String label) {
    final lower = label.toLowerCase();
    for (final a in ProviderOnboardConstants.abujaAreas) {
      if (lower.contains(a.toLowerCase())) return a;
    }
    return null;
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    final loc = await resolveUserLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get GPS — check location permission')),
      );
      return;
    }
    _pin = LatLng(loc.latitude, loc.longitude);
    _address = loc.address;
    _area ??= _matchArea(loc.label);
    _mapController.move(_pin, 15);
    setState(() {});
  }

  bool get _locationOk => _virtualOnly ? (_area != null && _area!.isNotEmpty) : _address.trim().isNotEmpty;

  bool get _canContinue => _styles.isNotEmpty && _locationOk;

  void _saveAndNext() {
    ProviderOnboardingController.instance.update((d) => d.copyWith(
          workStyles: _styles.toList(),
          travelRadius: _travelRadius.round(),
          travelFeeType: _travelFee,
          travelFeeNote: _feeNote.text.trim().isEmpty ? null : _feeNote.text.trim(),
          latitude: _pin.latitude,
          longitude: _pin.longitude,
          address: _virtualOnly ? (_area ?? 'Abuja') : _address,
          area: _area ?? 'Wuse II',
          additionalAreas: _additionalAreas.toList(),
        ));
    context.go('/provider-signup/step5');
  }

  @override
  Widget build(BuildContext context) {
    return ProviderOnboardLayout(
      step: 4,
      onBack: () => context.pop(),
      onNext: _saveAndNext,
      nextDisabled: !_canContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How do you work?', style: ProviderOnboardStyles.stepTitle(context)),
          const SizedBox(height: 6),
          Text('Pick all that apply, then set your location', style: ProviderOnboardStyles.stepSub(context)),
          const SizedBox(height: 16),
          for (final opt in _workOptions)
            GestureDetector(
              onTap: () => _toggleWork(opt.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _styles.contains(opt.id) ? AppColors.matchaPale : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _styles.contains(opt.id) ? AppColors.matcha : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(opt.icon, color: _styles.contains(opt.id) ? AppColors.matcha : AppColors.soft),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.title, style: AppTheme.sans(13, weight: FontWeight.w600)),
                          Text(opt.subtitle, style: AppTheme.sans(11, color: AppColors.soft)),
                        ],
                      ),
                    ),
                    Icon(_styles.contains(opt.id) ? Icons.check_circle : Icons.circle_outlined,
                        color: _styles.contains(opt.id) ? AppColors.matcha : AppColors.border),
                  ],
                ),
              ),
            ),
          if (_styles.contains('mobile')) ...[
            const SizedBox(height: 8),
            Text('Travel radius', style: AppTheme.sans(12, weight: FontWeight.w600)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _travelRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.matcha,
                    onChanged: (v) => setState(() => _travelRadius = v),
                  ),
                ),
                Text('${_travelRadius.round()}km', style: AppTheme.sans(12, color: AppColors.matcha)),
              ],
            ),
          ],
          if (_styles.isNotEmpty) ...[
            const Divider(height: 28),
            Text('Where are you based?', style: AppTheme.sans(14, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (!_virtualOnly) ...[
              TextField(
                controller: _search,
                decoration: ProviderOnboardStyles.input('Search address or area').copyWith(
                  prefixIcon: const Icon(Icons.search, color: AppColors.soft),
                ),
                onSubmitted: (_) {
                  if (_search.text.trim().isNotEmpty) setState(() => _address = _search.text.trim());
                },
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pin,
                          initialZoom: 15,
                          onMapEvent: (e) {
                            if (e is MapEventMoveEnd) _onMapMoved();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.khade.khade_app',
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Center(child: Icon(Icons.location_on, size: 40, color: AppColors.matcha.withValues(alpha: 0.9))),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'onboard_gps4',
                          backgroundColor: AppColors.white,
                          onPressed: _locating ? null : _useGps,
                          child: _locating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, color: AppColors.matcha, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_geocoding)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Updating address…', style: AppTheme.sans(11, color: AppColors.soft)),
                ),
              if (_address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.matcha, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_address, style: AppTheme.sans(11, color: AppColors.matchaDeep))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            Text('Your main area', style: AppTheme.sans(12, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProviderOnboardConstants.abujaAreas.map((a) {
                final active = _area == a;
                return FilterChip(
                  label: Text(a),
                  selected: active,
                  onSelected: (_) => setState(() {
                    _area = a;
                    _additionalAreas.remove(a);
                  }),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkOpt {
  const _WorkOpt(this.id, this.icon, this.title, this.subtitle);
  final String id, title, subtitle;
  final IconData icon;
}
