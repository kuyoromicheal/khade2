import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/khade_image.dart';

class ProviderDashScreen extends StatefulWidget {
  const ProviderDashScreen({super.key, this.providerId = 1});
  final int providerId;

  @override
  State<ProviderDashScreen> createState() => _ProviderDashScreenState();
}

class _ProviderDashScreenState extends State<ProviderDashScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final provider = repo.providerById(widget.providerId);
        final appts = repo.bookingsForProvider(widget.providerId).where((b) => b.status == 'upcoming').toList();
        final posts = repo.feedForProvider(widget.providerId);
        final gross = appts.fold<int>(0, (sum, b) => sum + b.totalAmount);
        final net = (gross * 0.9).round();

        if (provider == null) {
          return Scaffold(backgroundColor: AppColors.cream, body: const Center(child: Text('Provider not found')));
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                color: AppColors.matchaDeep,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7)),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        alignment: Alignment.centerLeft,
                      ),
                      Text(provider.name, style: AppTheme.serif(22, color: AppColors.white)),
                      Text('${provider.category} · ${provider.area}, Abuja ${provider.verified ? '✦ Verified' : ''}', style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _PStat(num: formatNaira(gross > 0 ? gross : 284000), lbl: 'This Month'),
                          const SizedBox(width: 8),
                          _PStat(num: '${appts.isNotEmpty ? appts.length : provider.reviewCount}', lbl: 'Bookings'),
                          const SizedBox(width: 8),
                          _PStat(num: '${provider.rating} ⭐', lbl: 'Rating'),
                          const SizedBox(width: 8),
                          _PStat(num: '98%', lbl: 'Completion'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 0), child: ConnectionBanner()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _ViewSwitcher(
                  labels: const ['Appointments', 'My Posts', 'Earnings'],
                  active: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _AppointmentsTab(appts: appts),
                    _PostsTab(posts: posts),
                    _EarningsTab(gross: gross > 0 ? gross : 284000, net: net > 0 ? net : 255600),
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

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({required this.labels, required this.active, required this.onChanged});
  final List<String> labels;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: active == i ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(labels[i], style: AppTheme.sans(12, color: active == i ? AppColors.dark : AppColors.soft,
                      weight: active == i ? FontWeight.w500 : FontWeight.w400)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  const _PStat({required this.num, required this.lbl});
  final String num;
  final String lbl;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(num, style: AppTheme.sans(14, color: AppColors.white, weight: FontWeight.w500), textAlign: TextAlign.center),
            Text(lbl, style: AppTheme.sans(9, color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab({required this.appts});
  final List appts;

  @override
  Widget build(BuildContext context) {
    if (appts.isEmpty) {
      return Center(child: Text('No upcoming appointments', style: AppTheme.sans(14, color: AppColors.soft)));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('UPCOMING · ${appts.length} APPOINTMENTS', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
        const SizedBox(height: 10),
        for (final b in appts)
          _ApptCard(
            time: _timePart(b.scheduledAt),
            ampm: _ampmPart(b.scheduledAt),
            client: KhadeRepository.instance.user?.name ?? 'Client',
            service: b.serviceName,
            loc: b.locationType == 'home' ? 'At Client Location' : 'At Salon',
            price: formatNaira(b.totalAmount),
          ),
      ],
    );
  }

  String _timePart(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '10:30';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return m == '00' ? '$h:00' : '$h:$m';
  }

  String _ampmPart(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'AM';
    return dt.hour >= 12 ? 'PM' : 'AM';
  }
}

class _ApptCard extends StatelessWidget {
  const _ApptCard({required this.time, required this.ampm, required this.client, required this.service, required this.loc, required this.price});
  final String time, ampm, client, service, loc, price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
            child: Column(
              children: [
                Text(time, style: AppTheme.sans(14, color: AppColors.matcha, weight: FontWeight.w500)),
                Text(ampm, style: AppTheme.sans(10, color: AppColors.soft)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client, style: AppTheme.sans(13, weight: FontWeight.w500)),
                Text(service, style: AppTheme.sans(11, color: AppColors.soft)),
                Text('📍 $loc', style: AppTheme.sans(10, color: AppColors.matcha)),
              ],
            ),
          ),
          Text(price, style: AppTheme.sans(14, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts});
  final List<FeedPostModel> posts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (posts.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No posts yet', style: AppTheme.sans(14, color: AppColors.soft))))
        else
          for (final post in posts)
            _PostPreview(imageUrl: post.imageUrl, emoji: post.imageEmoji, likes: '${post.likes} likes', caption: '${post.caption} — ${post.comments} comments'),
      ],
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.emoji, required this.likes, required this.caption, this.imageUrl});
  final String emoji, likes, caption;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: KhadeImage(url: imageUrl, emoji: emoji, emojiSize: 48),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(caption, style: AppTheme.sans(12, color: AppColors.mid)),
          ),
        ],
      ),
    );
  }
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab({required this.gross, required this.net});
  final int gross;
  final int net;

  @override
  Widget build(BuildContext context) {
    final commission = gross - net;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.matchaDeep, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available for Withdrawal', style: AppTheme.sans(11, color: Colors.white.withValues(alpha: 0.6))),
              Text(formatNaira(net), style: AppTheme.serif(32, color: AppColors.white)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdrawal initiated — funds in 24hrs (mock)'), backgroundColor: AppColors.matcha),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.dark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text('Withdraw to Bank', style: AppTheme.sans(12, weight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS MONTH BREAKDOWN', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
              const SizedBox(height: 12),
              _earnRow('Gross Earnings', formatNaira(gross)),
              _earnRow('Khade Commission (10%)', '-${formatNaira(commission)}', red: true),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Payout', style: AppTheme.sans(12, weight: FontWeight.w500)),
                  Text(formatNaira(net), style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earnRow(String label, String value, {bool red = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.sans(12, color: AppColors.mid)),
          Text(value, style: AppTheme.sans(12, color: red ? AppColors.redDark : AppColors.dark)),
        ],
      ),
    );
  }
}
