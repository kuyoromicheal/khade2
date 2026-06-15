import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Bronze · Silver · Gold tier badge for customers and providers.
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.compact = false});
  final String tier;
  final bool compact;

  static const _colors = {
    'Bronze': Color(0xFFCD7F32),
    'Silver': Color(0xFF9E9E9E),
    'Gold': Color(0xFFC9A84C),
  };

  @override
  Widget build(BuildContext context) {
    final t = tier.isEmpty ? 'Bronze' : tier;
    final color = _colors[t] ?? AppColors.gold;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(t, style: AppTheme.sans(compact ? 9 : 10, color: color, weight: FontWeight.w600)),
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
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('₦2,000 is on us!', style: AppTheme.serif(24, color: AppColors.matchaDeep)),
          const SizedBox(height: 8),
          Text('Welcome to Khade. Your wallet has been credited — book your first glam today.', style: AppTheme.sans(13, color: AppColors.mid), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, minimumSize: const Size(double.infinity, 44)),
            child: const Text('Start exploring'),
          ),
        ],
      ),
    ),
  );
}
