import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await KhadeRepository.instance.initialize();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.matchaDeep,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('khade', style: AppTheme.serif(52, weight: FontWeight.w300, color: AppColors.cream).copyWith(letterSpacing: 6)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 16),
              Text('Loading your beauty world...', style: AppTheme.sans(12, color: AppColors.cream.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
