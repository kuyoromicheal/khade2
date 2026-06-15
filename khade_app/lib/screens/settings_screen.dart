import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _promos = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackHeader(title: 'Settings', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section('Notifications', [
                  _switch('Push notifications', _notifications, (v) => setState(() => _notifications = v)),
                  _switch('Promotions & offers', _promos, (v) => setState(() => _promos = v)),
                ]),
                _section('Appearance', [
                  _switch('Dark mode', _darkMode, (v) => setState(() => _darkMode = v)),
                ]),
                _section('Account', [
                  _tile(Icons.person_outline, 'Edit Profile', () => _snack('Profile updated (mock)')),
                  _tile(Icons.lock_outline, 'Change Password', () => _snack('Password changed (mock)')),
                  _tile(Icons.help_outline, 'Help & Support', () => _snack('Support: hello@khade.ng')),
                  _tile(Icons.logout, 'Log Out', () => context.go('/splash'), danger: true),
                ]),
                const SizedBox(height: 20),
                Text('Khade v1.0.0 · Abuja, Nigeria', style: AppTheme.sans(11, color: AppColors.soft), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.matcha));
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: AppTheme.sans(13)),
      value: value,
      activeThumbColor: AppColors.matcha,
      onChanged: onChanged,
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.redDark : AppColors.matcha, size: 20),
      title: Text(label, style: AppTheme.sans(13, color: danger ? AppColors.redDark : AppColors.dark)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.soft, size: 20),
      onTap: onTap,
    );
  }
}
