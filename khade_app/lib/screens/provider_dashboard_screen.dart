import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/tier_utils.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/khade_image.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  Map<String, dynamic> _earnings = {};
  bool _loadingEarnings = true;

  int get _providerId => AuthService.instance.authUser?.providerId ?? 1;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _loadingEarnings = true);
    try {
      if (KhadeRepository.instance.isLive && AuthService.instance.authUser?.isProvider == true) {
        _earnings = await khadeApi.getProviderEarnings();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingEarnings = false);
  }

  Future<void> _refresh() async {
    await KhadeRepository.instance.refresh();
    await _loadEarnings();
  }

  Future<void> _updateBooking(int id, String status, {required String success}) async {
    try {
      await khadeApi.updateBookingStatus(id, status);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success), backgroundColor: AppColors.matcha),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final provider = repo.providerById(_providerId);
        if (provider == null) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            body: const Center(child: Text('Provider profile not found')),
          );
        }

        final all = repo.bookingsForProvider(_providerId);
        final today = all.where((b) => _isToday(b.scheduledAt) && b.status == 'upcoming').toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final pending = all.where(_needsAction).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final gross = (_earnings['gross'] as int?) ?? 0;
        final balance = (_earnings['availableBalance'] as int?) ?? (_earnings['net'] as int?) ?? 0;
        final reviews = repo.reviewsForProvider(_providerId).take(3).toList();
        final completion = _profileCompletion(provider);

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: RefreshIndicator(
            color: AppColors.matcha,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(provider: provider, completion: completion)),
                const SliverToBoxAdapter(child: ConnectionBanner()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                    ),
                    delegate: SliverChildListDelegate([
                      _MetricCard(
                        icon: Icons.event_available_outlined,
                        label: "Today's bookings",
                        value: '${today.length}',
                        accent: AppColors.matchaDeep,
                      ),
                      _MetricCard(
                        icon: Icons.pending_actions_outlined,
                        label: 'Pending',
                        value: '${pending.length}',
                        accent: const Color(0xFFC47D00),
                      ),
                      _MetricCard(
                        icon: Icons.payments_outlined,
                        label: 'Month earnings',
                        value: _loadingEarnings ? '…' : _compactNaira(gross),
                        accent: AppColors.gold,
                      ),
                      _MetricCard(
                        icon: Icons.star_outline,
                        label: 'Rating',
                        value: '${provider.rating}',
                        sub: '${provider.reviewCount} reviews',
                        accent: AppColors.matcha,
                      ),
                    ]),
                  ),
                ),
                if (pending.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PendingBanner(
                      bookings: pending,
                      onAccept: (id) => _updateBooking(id, 'accepted', success: 'Booking accepted'),
                      onDecline: (id) => _updateBooking(id, 'cancelled', success: 'Booking declined'),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text("TODAY'S SCHEDULE", style: _sectionLabel),
                  ),
                ),
                if (today.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _EmptyCard(
                        icon: Icons.calendar_today_outlined,
                        message: 'No appointments today',
                        action: 'Set availability',
                        onAction: () => context.go('/provider-calendar'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _TimelineCard(
                          booking: today[i],
                          isLast: i == today.length - 1,
                          onComplete: () => _updateBooking(today[i].id, 'completed', success: 'Marked complete'),
                        ),
                        childCount: today.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _EarningsStrip(
                      balance: balance,
                      onView: () => context.push('/provider-more/earnings'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _QuickPostCard(onTap: () => context.push('/provider-more/portfolio')),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RECENT REVIEWS', style: _sectionLabel),
                        if (reviews.isNotEmpty)
                          TextButton(
                            onPressed: () => context.push('/provider-services'),
                            child: Text('See all', style: AppTheme.sans(12, color: AppColors.matcha)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (reviews.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: _EmptyCard(
                        icon: Icons.rate_review_outlined,
                        message: 'No reviews yet — complete bookings to get rated',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ReviewTile(review: reviews[i]),
                        childCount: reviews.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _needsAction(BookingModel b) {
    if (b.status == 'pending') return true;
    if (b.status != 'upcoming') return false;
    final provider = KhadeRepository.instance.providerById(_providerId);
    if (provider?.instantConfirm != false) return false;
    return !_isToday(b.scheduledAt);
  }

  int _profileCompletion(ProviderModel p) {
    var score = 0;
    if (p.bio.trim().isNotEmpty) score += 20;
    if (p.services.isNotEmpty) score += 25;
    if ((p.avatarUrl ?? p.imageUrl ?? '').isNotEmpty) score += 20;
    if (p.photos.isNotEmpty) score += 15;
    if ((p.phone ?? '').isNotEmpty) score += 10;
    if (p.openingHours != null) score += 10;
    return score.clamp(0, 100);
  }

  String _compactNaira(int amount) {
    if (amount >= 1000000) return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '₦${(amount / 1000).round()}K';
    return formatNaira(amount);
  }

  static final _sectionLabel = AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1);
}

class _Header extends StatelessWidget {
  const _Header({required this.provider, required this.completion});

  final ProviderModel provider;
  final int completion;

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.authUser?.name ?? provider.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: AppColors.matchaDeep,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TierUtils.greeting(), style: AppTheme.sans(12, color: Colors.white60)),
                      Text(name.split(' ').first, style: AppTheme.serif(26, color: AppColors.white)),
                      Text(
                        '${provider.category} · ${provider.area}${provider.verified ? ' ✦' : ''}',
                        style: AppTheme.sans(11, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: KhadeImage(
                      url: provider.avatarUrl ?? provider.imageUrl,
                      emoji: provider.emoji,
                      emojiSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            if (completion < 100) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$completion%', style: AppTheme.sans(11, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Complete your profile to get more bookings',
                style: AppTheme.sans(10, color: Colors.white54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: accent),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTheme.serif(22, color: AppColors.dark)),
              Text(label, style: AppTheme.sans(10, color: AppColors.soft)),
              if (sub != null) Text(sub!, style: AppTheme.sans(9, color: AppColors.mid)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.bookings,
    required this.onAccept,
    required this.onDecline,
  });

  final List<BookingModel> bookings;
  final ValueChanged<int> onAccept;
  final ValueChanged<int> onDecline;

  @override
  Widget build(BuildContext context) {
    final b = bookings.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFFC47D00)),
              const SizedBox(width: 8),
              Text(
                '${bookings.length} booking${bookings.length == 1 ? '' : 's'} need your response',
                style: AppTheme.sans(12, weight: FontWeight.w600, color: const Color(0xFFC47D00)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(b.serviceName, style: AppTheme.sans(13, weight: FontWeight.w500)),
          Text(
            '${_formatWhen(b.scheduledAt)} · ${formatNaira(b.totalAmount)}',
            style: AppTheme.sans(11, color: AppColors.mid),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onDecline(b.id),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.redDark),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => onAccept(b.id),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.matcha),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWhen(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day} · $h:${m == '00' ? '00' : m} $ampm';
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.booking,
    required this.isLast,
    this.onComplete,
  });

  final BookingModel booking;
  final bool isLast;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(booking.scheduledAt);
    final h = dt != null ? (dt.hour % 12 == 0 ? 12 : dt.hour % 12) : 10;
    final m = dt != null ? dt.minute.toString().padLeft(2, '0') : '30';
    final ampm = dt != null && dt.hour >= 12 ? 'PM' : 'AM';
    final loc = booking.locationType == 'home' ? 'At client' : 'At salon';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text('$h:${m == '00' ? '00' : m}', style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w600)),
                Text(ampm, style: AppTheme.sans(9, color: AppColors.soft)),
                if (!isLast) ...[
                  const SizedBox(height: 4),
                  Expanded(child: Container(width: 2, color: AppColors.border)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.customerName ?? booking.serviceName, style: AppTheme.sans(13, weight: FontWeight.w600)),
                        Text(booking.serviceName, style: AppTheme.sans(11, color: AppColors.soft)),
                        Text('📍 $loc · ${booking.bookingCode}', style: AppTheme.sans(10, color: AppColors.matcha)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatNaira(booking.totalAmount), style: AppTheme.sans(13, weight: FontWeight.w600)),
                      if (onComplete != null)
                        TextButton(
                          onPressed: onComplete,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Complete', style: AppTheme.sans(11, color: AppColors.matcha)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsStrip extends StatelessWidget {
  const _EarningsStrip({required this.balance, required this.onView});

  final int balance;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.matchaDeep, Color(0xFF3D5A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available balance', style: AppTheme.sans(11, color: Colors.white60)),
                Text(formatNaira(balance), style: AppTheme.serif(24, color: AppColors.white)),
              ],
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: Text('View earnings →', style: AppTheme.sans(12, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _QuickPostCard extends StatelessWidget {
  const _QuickPostCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.matchaDeep, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add to your portfolio', style: AppTheme.sans(13, weight: FontWeight.w600)),
                    Text('Show your work on your Khade profile', style: AppTheme.sans(11, color: AppColors.soft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.soft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.authorName, style: AppTheme.sans(12, weight: FontWeight.w600)),
              const Spacer(),
              Text('${'★' * review.rating}${'☆' * (5 - review.rating)}', style: AppTheme.sans(11, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment, style: AppTheme.sans(12, color: AppColors.mid), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.soft),
          const SizedBox(height: 8),
          Text(message, style: AppTheme.sans(13, color: AppColors.soft), textAlign: TextAlign.center),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
