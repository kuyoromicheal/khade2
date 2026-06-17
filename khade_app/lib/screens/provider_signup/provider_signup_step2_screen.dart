import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/provider_onboard_constants.dart';
import '../../services/provider_onboarding_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/provider_onboard_layout.dart';

class ProviderSignupStep2Screen extends StatefulWidget {
  const ProviderSignupStep2Screen({super.key});

  @override
  State<ProviderSignupStep2Screen> createState() => _ProviderSignupStep2ScreenState();
}

class _ProviderSignupStep2ScreenState extends State<ProviderSignupStep2Screen> {
  final _brand = TextEditingController();
  final _website = TextEditingController();
  String? _primary;
  final _additional = <String>{};
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    final d = ProviderOnboardingController.instance.data;
    _brand.text = d.brandName ?? '';
    _website.text = d.website ?? '';
    _primary = d.primaryCategory;
    _additional.addAll(d.additionalCategories);
  }

  @override
  void dispose() {
    _brand.dispose();
    _website.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    ProviderOnboardingController.instance.update((d) => d.copyWith(
          brandName: _brand.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          primaryCategory: _primary,
          additionalCategories: _additional.toList(),
        ));
    context.go('/provider-signup/step3');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _showAll ? ProviderOnboardConstants.crafts : ProviderOnboardConstants.crafts.take(6).toList();

    return ProviderOnboardLayout(
      step: 2,
      onBack: () => context.pop(),
      onNext: _saveAndNext,
      nextDisabled: _brand.text.trim().isEmpty || _primary == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about your craft', style: ProviderOnboardStyles.stepTitle(context)),
          const SizedBox(height: 6),
          Text('This is how clients will find you on Khade', style: ProviderOnboardStyles.stepSub(context)),
          const SizedBox(height: 24),
          Text('Business or brand name', style: AppTheme.sans(12, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _brand, decoration: ProviderOnboardStyles.input('e.g. Zara Beauty or your own name'), onChanged: (_) => setState(() {})),
          Text('Your own name works perfectly too', style: AppTheme.sans(10, color: AppColors.soft)),
          const SizedBox(height: 16),
          Text('Website or Instagram (optional)', style: AppTheme.sans(12, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _website, decoration: ProviderOnboardStyles.input('@instagram or website'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 20),
          Text("What's your main craft?", style: AppTheme.sans(12, weight: FontWeight.w600)),
          Text('Pick one — you can add more below', style: AppTheme.sans(10, color: AppColors.soft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visible.map((cat) {
              final active = _primary == cat.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _primary = cat.id;
                  _additional.remove(cat.id);
                }),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: active ? AppColors.matcha : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: active ? AppColors.matcha : AppColors.border),
                        ),
                        child: Icon(cat.icon, color: active ? Colors.white : AppColors.matcha, size: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(cat.label, style: AppTheme.sans(10, color: active ? AppColors.matcha : AppColors.mid), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (!_showAll)
            TextButton(onPressed: () => setState(() => _showAll = true), child: const Text('+ Show more crafts')),
          if (_primary != null) ...[
            const SizedBox(height: 16),
            Text('Also offer? (optional)', style: AppTheme.sans(12, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProviderOnboardConstants.crafts.where((c) => c.id != _primary).map((cat) {
                final sel = _additional.contains(cat.id);
                return FilterChip(
                  label: Text('${cat.label} ${sel ? '×' : '+'}'),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    if (sel) _additional.remove(cat.id); else _additional.add(cat.id);
                  }),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
