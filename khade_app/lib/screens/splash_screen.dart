import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../config/app_mode.dart';
import '../services/khade_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _wordFade;
  late final Animation<double> _lineWidth;
  late final Animation<double> _tagFade;
  late final Animation<double> _subFade;
  late final Animation<double> _loadFade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    _markFade = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    _markScale = Tween<double>(begin: 0.72, end: 1).animate(CurvedAnimation(parent: _enter, curve: const Interval(0, 0.45, curve: Curves.easeOutBack)));
    _wordFade = CurvedAnimation(parent: _enter, curve: const Interval(0.22, 0.55, curve: Curves.easeOut));
    _lineWidth = CurvedAnimation(parent: _enter, curve: const Interval(0.38, 0.72, curve: Curves.easeInOutCubic));
    _tagFade = CurvedAnimation(parent: _enter, curve: const Interval(0.5, 0.78, curve: Curves.easeOut));
    _subFade = CurvedAnimation(parent: _enter, curve: const Interval(0.58, 0.88, curve: Curves.easeOut));
    _loadFade = CurvedAnimation(parent: _enter, curve: const Interval(0.72, 1, curve: Curves.easeOut));

    _enter.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2600)),
      KhadeRepository.instance.initialize(),
    ]);
    if (!mounted) return;
    final auth = AuthService.instance;
    if (AppConfig.isProviderApp) {
      if (!auth.onboardingDone) await auth.completeOnboarding();
      if (!mounted) return;
      if (auth.isLoggedIn && auth.authUser?.isProvider == true) {
        context.go('/provider-home');
      } else {
        context.go('/provider-signup');
      }
      return;
    }
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
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String get _subtitle => AppConfig.isProviderApp
      ? 'Run your calendar, clients & earnings\nin one elegant workspace'
      : 'Luxury beauty & wellness services\ndelivered across Abuja';

  @override
  Widget build(BuildContext context) {
    final isPro = AppConfig.isProviderApp;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF152A1F), AppColors.matchaDeep, Color(0xFF2A4D38)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(right: -10, top: -10, child: _DecoCircle(size: 100, opacity: 0.05)),
              Positioned(
                bottom: -60,
                right: -60,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => _DecoCircle(size: 200, opacity: 0.035 + _pulse.value * 0.02),
                ),
              ),
              Positioned(
                bottom: 40,
                left: -40,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => _DecoCircle(size: 140, color: AppColors.gold.withValues(alpha: 0.06 + _pulse.value * 0.04)),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.12,
                left: -30,
                child: _DecoCircle(size: 80, color: AppColors.matchaLight.withValues(alpha: 0.06)),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _markFade,
                        child: ScaleTransition(
                          scale: _markScale,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isPro ? '✦' : '✦',
                              style: TextStyle(
                                fontSize: 34,
                                color: AppColors.gold.withValues(alpha: 0.95),
                                shadows: [Shadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 12)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _wordFade,
                        child: Text(
                          isPro ? 'khade pro' : 'khade',
                          style: AppTheme.serif(52, weight: FontWeight.w300, color: AppColors.cream).copyWith(
                            letterSpacing: isPro ? 4 : 8,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedBuilder(
                        animation: _lineWidth,
                        builder: (_, __) => Container(
                          width: 48 * _lineWidth.value,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.gold.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeTransition(
                        opacity: _tagFade,
                        child: Text(
                          AppConfig.tagline.toUpperCase(),
                          style: AppTheme.sans(11, color: AppColors.cream.withValues(alpha: 0.55)).copyWith(
                            letterSpacing: 3.2,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _subFade,
                        child: Text(
                          _subtitle,
                          style: AppTheme.sans(12, color: AppColors.cream.withValues(alpha: 0.42)).copyWith(height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _loadFade,
                        child: Column(
                          children: [
                            const _LoadingBar(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) => _LoadingDot(index: i, pulse: _pulse)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Abuja · Nigeria',
                              style: AppTheme.sans(10, color: AppColors.cream.withValues(alpha: 0.28)).copyWith(letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, this.opacity = 1, this.color});
  final double size;
  final double opacity;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return CustomPaint(
            painter: _BarPainter(progress: _c.value),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(1)), track);

    final sweep = size.width * 0.35;
    final start = (size.width + sweep) * progress - sweep;
    final grad = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, AppColors.gold, Colors.transparent],
      ).createShader(Rect.fromLTWH(start, 0, sweep, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(math.max(0, start), 0, math.min(sweep, size.width - start), size.height), const Radius.circular(1)),
      grad,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.progress != progress;
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot({required this.index, required this.pulse});
  final int index;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final phase = (pulse.value + index * 0.33) % 1.0;
    final active = phase < 0.45;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.18),
        boxShadow: active ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.45), blurRadius: 6)] : null,
      ),
    );
  }
}
