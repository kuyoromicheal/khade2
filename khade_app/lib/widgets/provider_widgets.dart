import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'khade_image.dart';

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.area,
    required this.price,
    required this.badge,
    this.gradient,
    this.imageUrl,
    this.onTap,
  });

  final String emoji;
  final String name;
  final String category;
  final String rating;
  final int reviews;
  final String distance;
  final String area;
  final String price;
  final String badge;
  final List<Color>? gradient;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  KhadeImage(url: imageUrl, fallbackUrl: imageUrl, gradient: gradient, emojiSize: 48),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                      child: Text(badge, style: AppTheme.sans(9, weight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.serif(17)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category, style: AppTheme.sans(11, color: AppColors.matcha)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text('$rating ($reviews reviews)', style: AppTheme.sans(11, color: AppColors.mid)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📍 $distance · $area', style: AppTheme.sans(10, color: AppColors.soft)),
                      Text(price, style: AppTheme.sans(12, weight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.emoji,
    required this.label,
    this.imageUrl,
    this.active = false,
    this.onTap,
  });

  final String emoji;
  final String label;
  final String? imageUrl;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? AppColors.matcha : AppColors.border, width: active ? 2 : 1),
                boxShadow: active ? [BoxShadow(color: AppColors.matcha.withValues(alpha: 0.25), blurRadius: 8)] : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? KhadeImage(url: imageUrl, fallbackUrl: imageUrl, emojiSize: 22)
                  : KhadeImage(fallbackUrl: imageUrl, emojiSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sans(10, color: active ? AppColors.matcha : AppColors.mid, weight: active ? FontWeight.w500 : FontWeight.w400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
