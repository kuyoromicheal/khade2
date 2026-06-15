import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'khade_api.dart';

/// Uploads provider GPS every 5s while "on the way" is active.
class ProviderGpsService {
  ProviderGpsService._();
  static final ProviderGpsService instance = ProviderGpsService._();

  Timer? _timer;
  bool get isSharing => _timer != null;

  Future<bool> startSharing() async {
    if (_timer != null) return true;
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied || req == LocationPermission.deniedForever) return false;
    }
    await _upload();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _upload());
    return true;
  }

  void stopSharing() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _upload() async {
    try {
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await khadeApi.uploadProviderLocation(lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      debugPrint('GPS upload: $e');
    }
  }
}
