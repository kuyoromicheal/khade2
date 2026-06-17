import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _payouts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (KhadeRepository.instance.isLive) {
        _providers = await khadeApi.getAdminProviders();
        _bookings = await khadeApi.getAdminBookings();
        _payouts = await khadeApi.getAdminPayouts();
        KhadeRepository.instance.adminStats = await khadeApi.getAdminDashboard();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '₦${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '₦${(n / 1000).round()}K';
    return formatNaira(n);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final stats = repo.adminStats;
        final revenue = stats['totalRevenue'] as int? ?? 8400000;
        final fees = stats['platformFees'] as int? ?? 840000;

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                color: AppColors.dark,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7)), onPressed: () => context.pop(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          const SizedBox(width: 10),
                          Text('Admin', style: AppTheme.serif(22, color: AppColors.white)),
                          const Spacer(),
                          if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                        ],
                      ),
                      Text('10% commission · Featured · Gold · Boosts', style: AppTheme.sans(10, color: Colors.white38)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(['Overview', 'Providers', 'Bookings', 'Payouts'][i]),
                                  selected: _tab == i,
                                  onSelected: (_) => setState(() => _tab = i),
                                  selectedColor: AppColors.gold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const ConnectionBanner(),
                    if (_tab == 0) ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _StatCard(label: 'Revenue', value: _fmt(revenue), sub: 'Completed bookings'),
                          _StatCard(label: 'Commission', value: _fmt(fees), sub: '10% platform fee'),
                          _StatCard(label: 'Featured', value: _fmt(stats['featuredRevenue'] as int? ?? 25000), sub: '₦5K/mo listings'),
                          _StatCard(label: 'Khade Gold', value: _fmt(stats['goldRevenue'] as int? ?? 9000), sub: '₦3K/mo subs'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatCard(label: 'Boost fees', value: _fmt(stats['boostRevenue'] as int? ?? 7500), sub: '₦2,500 / 7 days', wide: true),
                    ],
                    if (_tab == 1) ...[
                      for (final Map<String, dynamic> p in _providers.isNotEmpty
                          ? _providers
                          : repo.providers.map((pr) => <String, dynamic>{
                                'name': pr.name,
                                'category': pr.category,
                                'bookings': pr.reviewCount,
                                'status': 'active',
                                'id': pr.id,
                                'verified': pr.verified,
                              }))
                        _AdminRow(
                          title: '${p['name']}',
                          sub: '${p['category']} · ${p['bookings']} bookings',
                          badge: '${p['status']}',
                        ),
                    ],
                    if (_tab == 2)
                      for (final b in (_bookings.isNotEmpty
                          ? _bookings.take(20)
                          : repo.bookings.map((bk) => {
                                'bookingCode': bk.bookingCode,
                                'providerName': bk.providerName,
                                'totalAmount': bk.totalAmount,
                                'status': bk.status,
                              })))
                        _AdminRow(
                          title: '${b['bookingCode']}',
                          sub: '${b['providerName']} · ${formatNaira(b['totalAmount'] as int)}',
                          badge: '${b['status']}',
                        ),
                    if (_tab == 3)
                      ...(_payouts.isEmpty
                          ? [Padding(padding: const EdgeInsets.all(20), child: Text('No pending payouts', style: AppTheme.sans(13, color: AppColors.soft)))]
                          : _payouts.map((p) => _AdminRow(
                                title: '${p['providerName'] ?? 'Provider'}',
                                sub: formatNaira(p['amount'] as int),
                                badge: '${p['status']}',
                                onApprove: p['status'] == 'pending' ? () => _approvePayout(p['id'] as int) : null,
                              ))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _approvePayout(int id) async {
    try {
      await khadeApi.approvePayout(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.sub, this.wide = false});
  final String label, value, sub;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      margin: wide ? const EdgeInsets.only(bottom: 8) : null,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AppTheme.sans(9, color: AppColors.soft)),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.serif(22)),
        Text(sub, style: AppTheme.sans(10, color: AppColors.green)),
      ]),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({required this.title, required this.sub, required this.badge, this.onApprove});
  final String title, sub, badge;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTheme.sans(12, weight: FontWeight.w500)),
            Text(sub, style: AppTheme.sans(10, color: AppColors.soft)),
          ])),
          Text(badge, style: AppTheme.sans(10, color: AppColors.matcha)),
          if (onApprove != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onApprove, child: const Text('Approve')),
          ],
        ],
      ),
    );
  }
}
