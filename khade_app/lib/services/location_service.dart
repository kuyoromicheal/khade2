import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/geo_utils.dart';

class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.address,
    required this.fromGps,
    this.accuracyMeters,
    this.pinAdjusted = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final String address;
  final bool fromGps;
  final double? accuracyMeters;
  final bool pinAdjusted;

  bool get inServiceArea => isInAbujaServiceArea(latitude, longitude);

  DeliveryPoint toDeliveryPoint({bool pinAdjusted = false}) => DeliveryPoint(
        latitude: latitude,
        longitude: longitude,
        label: label,
        address: address,
        accuracyMeters: accuracyMeters,
        pinAdjusted: pinAdjusted,
      );
}

class GeocodeResult {
  const GeocodeResult({required this.label, required this.address});
  final String label;
  final String address;
}

class DeliveryPoint {
  const DeliveryPoint({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.address,
    this.accuracyMeters,
    this.pinAdjusted = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final String address;
  final double? accuracyMeters;
  final bool pinAdjusted;

  bool get inServiceArea => isInAbujaServiceArea(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        'address': address,
        'accuracyMeters': accuracyMeters,
        'pinAdjusted': pinAdjusted,
      };

  factory DeliveryPoint.fromJson(Map<String, dynamic> j) => DeliveryPoint(
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        label: j['label'] as String,
        address: j['address'] as String,
        accuracyMeters: (j['accuracyMeters'] as num?)?.toDouble(),
        pinAdjusted: j['pinAdjusted'] as bool? ?? false,
      );
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.name,
    required this.emoji,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.address,
  });

  final String id;
  final String name;
  final String emoji;
  final double latitude;
  final double longitude;
  final String label;
  final String address;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        'address': address,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        label: j['label'] as String,
        address: j['address'] as String,
      );
}

/// Device GPS + reverse geocode (Glovo step 1–2).
Future<UserLocation?> resolveUserLocation() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final geo = await reverseGeocodeAt(pos.latitude, pos.longitude);

    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      label: geo.label,
      address: geo.address,
      fromGps: true,
      accuracyMeters: pos.accuracy,
    );
  } catch (_) {
    return null;
  }
}

Future<GeocodeResult> reverseGeocodeAt(double lat, double lng) async {
  final label = await _reverseGeocodeLabel(lat, lng);
  final address = await _reverseGeocodeAddress(lat, lng);
  return GeocodeResult(label: label, address: address);
}

Future<String> _reverseGeocodeLabel(double lat, double lng) async {
  try {
    final marks = await placemarkFromCoordinates(lat, lng);
    if (marks.isEmpty) return _coordLabel(lat, lng);
    final p = marks.first;
    final area = p.subLocality?.trim().isNotEmpty == true
        ? p.subLocality!.trim()
        : (p.locality?.trim().isNotEmpty == true ? p.locality!.trim() : p.subAdministrativeArea?.trim());
    if (area != null && area.isNotEmpty) {
      final city = p.locality?.trim();
      if (city != null && city.isNotEmpty && city.toLowerCase() != area.toLowerCase()) {
        return '$area, $city';
      }
      return '$area, Abuja';
    }
  } catch (_) {}
  return _coordLabel(lat, lng);
}

Future<String> _reverseGeocodeAddress(double lat, double lng) async {
  try {
    final marks = await placemarkFromCoordinates(lat, lng);
    if (marks.isEmpty) return _coordAddress(lat, lng);
    final p = marks.first;
    final parts = <String>[
      if (p.street?.trim().isNotEmpty == true) p.street!.trim(),
      if (p.subLocality?.trim().isNotEmpty == true) p.subLocality!.trim(),
      if (p.locality?.trim().isNotEmpty == true) p.locality!.trim(),
      if (p.administrativeArea?.trim().isNotEmpty == true) p.administrativeArea!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
  } catch (_) {}
  return _coordAddress(lat, lng);
}

String _coordLabel(double lat, double lng) =>
    '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)} · Abuja';

String _coordAddress(double lat, double lng) =>
    'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

DeliveryPoint get defaultDeliveryPoint => const DeliveryPoint(
      latitude: defaultLat,
      longitude: defaultLng,
      label: 'Maitama, Abuja',
      address: 'Maitama, Abuja',
    );
