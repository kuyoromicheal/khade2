import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Customer vs Provider app entry — like Fresha's separate business/client flows.
class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text('How will you\nuse Khade?', style: AppTheme.serif(36)),
              const SizedBox(height: 8),
              Text('Two apps, one platform — pick your experience', style: AppTheme.sans(13, color: AppColors.soft)),
              const SizedBox(height: 32),
              _RoleCard(
                emoji: '💆',
                title: 'I\'m a Customer',
                subtitle: 'Book beauty services at home or salon · ₦2,000 free on signup',
                color: AppColors.matcha,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                emoji: '💄',
                title: 'I\'m a Provider',
                subtitle: 'Manage bookings, earnings & clients · CAC verification',
                color: AppColors.matchaDeep,
                onTap: () => context.push('/register?role=provider'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text('Continue browsing as guest →', style: AppTheme.sans(12, color: AppColors.matcha)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.onTap});
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.sans(15, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTheme.sans(11, color: AppColors.soft)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
