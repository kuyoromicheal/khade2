import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../services/khade_repository.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/geo_utils.dart';
import '../widgets/common_widgets.dart';

/// Glovo-style map pin picker — drag map under fixed pin, confirm delivery point.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  LatLng _pin = LatLng(defaultLat, defaultLng);
  String _label = 'Loading…';
  String _address = '';
  double? _accuracyMeters;
  bool _inServiceArea = true;
  bool _geocoding = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final repo = KhadeRepository.instance;
    _pin = LatLng(repo.userLat, repo.userLng);
    _label = repo.locationLabel;
    _address = repo.userAddress;
    _accuracyMeters = repo.locationAccuracyMeters;
    _inServiceArea = repo.inServiceArea;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_pin, 16);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
      _label = geo.label;
      _address = geo.address;
      _inServiceArea = isInAbujaServiceArea(point.latitude, point.longitude);
    });
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
    _label = loc.label;
    _address = loc.address;
    _accuracyMeters = loc.accuracyMeters;
    _inServiceArea = isInAbujaServiceArea(loc.latitude, loc.longitude);
    _mapController.move(_pin, 16);
    setState(() {});
  }

  void _selectSaved(SavedAddress saved) {
    _pin = LatLng(saved.latitude, saved.longitude);
    _label = saved.label;
    _address = saved.address;
    _inServiceArea = isInAbujaServiceArea(saved.latitude, saved.longitude);
    _mapController.move(_pin, 16);
    setState(() {});
  }

  Future<void> _confirm() async {
    if (!_inServiceArea) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khade is not available in this area yet. Move pin to Abuja.')),
      );
      return;
    }
    final point = DeliveryPoint(
      latitude: _pin.latitude,
      longitude: _pin.longitude,
      label: _label,
      address: _address,
      accuracyMeters: _accuracyMeters,
      pinAdjusted: true,
    );
    await KhadeRepository.instance.applyDeliveryPoint(point);
    if (mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saved = KhadeRepository.instance.savedAddresses;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackHeader(title: 'Delivery location', onBack: () => context.pop()),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pin,
                    initialZoom: 16,
                    onMapEvent: (e) {
                      if (e is MapEventMoveEnd) _onMapMoved();
                    },
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.khade.khade_app',
                    ),
                    if (_accuracyMeters != null && _accuracyMeters! > 0)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _pin,
                            radius: _accuracyMeters!.clamp(10, 120),
                            color: AppColors.matcha.withValues(alpha: 0.12),
                            borderColor: AppColors.matcha.withValues(alpha: 0.35),
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ),
                  ],
                ),
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 48, color: AppColors.matcha.withValues(alpha: 0.9)),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.matcha, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: FloatingActionButton.small(
                    heroTag: 'gps',
                    backgroundColor: AppColors.white,
                    onPressed: _locating ? null : _useGps,
                    child: _locating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: AppColors.matcha),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_inServiceArea)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Text(
                        'Service unavailable — Khade operates in Abuja only',
                        style: AppTheme.sans(12, color: const Color(0xFFC47D00)),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_geocoding ? 'Finding address…' : _label, style: AppTheme.serif(18)),
                            const SizedBox(height: 4),
                            Text(
                              _address,
                              style: AppTheme.sans(12, color: AppColors.soft),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_accuracyMeters != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'GPS accuracy ±${_accuracyMeters!.round()}m · drag map to adjust pin',
                                  style: AppTheme.sans(10, color: AppColors.soft),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (saved.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final s in saved)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text('${s.emoji} ${s.name}', style: AppTheme.sans(12)),
                                onPressed: () => _selectSaved(s),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await KhadeRepository.instance.saveCurrentAsHome();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved as Home')),
                              );
                              setState(() {});
                            }
                          },
                          child: Text('Save as Home', style: AppTheme.sans(13, color: AppColors.matcha)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: _inServiceArea ? 'Confirm location' : 'Outside service area',
                          onPressed: _inServiceArea && !_geocoding ? _confirm : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
