import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _slides = [
    ('✦', 'Beauty on demand', 'Book barbing, nails, makeup, spa & more — delivered to your door in Abuja.'),
    ('📍', 'Track like Glovo', 'Live GPS tracking, call or message your provider, pay with Paystack or cash.'),
    ('💄', 'Discover & book', 'Watch provider reels, save favourites, earn Gold rewards — no forced signup to browse.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.matchaDeep,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip', style: AppTheme.sans(13, color: AppColors.cream.withValues(alpha: 0.7))),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.$1, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 24),
                        Text(s.$2, style: AppTheme.serif(32, color: AppColors.cream), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(s.$3, style: AppTheme.sans(14, color: AppColors.cream.withValues(alpha: 0.65)), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => Container(
                width: i == _index ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.gold : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _index == _slides.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_index < _slides.length - 1) {
                        _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        _finish();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text('Already have an account? Sign in', style: AppTheme.sans(12, color: AppColors.gold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await AuthService.instance.completeOnboarding();
    if (mounted) context.go('/role-picker');
  }
}
