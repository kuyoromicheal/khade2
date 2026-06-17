import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Live API on Render — used on real phones when no override is set.
  static const productionUrl = 'https://khade-api.onrender.com';

  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://khade-api.onrender.com`
  /// Local dev (emulator): `--dart-define=API_BASE_URL=http://10.0.2.2:3001`
  /// Local dev (phone on Wi‑Fi): `--dart-define=API_BASE_URL=http://192.168.x.x:3001`
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3001';
    // Physical devices cannot use 10.0.2.2 (emulator-only) or localhost.
    if (Platform.isAndroid || Platform.isIOS) return productionUrl;
    return 'http://localhost:3001';
  }

  static const defaultUserId = 1;

  /// Paystack public key — safe in client
  static const paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_35ce59d68cc897e975dbc6fde7b33b5837b576d4',
  );
}
