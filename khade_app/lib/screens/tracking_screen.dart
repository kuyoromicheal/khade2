import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/geo_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/khade_image.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.bookingId, this.bookingCode});

  final int? bookingId;
  final String? bookingCode;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _mapController = MapController();
  TrackingSnapshot? _snap;
  Timer? _timer;

  int? get _bookingId {
    final repo = KhadeRepository.instance;
    if (widget.bookingId != null) return widget.bookingId;
    if (widget.bookingCode != null) return repo.bookingByCode(widget.bookingCode!)?.id;
    return repo.bookings.where((b) => b.status == 'upcoming').firstOrNull?.id;
  }

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final id = _bookingId;
    if (id == null) return;
    final snap = await KhadeRepository.instance.fetchTracking(id);
    if (!mounted || snap == null) return;
    setState(() => _snap = snap);
    _mapController.move(LatLng(snap.providerLat, snap.providerLng), _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = KhadeRepository.instance;
    final booking = _bookingId != null ? repo.bookingById(_bookingId!) : null;
    final provider = booking != null ? repo.providerById(booking.providerId) : null;
    final snap = _snap;
    final dest = LatLng(snap?.destinationLat ?? defaultLat, snap?.destinationLng ?? defaultLng);
    final providerPos = LatLng(snap?.providerLat ?? provider?.latitude ?? 9.0833, snap?.providerLng ?? provider?.longitude ?? 7.495);
    final start = LatLng(snap != null ? snap.providerLat - (dest.latitude - snap.providerLat) * 0.3 : providerPos.latitude, snap != null ? snap.providerLng - (dest.longitude - snap.providerLng) * 0.3 : providerPos.longitude);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackHeader(title: 'Live Tracking', onBack: () => context.pop()),
          SizedBox(
            height: 280,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: providerPos,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.khade.khade_app',
                ),
                if (snap != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: [start, providerPos, dest], color: AppColors.matcha, strokeWidth: 4),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: dest,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.home, color: AppColors.red, size: 32),
                    ),
                    Marker(
                      point: providerPos,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.matcha, width: 3), color: Colors.white),
                        child: KhadeAvatar(url: snap?.providerAvatarUrl ?? provider?.avatarUrl, emoji: provider?.emoji ?? '💄', radius: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('On the way to you', style: AppTheme.serif(18)),
                            Text(booking?.serviceName ?? 'Your appointment', style: AppTheme.sans(12, color: AppColors.soft)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Text('${snap?.etaMinutes ?? 12} min', style: AppTheme.serif(20, color: AppColors.matcha)),
                              Text('${(snap?.distanceKm ?? 3.4).toStringAsFixed(1)} km', style: AppTheme.sans(10, color: AppColors.soft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(snap?.address ?? booking?.address ?? 'Maitama, Abuja', style: AppTheme.sans(11, color: AppColors.mid)),
                    const SizedBox(height: 16),
                    _TrackProgress(step: snap?.progressStep ?? 2),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.matcha.withValues(alpha: 0.2))),
                      child: Row(
                        children: [
                          KhadeAvatar(url: provider?.avatarUrl, emoji: provider?.emoji ?? booking?.providerEmoji, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(snap?.providerName ?? provider?.name ?? booking?.providerName ?? 'Provider', style: AppTheme.sans(13, weight: FontWeight.w500)),
                                Text('Live GPS · updates every 5s', style: AppTheme.sans(11, color: AppColors.matcha)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.matcha),
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat with provider'), backgroundColor: AppColors.matcha)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling provider...'), backgroundColor: AppColors.matcha)),
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: AppColors.cream),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/cancel?bookingId=${booking?.id ?? 1}&provider=${Uri.encodeComponent(provider?.name ?? booking?.providerName ?? 'Provider')}'),
                            icon: const Icon(Icons.close, size: 16, color: AppColors.redDark),
                            label: Text('Cancel', style: AppTheme.sans(12, color: AppColors.redDark)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: AppColors.redBg),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackProgress extends StatelessWidget {
  const _TrackProgress({required this.step});
  final int step;
  static const _steps = ['Booking\nConfirmed', 'Provider\nAccepted', 'On the\nWay', 'In\nSession', 'Done ✦'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(top: 12, left: 0, right: 0, child: Container(height: 2, color: AppColors.border)),
          Positioned(top: 12, left: 0, child: Container(width: MediaQuery.of(context).size.width * (step / 4) * 0.85, height: 2, color: AppColors.matcha)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _steps.length; i++)
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < step ? AppColors.matcha : i == step ? AppColors.matchaDeep : AppColors.border,
                        border: i == step ? Border.all(color: AppColors.matcha, width: 3) : null,
                      ),
                      child: i < step ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
                    ),
                    const SizedBox(height: 6),
                    Text(_steps[i], style: AppTheme.sans(9, color: AppColors.soft), textAlign: TextAlign.center),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
