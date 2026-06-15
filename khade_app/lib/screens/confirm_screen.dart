import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({
    super.key,
    this.code = 'KHD-2847',
    this.total = 13200,
    this.service = 'Full Glam Makeup',
    this.provider = 'Zara Beauty Studio',
    this.date = 'Tue Jun 17 · 10:30 AM',
  });

  final String code;
  final int total;
  final String service;
  final String provider;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.matchaPale, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.matcha),
              ),
              const SizedBox(height: 20),
              Text('Booking Confirmed!', style: AppTheme.serif(28)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Your appointment with\n',
                  style: AppTheme.sans(13, color: AppColors.soft).copyWith(height: 1.6),
                  children: [
                    TextSpan(text: provider, style: AppTheme.sans(13, color: AppColors.dark, weight: FontWeight.w600)),
                    TextSpan(text: '\nis set for $date'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _detail('Booking ID', code),
                    const SizedBox(height: 8),
                    _detail('Service', service),
                    const SizedBox(height: 8),
                    _detail('Amount Paid', formatNaira(total), valueColor: AppColors.matcha),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Track Appointment →', onPressed: () => context.push('/tracking?code=$code')),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Back to Home', style: AppTheme.sans(14, color: AppColors.mid)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans(12, color: AppColors.mid)),
        Text(value, style: AppTheme.sans(12, color: valueColor ?? AppColors.dark, weight: FontWeight.w500)),
      ],
    );
  }
}
