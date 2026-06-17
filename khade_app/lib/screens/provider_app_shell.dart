import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'provider_calendar_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_dash_screen.dart';

/// Provider app shell — separate bottom nav from customer app.
class ProviderAppShell extends StatelessWidget {
  const ProviderAppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/provider-calendar')) return 1;
    if (location.startsWith('/provider-clients')) return 2;
    if (location.startsWith('/provider-inbox')) return 3;
    if (location.startsWith('/provider-more')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.ivory, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _item(context, 0, Icons.home_outlined, Icons.home, 'Home', '/provider-home'),
              _item(context, 1, Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar', '/provider-calendar'),
              _item(context, 2, Icons.groups_outlined, Icons.groups, 'Clients', '/provider-clients'),
              _item(context, 3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Inbox', '/provider-inbox'),
              _item(context, 4, Icons.more_horiz, Icons.more_horiz, 'More', '/provider-more'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, IconData icon, IconData activeIcon, String label, String path) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () => context.go(path),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.matcha : AppColors.navInactive),
              const SizedBox(height: 3),
              Text(label, style: AppTheme.sans(9, color: active ? AppColors.matcha : AppColors.navInactive)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderDashboardScreen();
  }
}

class ProviderCalendarScreen extends StatelessWidget {
  const ProviderCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProviderCalendarScreenView();
}

class ProviderEarningsShellScreen extends StatelessWidget {
  const ProviderEarningsShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderDashScreen();
  }
}

class ProviderProfileShellScreen extends StatelessWidget {
  const ProviderProfileShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            color: AppColors.matchaDeep,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Provider Profile', style: AppTheme.serif(24, color: AppColors.white)),
                Text('Manage services & salon settings', style: AppTheme.sans(12, color: Colors.white60)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.design_services_outlined, color: AppColors.matcha),
            title: const Text('My Services'),
            subtitle: const Text('Add prices & durations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/provider-services'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_outlined, color: AppColors.gold),
            title: const Text('Get Verified'),
            subtitle: const Text('Optional ✦ badge — build trust with clients'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppColors.matcha),
            title: const Text('Book as a customer'),
            subtitle: Text(
              AppConfig.isProviderApp ? 'Open the Khade customer app on your phone' : 'Switch to customer experience',
              style: AppTheme.sans(11, color: AppColors.soft),
            ),
            onTap: () {
              if (AppConfig.isProviderApp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Install the Khade app to book services as a customer')),
                );
              } else {
                context.go('/home');
              }
            },
          ),
        ],
      ),
    );
  }
}
