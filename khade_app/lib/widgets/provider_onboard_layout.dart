import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ProviderOnboardLayout extends StatelessWidget {
  const ProviderOnboardLayout({
    super.key,
    required this.step,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Continue',
    this.nextDisabled = false,
    this.loading = false,
    this.totalSteps = 5,
  });

  final int step;
  final int totalSteps;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final bool nextDisabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: AppColors.matcha),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: step / 6,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.matcha,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$step/$totalSteps', style: AppTheme.sans(11, color: AppColors.soft)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: child,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (nextDisabled || loading) ? null : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.matcha,
                    disabledBackgroundColor: const Color(0xFFC8D8C8),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(nextLabel, style: AppTheme.sans(15, color: Colors.white, weight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderOnboardStyles {
  static TextStyle stepTitle(BuildContext context) => AppTheme.serif(28, color: AppColors.dark);
  static TextStyle stepSub(BuildContext context) => AppTheme.sans(13, color: AppColors.soft);
  static InputDecoration input(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}
