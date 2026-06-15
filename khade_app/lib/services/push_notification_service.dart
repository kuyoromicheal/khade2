import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'khade_api.dart';

/// Registers device token with backend for FCM push.
/// Wire firebase_messaging when google-services.json is added — until then uses a stable local ID.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _deviceIdKey = 'khade_device_push_id';

  Future<void> registerIfLoggedIn() async {
    if (!AuthService.instance.isLoggedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString(_deviceIdKey);
      token ??= 'khade_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_deviceIdKey, token);
      await khadeApi.registerFcmToken(
        userId: AuthService.instance.authUser!.id,
        token: token,
        platform: defaultTargetPlatform.name,
      );
    } catch (e) {
      debugPrint('Push registration: $e');
    }
  }
}
