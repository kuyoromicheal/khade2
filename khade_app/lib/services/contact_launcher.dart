import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer / SMS / WhatsApp — same pattern as Uber, Glovo, inDrive.
class ContactLauncher {
  ContactLauncher._();

  static String normalizePhone(String phone) {
    var p = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('0')) return '+234${p.substring(1)}';
    if (p.startsWith('234')) return '+$p';
    return '+234$p';
  }

  static String whatsAppDigits(String phone) => normalizePhone(phone).replaceFirst('+', '');

  static Future<bool> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: normalizePhone(phone));
    return _open(uri);
  }

  static Future<bool> sms(String phone, {String? body}) async {
    final normalized = normalizePhone(phone);
    final uri = body != null && body.isNotEmpty
        ? Uri(scheme: 'sms', path: normalized, queryParameters: {'body': body})
        : Uri(scheme: 'sms', path: normalized);
    return _open(uri, external: true);
  }

  static Future<bool> whatsApp(String phone, {String? message}) async {
    final digits = whatsAppDigits(phone);
    final uri = message != null && message.isNotEmpty
        ? Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}')
        : Uri.parse('https://wa.me/$digits');
    return _open(uri, external: true);
  }

  static Future<bool> _open(Uri uri, {bool external = false}) async {
    try {
      final mode = external ? LaunchMode.externalApplication : LaunchMode.platformDefault;
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: mode);
      }
      return launchUrl(uri, mode: mode);
    } catch (e) {
      debugPrint('ContactLauncher: $e');
      return false;
    }
  }

  static String trackingMessage({
    required String providerName,
    required String bookingCode,
    String? customerName,
    String? address,
    int? etaMinutes,
  }) {
    final who = customerName != null && customerName.isNotEmpty ? customerName : 'your Khade customer';
    final buf = StringBuffer('Hi $providerName, this is $who regarding booking $bookingCode');
    if (address != null && address.isNotEmpty) buf.write(' at $address');
    if (etaMinutes != null) buf.write('. ETA ~$etaMinutes min');
    buf.write('. Are you on your way?');
    return buf.toString();
  }
}
