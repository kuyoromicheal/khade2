import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Provider registration entry — Salon / Mobile / Solo Pro.
class ProviderSplashScreen extends StatelessWidget {
  const ProviderSplashScreen({super.key});

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
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: 8),
              Text('Join Khade\nas a Provider', style: AppTheme.serif(32)),
              const SizedBox(height: 8),
              Text('Pick how you work — we take 10%, not 20%', style: AppTheme.sans(13, color: AppColors.soft)),
              const SizedBox(height: 28),
              _PathCard(
                emoji: '🏪',
                title: 'I have a Salon or Studio',
                subtitle: 'Fixed location, clients come to me',
                button: 'Register as Salon',
                onTap: () => context.push('/provider-onboarding?type=salon'),
              ),
              const SizedBox(height: 12),
              _PathCard(
                emoji: '🚗',
                title: "I'm Mobile",
                subtitle: 'I travel to my clients',
                button: 'Register as Mobile Pro',
                onTap: () => context.push('/provider-onboarding?type=mobile'),
              ),
              const SizedBox(height: 12),
              _PathCard(
                emoji: '⚡',
                title: "I'm a Solo Pro",
                subtitle: 'Skilled, flexible, no fixed space',
                button: 'Register as Solo Pro',
                highlight: true,
                onTap: () => context.push('/provider-onboarding?type=solo_pro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
    this.highlight = false,
  });

  final String emoji, title, subtitle, button;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: highlight ? AppColors.matcha : AppColors.border, width: highlight ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(title, style: AppTheme.sans(15, weight: FontWeight.w600)),
              Text(subtitle, style: AppTheme.sans(12, color: AppColors.soft)),
              const SizedBox(height: 12),
              Text('$button →', style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
