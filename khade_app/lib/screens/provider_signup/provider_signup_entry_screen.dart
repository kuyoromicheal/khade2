import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Step 0 — dark matcha entry: Google or Email.
class ProviderSignupEntryScreen extends StatelessWidget {
  const ProviderSignupEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.matchaDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              const Text('🌿', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('khade', style: AppTheme.serif(48, color: AppColors.white).copyWith(letterSpacing: 6, fontWeight: FontWeight.w300)),
              Text('for professionals', style: AppTheme.sans(11, color: Colors.white54).copyWith(letterSpacing: 3)),
              const SizedBox(height: 32),
              Text(
                'Join 2,400+ beauty pros\nalready earning on Khade',
                textAlign: TextAlign.center,
                style: AppTheme.sans(13, color: Colors.white60),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google sign-in coming soon — use email for now')),
                    );
                  },
                  icon: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  label: const Text('Continue with Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white24)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: AppTheme.sans(12, color: Colors.white38))),
                  Expanded(child: Container(height: 1, color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/provider-signup/step1'),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Continue with Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: Colors.white38, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.push('/login?role=provider'),
                child: Text.rich(
                  TextSpan(
                    text: 'Already on Khade? ',
                    style: AppTheme.sans(13, color: Colors.white54),
                    children: [TextSpan(text: 'Sign in', style: AppTheme.sans(13, color: AppColors.gold))],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
