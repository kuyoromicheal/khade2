import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/khade_image.dart';

// ─── More hub ───────────────────────────────────────────────────────────────

class ProviderMoreScreen extends StatelessWidget {
  const ProviderMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([KhadeRepository.instance, AuthService.instance]),
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final auth = AuthService.instance;
        final pid = auth.authUser?.providerId ?? 1;
        final provider = repo.providerById(pid);
        final unread = repo.unreadNotificationCount;

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: RefreshIndicator(
            color: AppColors.matcha,
            onRefresh: repo.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _MoreHeader(provider: provider, name: auth.authUser?.name)),
                const SliverToBoxAdapter(child: ConnectionBanner()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(child: _EarningsSnapshot()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text('YOUR BUSINESS', style: AppTheme.labelCaps('')),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.35,
                    ),
                    delegate: SliverChildListDelegate([
                      _HubTile(icon: Icons.account_balance_wallet_outlined, label: 'Money', sub: 'Earnings & payouts', route: '/provider-more/earnings', accent: AppColors.gold),
                      _HubTile(icon: Icons.insights_outlined, label: 'Analytics', sub: 'Performance', route: '/provider-more/analytics', accent: AppColors.matcha),
                      _HubTile(icon: Icons.design_services_outlined, label: 'Services', sub: 'Menu & pricing', route: '/provider-more/services', accent: AppColors.matchaDeep),
                      _HubTile(icon: Icons.collections_outlined, label: 'Portfolio', sub: 'Photos & videos', route: '/provider-more/portfolio', accent: AppColors.matchaLight),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(child: Text('ACCOUNT', style: AppTheme.labelCaps(''))),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _MenuRow(icon: Icons.notifications_outlined, label: 'Notifications', badge: unread > 0 ? '$unread' : null, route: '/provider-more/notifications'),
                      _MenuRow(icon: Icons.settings_outlined, label: 'Settings', sub: 'Profile, hours, bank', route: '/provider-more/settings'),
                      _MenuRow(icon: Icons.verified_outlined, label: 'Get Verified', sub: 'Optional ✦ trust badge', route: null, onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification coming soon — optional ✦ badge'), backgroundColor: AppColors.matcha));
                      }),
                      _MenuRow(icon: Icons.calendar_month_outlined, label: 'Availability', sub: 'Open the calendar tab', route: '/provider-calendar'),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreHeader extends StatelessWidget {
  const _MoreHeader({this.provider, this.name});
  final ProviderModel? provider;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: BoxDecoration(gradient: AppColors.matchaGradient),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: KhadeImage(url: provider?.avatarUrl ?? provider?.imageUrl, emoji: provider?.emoji ?? '💄', emojiSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? provider?.name ?? 'Provider', style: AppTheme.serif(22, color: AppColors.white)),
                Text(
                  '${provider?.category ?? 'Beauty'} · ${provider?.area ?? 'Abuja'}${provider?.verified == true ? ' ✦' : ''}',
                  style: AppTheme.sans(11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsSnapshot extends StatefulWidget {
  @override
  State<_EarningsSnapshot> createState() => _EarningsSnapshotState();
}

class _EarningsSnapshotState extends State<_EarningsSnapshot> {
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (KhadeRepository.instance.isLive) {
        _data = await khadeApi.getProviderEarnings();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bal = (_data['availableBalance'] as int?) ?? 0;
    final gross = (_data['gross'] as int?) ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.luxuryCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.matchaDeep.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available balance', style: AppTheme.sans(11, color: Colors.white60)),
                Text(formatNaira(bal), style: AppTheme.serif(26, color: AppColors.white)),
                Text('${formatNaira(gross)} gross this period', style: AppTheme.sans(10, color: AppColors.goldMuted)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/provider-more/earnings'),
            child: Text('View →', style: AppTheme.sans(12, color: AppColors.goldLight, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.icon, required this.label, required this.sub, required this.route, required this.accent});
  final IconData icon;
  final String label;
  final String sub;
  final String route;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 22, color: accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.sans(14, weight: FontWeight.w600)),
                  Text(sub, style: AppTheme.sans(10, color: AppColors.soft)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.sub, this.route, this.badge, this.onTap});
  final IconData icon;
  final String label;
  final String? sub;
  final String? route;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        onTap: onTap ?? (route != null ? () => context.push(route!) : null),
        leading: Icon(icon, color: AppColors.matcha),
        title: Text(label, style: AppTheme.sans(14, weight: FontWeight.w500)),
        subtitle: sub != null ? Text(sub!, style: AppTheme.sans(11, color: AppColors.soft)) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.matcha, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: AppTheme.sans(10, color: Colors.white)),
              ),
            const Icon(Icons.chevron_right, color: AppColors.soft, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Money ──────────────────────────────────────────────────────────────────

class ProviderMoneyScreen extends StatefulWidget {
  const ProviderMoneyScreen({super.key});

  @override
  State<ProviderMoneyScreen> createState() => _ProviderMoneyScreenState();
}

class _ProviderMoneyScreenState extends State<ProviderMoneyScreen> {
  Map<String, dynamic> _e = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _e = await khadeApi.getProviderEarnings();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _withdraw() async {
    try {
      final bal = (_e['availableBalance'] as int?) ?? 0;
      await khadeApi.requestPayout(amount: bal);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal submitted'), backgroundColor: AppColors.matcha));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gross = (_e['gross'] as int?) ?? 0;
    final net = (_e['net'] as int?) ?? 0;
    final bal = (_e['availableBalance'] as int?) ?? net;
    final commission = (_e['commission'] as int?) ?? (gross - net);
    final completed = (_e['completedCount'] as int?) ?? 0;

    return _Scaffold(
      title: 'Money',
      child: _loading
          ? const LoadingPlaceholder()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: AppColors.luxuryCard, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available to withdraw', style: AppTheme.sans(11, color: Colors.white60)),
                      Text(formatNaira(bal), style: AppTheme.serif(34, color: AppColors.white)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: bal > 0 ? _withdraw : null,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.dark),
                        child: Text('Withdraw to bank', style: AppTheme.sans(13, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card('Breakdown', [
                  _row('Gross earnings', formatNaira(gross)),
                  _row('Khade fee (10%)', '-${formatNaira(commission)}', muted: true),
                  const Divider(height: 20),
                  _row('Net earnings', formatNaira(net), bold: true),
                  _row('Completed bookings', '$completed'),
                ]),
              ],
            ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTheme.labelCaps(title)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool muted = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: AppTheme.sans(12, color: muted ? AppColors.soft : AppColors.mid)),
          Text(v, style: AppTheme.sans(12, color: bold ? AppColors.matcha : AppColors.dark, weight: bold ? FontWeight.w600 : FontWeight.w400)),
        ],
      ),
    );
  }
}

// ─── Analytics ──────────────────────────────────────────────────────────────

class ProviderAnalyticsScreen extends StatelessWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final bookings = KhadeRepository.instance.providerBookings;
        final completed = bookings.where((b) => b.status == 'completed').length;
        final upcoming = bookings.where((b) => b.status == 'upcoming').length;
        final revenue = bookings.where((b) => b.status == 'completed').fold<int>(0, (s, b) => s + b.totalAmount);
        final rate = bookings.isEmpty ? 98 : ((completed / bookings.length) * 100).round();

        final serviceCounts = <String, int>{};
        for (final b in bookings) {
          serviceCounts[b.serviceName] = (serviceCounts[b.serviceName] ?? 0) + 1;
        }
        final top = serviceCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return _Scaffold(
          title: 'Analytics',
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(child: _stat('Revenue', formatNaira(revenue), AppColors.gold)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('Completion', '$rate%', AppColors.matcha)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _stat('Upcoming', '$upcoming', AppColors.matchaLight)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('Completed', '$completed', AppColors.matchaDeep)),
                ],
              ),
              const SizedBox(height: 20),
              Text('TOP SERVICES', style: AppTheme.labelCaps('')),
              const SizedBox(height: 10),
              if (top.isEmpty)
                Text('No booking data yet', style: AppTheme.sans(13, color: AppColors.soft))
              else
                for (final e in top.take(5))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: AppTheme.sans(13))),
                        Text('${e.value} bookings', style: AppTheme.sans(11, color: AppColors.matcha)),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.serif(22, color: color)),
          Text(label, style: AppTheme.sans(11, color: AppColors.mid)),
        ],
      ),
    );
  }
}

