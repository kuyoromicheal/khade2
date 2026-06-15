import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.88, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    await KhadeRepository.instance.initialize();
    if (!mounted) return;
    final auth = AuthService.instance;
    if (!auth.onboardingDone) {
      context.go('/onboarding');
    } else if (auth.isLoggedIn && auth.authUser?.isProvider == true) {
      context.go('/provider-home');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a3d28), AppColors.matchaDeep, Color(0xFF2d5c3f)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -80, right: -60, child: _orb(180, AppColors.gold.withValues(alpha: 0.08))),
              Positioned(bottom: -40, left: -50, child: _orb(140, AppColors.matcha.withValues(alpha: 0.15))),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 2),
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            alignment: Alignment.center,
                            child: Text('K', style: AppTheme.serif(36, color: AppColors.gold, weight: FontWeight.w400)),
                          ),
                          const SizedBox(height: 20),
                          Text('khade', style: AppTheme.serif(48, weight: FontWeight.w300, color: AppColors.cream).copyWith(letterSpacing: 8)),
                          const SizedBox(height: 8),
                          Text('your beauty, on demand', style: AppTheme.sans(12, color: AppColors.gold).copyWith(letterSpacing: 2)),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 12),
                          Text('Abuja · Nigeria', style: AppTheme.sans(10, color: AppColors.cream.withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
