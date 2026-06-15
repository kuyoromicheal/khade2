import 'dart:io';
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Override at build time: flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3001
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    if (kIsWeb) return 'http://localhost:3001';

    // Android emulator maps host machine localhost to 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3001';

    return 'http://localhost:3001';
  }

  static const defaultUserId = 1;

  /// Paystack public key — safe in client
  static const paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_35ce59d68cc897e975dbc6fde7b33b5837b576d4',
  );
}
