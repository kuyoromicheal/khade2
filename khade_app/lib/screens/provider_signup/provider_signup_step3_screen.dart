import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/provider_onboarding_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/provider_onboard_layout.dart';

class ProviderSignupStep3Screen extends StatefulWidget {
  const ProviderSignupStep3Screen({super.key});

  @override
  State<ProviderSignupStep3Screen> createState() => _ProviderSignupStep3ScreenState();
}

class _ProviderSignupStep3ScreenState extends State<ProviderSignupStep3Screen> {
  String? _crew;

  static const _options = [
    _CrewOption('solo', 'Just me', 'Solo Pro — I work alone', Icons.person_outline, 'solo_pro'),
    _CrewOption('small', 'Small crew', '2–5 people · A tight-knit team', Icons.groups_outlined, 'studio'),
    _CrewOption('growing', 'Growing squad', '6–10 · Multiple specialists', Icons.group_outlined, 'studio'),
    _CrewOption('full', 'Full studio', '11+ · Salon or spa with full staff', Icons.store_outlined, 'salon'),
  ];

  @override
  void initState() {
    super.initState();
    _crew = ProviderOnboardingController.instance.data.crewSize;
  }

  @override
  Widget build(BuildContext context) {
    return ProviderOnboardLayout(
      step: 3,
      onBack: () => context.pop(),
      onNext: () {
        final opt = _options.firstWhere((o) => o.id == _crew);
        ProviderOnboardingController.instance.update((d) => d.copyWith(crewSize: _crew, providerSubtype: opt.subtype));
        context.go('/provider-signup/step4');
      },
      nextDisabled: _crew == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How big is your crew?', style: ProviderOnboardStyles.stepTitle(context)),
          const SizedBox(height: 6),
          Text("We'll set things up just right for you", style: ProviderOnboardStyles.stepSub(context)),
          const SizedBox(height: 20),
          for (final opt in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _crew = opt.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _crew == opt.id ? AppColors.matchaPale : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _crew == opt.id ? AppColors.matcha : AppColors.border, width: _crew == opt.id ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _crew == opt.id ? AppColors.matcha : AppColors.matchaPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(opt.icon, color: _crew == opt.id ? Colors.white : AppColors.matcha),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.title, style: AppTheme.sans(14, weight: FontWeight.w600, color: _crew == opt.id ? AppColors.matcha : AppColors.dark)),
                            Text(opt.subtitle, style: AppTheme.sans(11, color: AppColors.soft)),
                          ],
                        ),
                      ),
                      _radio(_crew == opt.id),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _radio(bool on) => Container(
        width: 20, height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? AppColors.matcha : AppColors.border, width: 2)),
        child: on ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.matcha))) : null,
      );
}

class _CrewOption {
  const _CrewOption(this.id, this.title, this.subtitle, this.icon, this.subtype);
  final String id, title, subtitle, subtype;
  final IconData icon;
}
