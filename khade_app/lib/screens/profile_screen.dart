import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/tier_badge.dart';
import '../widgets/tier_progress.dart';
import '../widgets/connection_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    KhadeRepository.instance.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([KhadeRepository.instance, AuthService.instance]),
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final auth = AuthService.instance;
        final user = auth.authUser ?? repo.user;
        final initials = user?.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join() ?? 'G';
        final unread = repo.unreadMessagesCount;

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
                            Text(user?.name ?? 'Guest', style: AppTheme.serif(22, color: AppColors.white)),
                            Text(
                              auth.isLoggedIn
                                  ? '${user?.city ?? 'Abuja'} · Member since ${user?.memberSince ?? 2024}'
                                  : 'Browse as guest — sign in to book & save',
                              style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.6)),
                            ),
                            if (auth.isLoggedIn) ...[const SizedBox(height: 6), TierBadge(tier: user?.tier ?? 'Bronze', compact: true)],
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
                        _StatBox(value: user?.tier ?? 'Bronze', label: 'Tier'),
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
                      if (auth.isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TierProgress(tier: user?.tier ?? 'Bronze', totalBookings: user?.bookingsCount ?? 0),
                        ),
                      Container(
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            _MenuRow(icon: Icons.person_outline, label: 'Profile & Personal Info', onTap: () => context.push('/settings')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.chat_bubble_outline, label: 'Messages', badge: unread > 0 ? unread : null, onTap: () => context.push('/messages')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.favorite_outline, label: 'Favourites (${repo.savedProviderIds.length})', onTap: () => context.push('/saved-providers')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.calendar_today_outlined, label: 'My Appointments', onTap: () => context.go('/appointments')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.account_balance_wallet_outlined, label: 'Khade Wallet · ${formatNaira(user?.walletBalance ?? 0)}', onTap: () => context.push('/wallet')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),
                            const Divider(height: 1, color: AppColors.border),
                            _MenuRow(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/settings')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!auth.isLoggedIn)
                        FilledButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Sign In / Create Account'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, padding: const EdgeInsets.symmetric(vertical: 14)),
                        )
                      else ...[
                        if (user?.isProvider == true)
                          FilledButton.icon(
                            onPressed: () => context.push('/provider-dash'),
                            icon: const Icon(Icons.work_outline, size: 18),
                            label: const Text('Provider Dashboard'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.dark, padding: const EdgeInsets.symmetric(vertical: 14)),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => context.push('/provider-signup'),
                            icon: const Icon(Icons.storefront_outlined, size: 18),
                            label: const Text('Become a Provider'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.dark, padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        if (user?.isAdmin == true) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => context.push('/admin'),
                            icon: const Icon(Icons.shield_outlined, size: 18),
                            label: const Text('Admin Dashboard'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.matchaDeep, padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await AuthService.instance.logout();
                            if (context.mounted) context.go('/splash');
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Log out'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.redDark, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ],
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
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: AppTheme.serif(18, color: AppColors.white)),
          Text(label, style: AppTheme.sans(10, color: Colors.white.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.badge, this.onTap});
  final IconData icon;
  final String label;
  final int? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.matcha, size: 22),
      title: Text(label, style: AppTheme.sans(14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.matcha, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: AppTheme.sans(10, color: Colors.white, weight: FontWeight.w600)),
            ),
          const Icon(Icons.chevron_right, color: AppColors.soft),
        ],
      ),
      onTap: onTap,
    );
  }
}
