import 'package:flutter/material.dart';
import '../constants/tiers.dart';
import '../theme/app_theme.dart';

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.compact = false});
  final String tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = KhadeTiers.data(KhadeTiers.fromString(tier));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.icon, style: TextStyle(fontSize: compact ? 11 : 13)),
          const SizedBox(width: 4),
          Text(data.name, style: AppTheme.sans(compact ? 9 : 10, color: data.textColor, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

void showWelcomeBonusDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('₦2,000 is on us!', style: AppTheme.serif(24)),
          const SizedBox(height: 8),
          Text('Welcome to Khade. Your wallet has been credited — book your first glam today.', style: AppTheme.sans(13), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Start exploring')),
        ],
      ),
    ),
  );
}
