import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const kImageHeaders = {'Accept': 'image/*', 'User-Agent': 'KhadeApp/1.0'};

const kBeautyPhotoFallback =
    'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop';

/// Network image with real-photo fallback chain (no infinite spinners).
class KhadeImage extends StatelessWidget {
  const KhadeImage({
    super.key,
    this.url,
    this.emoji,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.gradient,
    this.emojiSize = 48,
  });

  final String? url;
  final String? emoji;
  final String? fallbackUrl;
  final BoxFit fit;
  final List<Color>? gradient;
  final double emojiSize;

  String? get _primary => (url != null && url!.isNotEmpty) ? url : null;
  String get _secondary => (fallbackUrl != null && fallbackUrl!.isNotEmpty && fallbackUrl != url) ? fallbackUrl! : kBeautyPhotoFallback;

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? [AppColors.matchaPale, const Color(0xFFD4E6D8)];
    final primary = _primary;

    if (primary != null) {
      return Image.network(
        primary,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        headers: kImageHeaders,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) => progress == null ? child : _loading(colors),
        errorBuilder: (_, __, ___) => _networkImage(_secondary, fit, colors, isFinalFallback: false),
      );
    }
    return _networkImage(_secondary, fit, colors, isFinalFallback: true);
  }

  Widget _networkImage(String src, BoxFit fit, List<Color> colors, {required bool isFinalFallback}) {
    return Image.network(
      src,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      headers: kImageHeaders,
      gaplessPlayback: true,
      loadingBuilder: (_, child, progress) => progress == null ? child : _loading(colors),
      errorBuilder: (_, __, ___) => isFinalFallback ? _placeholder(colors) : _networkImage(kBeautyPhotoFallback, fit, colors, isFinalFallback: true),
    );
  }

  Widget _loading(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      alignment: Alignment.center,
      child: const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.matcha)),
    );
  }

  Widget _placeholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      alignment: Alignment.center,
      child: Icon(Icons.spa_outlined, size: emojiSize, color: AppColors.matcha.withValues(alpha: 0.55)),
    );
  }
}

/// Circular avatar from real photo URLs.
class KhadeAvatar extends StatelessWidget {
  const KhadeAvatar({super.key, this.url, this.emoji, this.fallbackUrl, this.radius = 18});

  final String? url;
  final String? emoji;
  final String? fallbackUrl;
  final double radius;

  String get _photoUrl {
    if (url != null && url!.isNotEmpty) return url!;
    if (fallbackUrl != null && fallbackUrl!.isNotEmpty) return fallbackUrl!;
    return kBeautyPhotoFallback;
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.matchaPale,
      child: ClipOval(
        child: Image.network(
          _photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          headers: kImageHeaders,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius, color: AppColors.matcha),
        ),
      ),
    );
  }
}
