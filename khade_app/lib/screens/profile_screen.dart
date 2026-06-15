import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final user = KhadeRepository.instance.user;
        final initials = user?.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join() ?? 'AC';

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
              color: AppColors.matchaDeep,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 28, backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text(initials, style: AppTheme.sans(24, color: AppColors.white))),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Adaeze Chukwu', style: AppTheme.serif(22, color: AppColors.white)),
                            Text('${user?.city ?? 'Abuja'} · Member since ${user?.memberSince ?? 2024}', style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.6))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatBox(value: '${user?.bookingsCount ?? 0}', label: 'Bookings'),
                        const SizedBox(width: 10),
                        _StatBox(value: '${user?.savedProviders ?? 0}', label: 'Providers Saved'),
                        const SizedBox(width: 10),
                        _StatBox(value: user?.tier ?? 'Gold', label: 'Tier ✦'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      const ConnectionBanner(),
                      Container(
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            _MenuRow(icon: Icons.calendar_today_outlined, label: 'My Bookings', onTap: () => context.go('/appointments')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.favorite_outline, label: 'Saved Providers (${KhadeRepository.instance.savedProviderIds.length})', onTap: () => context.push('/saved-providers')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.account_balance_wallet_outlined, label: 'Khade Wallet · ${formatNaira(user?.walletBalance ?? 0)}', onTap: () => context.push('/wallet')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/settings')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push('/provider-dash'),
                        icon: const Icon(Icons.work_outline, size: 18),
                        label: const Text('Switch to Provider View'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.dark, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => context.push('/admin'),
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: const Text('Admin Dashboard'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.matchaDeep, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: AppTheme.sans(18, color: AppColors.white, weight: FontWeight.w500)),
          Text(label, style: AppTheme.sans(10, color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.matcha, size: 20),
      title: Text(label, style: AppTheme.sans(13)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.soft, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
