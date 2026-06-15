import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'provider_dash_screen.dart';

/// Provider app shell — separate bottom nav from customer app.
class ProviderAppShell extends StatelessWidget {
  const ProviderAppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/provider-calendar')) return 1;
    if (location.startsWith('/provider-earnings')) return 2;
    if (location.startsWith('/provider-profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _item(context, 0, Icons.today_outlined, Icons.today, 'Today', '/provider-home'),
              _item(context, 1, Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar', '/provider-calendar'),
              _item(context, 2, Icons.payments_outlined, Icons.payments, 'Earnings', '/provider-earnings'),
              _item(context, 3, Icons.person_outline, Icons.person, 'Profile', '/provider-profile'),
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
              Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.matchaDeep : AppColors.soft),
              const SizedBox(height: 3),
              Text(label, style: AppTheme.sans(9, color: active ? AppColors.matchaDeep : AppColors.soft)),
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
    return const ProviderDashScreen();
  }
}

class ProviderCalendarScreen extends StatelessWidget {
  const ProviderCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Availability', style: AppTheme.serif(20)), backgroundColor: AppColors.white, foregroundColor: AppColors.dark, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Set your working hours and block dates. Customers only see open slots.', style: AppTheme.sans(13, color: AppColors.mid)),
          const SizedBox(height: 16),
          for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
            Card(
              child: ListTile(
                title: Text(day, style: AppTheme.sans(13, weight: FontWeight.w500)),
                subtitle: Text('9:00 · 10:00 · 11:00 · 14:00 · 15:00 · 16:00', style: AppTheme.sans(11, color: AppColors.soft)),
                trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.matcha),
              ),
            ),
        ],
      ),
    );
  }
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
                Text('Manage services, CAC & salon settings', style: AppTheme.sans(12, color: Colors.white60)),
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
            leading: const Icon(Icons.business_center_outlined, color: AppColors.matcha),
            title: const Text('Business tools'),
            subtitle: const Text('CRM, staff, inventory, campaigns, Khade Capital'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/provider-business'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined, color: AppColors.matcha),
            title: const Text('Business verification'),
            subtitle: const Text('CAC number & documents'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppColors.matcha),
            title: const Text('Switch to Customer App'),
            onTap: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
