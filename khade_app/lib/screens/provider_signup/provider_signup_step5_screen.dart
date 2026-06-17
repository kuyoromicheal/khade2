import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/provider_onboarding_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Step 5 — You're in! Profile is live immediately.
class ProviderSignupStep5Screen extends StatefulWidget {
  const ProviderSignupStep5Screen({super.key});

  @override
  State<ProviderSignupStep5Screen> createState() => _ProviderSignupStep5ScreenState();
}

class _ProviderSignupStep5ScreenState extends State<ProviderSignupStep5Screen> {
  bool _submitting = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ProviderOnboardingController.instance.submitProfile();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _success = ok;
      _error = ok ? null : ProviderOnboardingController.instance.lastError;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitting) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.matcha)),
      );
    }

    if (!_success) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.redDark),
                const SizedBox(height: 16),
                Text('Something went wrong', style: AppTheme.serif(24)),
                const SizedBox(height: 8),
                Text(_error ?? 'Please try again', textAlign: TextAlign.center, style: AppTheme.sans(13, color: AppColors.soft)),
                const SizedBox(height: 24),
                FilledButton(onPressed: _submit, child: const Text('Try again')),
                TextButton(onPressed: () => context.go('/provider-signup/step4'), child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.matchaPale,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.matcha, width: 2),
                ),
                child: const Center(child: Text('🌿', style: TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 20),
              Text("You're in! ✦", textAlign: TextAlign.center, style: AppTheme.serif(34, color: AppColors.dark)),
              const SizedBox(height: 10),
              Text(
                'Your profile is live. Clients in your area can find and book you right now.',
                textAlign: TextAlign.center,
                style: AppTheme.sans(14, color: AppColors.soft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              _actionCard(
                icon: Icons.add_circle_outline,
                iconColor: AppColors.matcha,
                title: 'Add your services',
                sub: 'Set prices so clients can book',
                cta: 'Start →',
                onTap: () => context.go('/provider-services'),
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.image_outlined,
                iconColor: AppColors.gold,
                title: 'Upload your work',
                sub: 'Photos attract more clients',
                cta: 'Add →',
                onTap: () => context.go('/provider-more/portfolio'),
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.matcha,
                title: 'Set your availability',
                sub: 'When can clients book you?',
                cta: 'Set →',
                onTap: () => context.go('/provider-calendar'),
              ),
              const SizedBox(height: 28),
              TextButton.icon(
                onPressed: () => context.go('/provider-home'),
                icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.soft),
                label: Text('Go to my dashboard', style: AppTheme.sans(13, color: AppColors.soft)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String sub,
    required String cta,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.sans(13, weight: FontWeight.w500)),
                  Text(sub, style: AppTheme.sans(11, color: AppColors.soft)),
                ],
              ),
            ),
            Text(cta, style: AppTheme.sans(13, color: AppColors.matcha, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
