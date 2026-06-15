import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
        final bookingCount = stats['bookings'] as int? ?? repo.bookings.length;
        final users = stats['activeUsers'] as int? ?? 1;
        final topProviders = repo.providers.take(4).toList();

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                color: AppColors.dark,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7)),
                            onPressed: () => context.pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 10),
                          Text('Admin Dashboard', style: AppTheme.serif(22, color: AppColors.white)),
                        ],
                      ),
                      Text('Khade Platform · ${repo.isLive ? 'Live data' : 'Offline data'}', style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: ConnectionBanner()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                        children: [
                          _StatCard(label: 'Total Revenue', value: _fmt(revenue), change: repo.isLive ? 'From backend' : 'Seed data'),
                          _StatCard(label: 'Platform Fees', value: _fmt(fees), change: '10% commission'),
                          _StatCard(label: 'Bookings', value: '$bookingCount', change: '${repo.bookings.where((b) => b.status == 'upcoming').length} upcoming'),
                          _StatCard(label: 'Providers', value: '${repo.providers.length}', change: '$users users'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('PROVIDERS OVERVIEW', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < topProviders.length; i++)
                              _ProviderRow(
                                name: '${topProviders[i].emoji} ${topProviders[i].name}',
                                bookings: '${topProviders[i].reviewCount}',
                                status: topProviders[i].verified ? 'Active' : 'Review',
                                active: topProviders[i].verified,
                                last: i == topProviders.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Bookings', style: AppTheme.serif(18, color: AppColors.white)),
                            const SizedBox(height: 8),
                            for (final b in repo.bookings.take(3))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${b.providerEmoji} ${b.serviceName} · ${formatNaira(b.totalAmount)} · ${b.status}',
                                  style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.6)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.change});
  final String label;
  final String value;
  final String change;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1)),
          const Spacer(),
          Text(value, style: AppTheme.serif(24)),
          Text(change, style: AppTheme.sans(10, color: AppColors.green)),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.name, required this.bookings, required this.status, required this.active, this.last = false});
  final String name;
  final String bookings;
  final String status;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTheme.sans(12))),
          Text(bookings, style: AppTheme.sans(12, color: AppColors.mid)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: active ? AppColors.greenBg : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTheme.sans(9, color: active ? AppColors.green : const Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }
}