// ─── Services ───────────────────────────────────────────────────────────────

class ProviderServicesHubScreen extends StatefulWidget {
  const ProviderServicesHubScreen({super.key});

  @override
  State<ProviderServicesHubScreen> createState() => _ProviderServicesHubScreenState();
}

class _ProviderServicesHubScreenState extends State<ProviderServicesHubScreen> {
  ProviderModel? _provider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pid = AuthService.instance.authUser?.providerId ?? 1;
    final p = await KhadeRepository.instance.fetchProviderDetail(pid);
    if (mounted) setState(() => _provider = p);
  }

  @override
  Widget build(BuildContext context) {
    final services = _provider?.services ?? [];
    return _Scaffold(
      title: 'Services',
      actions: [
        TextButton(
          onPressed: () => context.push('/provider-services'),
          child: Text('+ Add', style: AppTheme.sans(13, color: AppColors.matcha, weight: FontWeight.w600)),
        ),
      ],
      child: services.isEmpty
          ? Center(child: Text('Add your first service', style: AppTheme.sans(14, color: AppColors.soft)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (_, i) {
                final s = services[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  child: ListTile(
                    title: Text(s.name, style: AppTheme.sans(14, weight: FontWeight.w600)),
                    subtitle: Text(s.duration, style: AppTheme.sans(11, color: AppColors.soft)),
                    trailing: Text(formatNaira(s.price), style: AppTheme.sans(14, color: AppColors.matcha, weight: FontWeight.w600)),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Portfolio (not public feed) ────────────────────────────────────────────

class ProviderPortfolioScreen extends StatefulWidget {
  const ProviderPortfolioScreen({super.key});

  @override
  State<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen> {
  int _tab = 0;

  Future<void> _addPost(BuildContext context) async {
    final caption = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to portfolio', style: AppTheme.serif(18)),
        content: TextField(controller: caption, maxLines: 3, decoration: const InputDecoration(hintText: 'Caption — e.g. Soft glam bridal look')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      ),
    );
    if (ok != true || caption.text.trim().isEmpty) return;
    try {
      await khadeApi.createProviderPost(caption: caption.text.trim());
      await KhadeRepository.instance.refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to your portfolio'), backgroundColor: AppColors.matcha));
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pid = AuthService.instance.authUser?.providerId ?? 1;
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final posts = KhadeRepository.instance.feedForProvider(pid);
        final photos = posts.where((p) => !p.isVideo).toList();
        final videos = posts.where((p) => p.isVideo).toList();
        final items = _tab == 0 ? photos : videos;

        return _Scaffold(
          title: 'Portfolio',
          actions: [
            IconButton(icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.matcha), onPressed: () => _addPost(context)),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Your work appears on your Khade profile — not in a public feed.',
                  style: AppTheme.sans(12, color: AppColors.mid),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _tabBtn('Photos', 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _tabBtn('Videos', 1)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('No ${_tab == 0 ? 'photos' : 'videos'} yet', style: AppTheme.sans(14, color: AppColors.soft)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final p = items[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                KhadeImage(url: p.imageUrl, emoji: p.imageEmoji, emojiSize: 40),
                                if (p.isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36)),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.black45,
                                    child: Text(p.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.sans(10, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabBtn(String label, int i) {
    final active = _tab == i;
    return GestureDetector(
      onTap: () => setState(() => _tab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.matcha : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.matcha : AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTheme.sans(12, color: active ? Colors.white : AppColors.mid, weight: FontWeight.w500)),
      ),
    );
  }
}

// ─── Settings ───────────────────────────────────────────────────────────────

class ProviderSettingsHubScreen extends StatelessWidget {
  const ProviderSettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _Scaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, Icons.person_outline, 'Business profile', 'Name, bio, area', () {}),
          _tile(context, Icons.calendar_month_outlined, 'Working hours', 'Set in Calendar tab', () => context.go('/provider-calendar')),
          _tile(context, Icons.account_balance_outlined, 'Bank account', 'For withdrawals', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link bank in next update'), backgroundColor: AppColors.matcha));
          }),
          _tile(context, Icons.notifications_outlined, 'Notification preferences', '', () => context.push('/provider-more/notifications')),
          _tile(context, Icons.help_outline, 'Help & support', 'hello@khade.ng', () {}),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.matcha),
        title: Text(title, style: AppTheme.sans(14, weight: FontWeight.w500)),
        subtitle: sub.isNotEmpty ? Text(sub, style: AppTheme.sans(11, color: AppColors.soft)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.soft),
        onTap: onTap,
      ),
    );
  }
}

// ─── Notifications ──────────────────────────────────────────────────────────

class ProviderNotificationsHubScreen extends StatelessWidget {
  const ProviderNotificationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final notes = KhadeRepository.instance.notifications;
        return _Scaffold(
          title: 'Notifications',
          child: notes.isEmpty
              ? Center(child: Text('All caught up', style: AppTheme.sans(14, color: AppColors.soft)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (_, i) {
                    final n = notes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: n.read ? AppColors.surface : AppColors.matchaPale,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        leading: Text(n.emoji ?? '✦', style: const TextStyle(fontSize: 22)),
                        title: Text(n.title, style: AppTheme.sans(13, weight: FontWeight.w600)),
                        subtitle: Text(n.body, style: AppTheme.sans(11, color: AppColors.mid)),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.title, required this.child, this.actions});
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(title, style: AppTheme.serif(22)),
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.dark,
        actions: actions,
      ),
      body: child,
    );
  }
}
