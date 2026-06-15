import 'dart:math' as math;

/// Abuja default (Maitama) when GPS unavailable.
const defaultLat = 9.0765;
const defaultLng = 7.4898;

/// Approximate Abuja FCT service boundary.
const abujaMinLat = 8.95;
const abujaMaxLat = 9.20;
const abujaMinLng = 7.30;
const abujaMaxLng = 7.60;

bool isInAbujaServiceArea(double lat, double lng) =>
    lat >= abujaMinLat && lat <= abujaMaxLat && lng >= abujaMinLng && lng <= abujaMaxLng;

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Rough ETA for Abuja road travel (~4 min/km).
int etaFromDistanceKm(double km) => math.max(1, (km * 4).round());

double _rad(double deg) => deg * math.pi / 180;
