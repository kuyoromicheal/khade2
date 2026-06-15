import '../config/api_config.dart';

/// Resolves relative `/media/...` paths against the API base URL.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('assets/')) {
    return url;
  }
  if (url.startsWith('/')) return '${ApiConfig.baseUrl}$url';
  return url;
}
