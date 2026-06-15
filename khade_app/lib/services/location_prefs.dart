import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class LocationPrefs {
  static const _deliveryKey = 'khade_delivery_point';
  static const _savedKey = 'khade_saved_addresses';

  static Future<DeliveryPoint?> loadDeliveryPoint() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deliveryKey);
    if (raw == null) return null;
    return DeliveryPoint.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveDeliveryPoint(DeliveryPoint point) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deliveryKey, jsonEncode(point.toJson()));
  }

  static Future<List<SavedAddress>> loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> upsertSavedAddress(SavedAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadSavedAddresses();
    final next = [...current.where((a) => a.id != address.id), address];
    await prefs.setString(_savedKey, jsonEncode(next.map((a) => a.toJson()).toList()));
  }
}
