import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/confirm_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/cancel_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/provider_dash_screen.dart';
import '../screens/review_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/saved_providers_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/provider_onboarding_screen.dart';
import '../screens/role_picker_screen.dart';
import '../screens/provider_app_shell.dart';
import '../screens/provider_services_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/group_booking_screen.dart';
import '../screens/provider_business_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter() => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/role-picker', builder: (_, __) => const RolePickerScreen()),
        GoRoute(path: '/login', builder: (_, state) => LoginScreen(roleHint: state.uri.queryParameters['role'])),
        GoRoute(path: '/register', builder: (_, state) => RegisterScreen(initialRole: state.uri.queryParameters['role'] ?? 'customer')),
        GoRoute(path: '/provider-onboarding', builder: (_, __) => const ProviderOnboardingScreen()),
        GoRoute(path: '/provider-services', builder: (_, __) => const ProviderServicesScreen()),
        ShellRoute(
          builder: (context, state, child) => ProviderAppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/provider-home', builder: (_, __) => const ProviderHomeScreen()),
            GoRoute(path: '/provider-calendar', builder: (_, __) => const ProviderCalendarScreen()),
            GoRoute(path: '/provider-earnings', builder: (_, __) => const ProviderEarningsShellScreen()),
            GoRoute(path: '/provider-profile', builder: (_, __) => const ProviderProfileShellScreen()),
          ],
        ),
        ShellRoute(
          navigatorKey: _shellKey,
          builder: (context, state, child) => MainShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
            GoRoute(path: '/appointments', builder: (_, __) => const AppointmentsScreen()),
            GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
        GoRoute(
          path: '/booking',
          builder: (_, state) => BookingScreen(
            providerId: int.tryParse(state.uri.queryParameters['providerId'] ?? '1') ?? 1,
          ),
        ),
        GoRoute(
          path: '/payment',
          builder: (_, state) => PaymentScreen(
            providerId: int.tryParse(state.uri.queryParameters['providerId'] ?? '1') ?? 1,
            serviceId: int.tryParse(state.uri.queryParameters['serviceId'] ?? '1') ?? 1,
            scheduledAt: state.uri.queryParameters['scheduledAt'] ?? '2025-06-17T10:30:00',
            locationType: state.uri.queryParameters['locationType'] ?? 'home',
            serviceName: Uri.decodeComponent(state.uri.queryParameters['serviceName'] ?? 'Full Glam Makeup'),
            providerName: Uri.decodeComponent(state.uri.queryParameters['providerName'] ?? 'Zara Beauty Studio'),
            price: int.tryParse(state.uri.queryParameters['price'] ?? '12000') ?? 12000,
            note: state.uri.queryParameters.containsKey('note') ? Uri.decodeComponent(state.uri.queryParameters['note']!) : null,
          ),
        ),
        GoRoute(
          path: '/confirm',
          builder: (_, state) => ConfirmScreen(
            code: state.uri.queryParameters['code'] ?? 'KHD-2847',
            total: int.tryParse(state.uri.queryParameters['total'] ?? '13200') ?? 13200,
            service: Uri.decodeComponent(state.uri.queryParameters['service'] ?? 'Full Glam Makeup'),
            provider: Uri.decodeComponent(state.uri.queryParameters['provider'] ?? 'Zara Beauty Studio'),
            date: Uri.decodeComponent(state.uri.queryParameters['date'] ?? 'Tue Jun 17 · 10:30 AM'),
          ),
        ),
        GoRoute(
          path: '/tracking',
          builder: (_, state) => TrackingScreen(
            bookingId: int.tryParse(state.uri.queryParameters['bookingId'] ?? ''),
            bookingCode: state.uri.queryParameters['code'],
          ),
        ),
        GoRoute(
          path: '/cancel',
          builder: (_, state) => CancelScreen(
            bookingId: int.tryParse(state.uri.queryParameters['bookingId'] ?? '1') ?? 1,
            providerName: Uri.decodeComponent(state.uri.queryParameters['provider'] ?? 'Provider'),
          ),
        ),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(path: '/saved-providers', builder: (_, __) => const SavedProvidersScreen()),
        GoRoute(path: '/location-picker', builder: (_, __) => const LocationPickerScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/review',
          builder: (_, state) => ReviewScreen(
            providerId: int.tryParse(state.uri.queryParameters['providerId'] ?? '1') ?? 1,
            providerName: Uri.decodeComponent(state.uri.queryParameters['providerName'] ?? 'Provider'),
            bookingId: int.tryParse(state.uri.queryParameters['bookingId'] ?? ''),
          ),
        ),
        GoRoute(path: '/provider-dash', builder: (_, __) => const ProviderDashScreen()),
        GoRoute(
          path: '/chat',
          builder: (_, state) => ChatScreen(
            bookingId: int.tryParse(state.uri.queryParameters['bookingId'] ?? '1') ?? 1,
            title: state.uri.queryParameters.containsKey('title') ? Uri.decodeComponent(state.uri.queryParameters['title']!) : null,
          ),
        ),
        GoRoute(
          path: '/group-booking',
          builder: (_, state) => GroupBookingScreen(
            providerId: int.tryParse(state.uri.queryParameters['providerId'] ?? ''),
          ),
        ),
        GoRoute(path: '/provider-business', builder: (_, __) => const ProviderBusinessScreen()),
      ],
    );

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/appointments')) return 2;
    if (location.startsWith('/feed')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    const paths = ['/home', '/explore', '/appointments', '/feed', '/profile'];
    context.go(paths[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _index == 3 ? Colors.black : AppColors.white,
          border: Border(top: BorderSide(color: _index == 3 ? Colors.white12 : AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', active: _index == 0, onTap: () => _onTap(context, 0)),
                _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore', active: _index == 1, onTap: () => _onTap(context, 1)),
                _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Bookings', active: _index == 2, onTap: () => _onTap(context, 2)),
                _NavItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle, label: 'Feed', active: _index == 3, onTap: () => _onTap(context, 3), dark: _index == 3),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', active: _index == 4, onTap: () => _onTap(context, 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap, this.dark = false});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? (dark ? AppColors.white : AppColors.matcha) : (dark ? Colors.white54 : const Color(0xFFBBBBBB));
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.sans(9, color: color)),
          ],
        ),
      ),
    );
  }
}
