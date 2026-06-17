import 'package:flutter/material.dart';
import '../constants/tiers.dart';
import '../utils/tier_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TierProgress extends StatelessWidget {
  const TierProgress({super.key, required this.tier, required this.totalBookings, this.compact = false});
  final String tier;
  final int totalBookings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = KhadeTiers.fromString(tier);
    final data = KhadeTiers.data(current);
    final left = TierUtils.bookingsToNextTier(totalBookings);

    if (current == TierName.gold) {
      return Row(
        children: [
          Text(data.icon, style: TextStyle(fontSize: compact ? 14 : 18)),
          const SizedBox(width: 6),
          Text('${data.name} · $totalBookings bookings', style: AppTheme.sans(compact ? 11 : 12, color: data.textColor, weight: FontWeight.w600)),
        ],
      );
    }

    final next = current == TierName.bronze ? 'Silver' : 'Gold';
    final progress = TierUtils.tierProgress(totalBookings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(data.icon, style: TextStyle(fontSize: compact ? 14 : 16)),
            const SizedBox(width: 6),
            Text('${data.name} · $totalBookings bookings', style: AppTheme.sans(compact ? 11 : 12, color: data.textColor, weight: FontWeight.w600)),
            const Spacer(),
            Text('$left to $next', style: AppTheme.sans(10, color: AppColors.soft)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AppColors.border, color: data.color),
        ),
      ],
    );
  }
}
