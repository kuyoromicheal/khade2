import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/opening_hours.dart' show formatOpeningHoursDisplay;
import '../widgets/booking_sheet.dart';
import '../widgets/open_status_pill.dart';
import '../widgets/api_widgets.dart';
import '../widgets/khade_image.dart';

class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen({super.key, required this.providerId});
  final int providerId;

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  ProviderModel? _provider;
  bool _loading = true;
  bool _bioExpanded = false;
  int _photoIndex = 0;
  int _serviceTab = 0;
  final _servicesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await KhadeRepository.instance.fetchProviderDetail(widget.providerId);
    if (mounted) setState(() { _provider = p; _loading = false; });
  }

  List<ServiceModel> get _services => _provider?.services ?? [];

  List<String> get _serviceCategories {
    final cats = _services.map((s) => s.name.split(' ').first).toSet().toList();
    return ['All', ...cats.take(4)];
  }

  List<ServiceModel> get _filteredServices {
    if (_serviceTab == 0) return _services;
    final cat = _serviceCategories[_serviceTab];
    return _services.where((s) => s.name.toLowerCase().contains(cat.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.cream, body: Center(child: CircularProgressIndicator(color: AppColors.matcha)));
    }
    final p = _provider;
    if (p == null) {
      return Scaffold(backgroundColor: AppColors.cream, body: Center(child: Text('Provider not found', style: AppTheme.sans(14, color: AppColors.soft))));
    }

    final photos = p.photos.isNotEmpty ? p.photos : [if (p.imageUrl != null) p.imageUrl!];
    final reviews = KhadeRepository.instance.reviewsForProvider(p.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _gallery(p, photos)),
              SliverToBoxAdapter(child: _header(p)),
              SliverToBoxAdapter(child: _about(p)),
              SliverToBoxAdapter(child: _servicesSection(p)),
              SliverToBoxAdapter(child: _portfolioSection(p)),
              if (p.hasTeam && p.team.isNotEmpty) SliverToBoxAdapter(child: _teamSection(p)),
              SliverToBoxAdapter(child: _reviewsSection(p, reviews)),
              SliverToBoxAdapter(child: _hoursSection(p)),
              SliverToBoxAdapter(child: _badgesSection(p)),
              if (p.latitude != null && p.longitude != null) SliverToBoxAdapter(child: _mapSection(p)),
              if (p.branches.isNotEmpty) SliverToBoxAdapter(child: _branchesSection(p)),
              SliverToBoxAdapter(child: _similarSection(p)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _stickyBar(p),
        ],
      ),
    );
  }

  Widget _gallery(ProviderModel p, List<String> photos) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          child: photos.isEmpty
              ? KhadeImage(gradient: [colorFromHex(p.gradientStart), colorFromHex(p.gradientEnd)], emojiSize: 64)
              : PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _photoIndex = i),
                  itemBuilder: (_, i) => KhadeImage(url: photos[i], fallbackUrl: photos[i]),
                ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) => Container(
                width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _photoIndex == i ? AppColors.white : Colors.white54),
              )),
            ),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, left: 12,
          child: _circleBtn(Icons.arrow_back, () => context.pop()),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, right: 12,
          child: Row(
            children: [
              _circleBtn(
                KhadeRepository.instance.isProviderSaved(p.id) ? Icons.favorite : Icons.favorite_border,
                () => KhadeRepository.instance.toggleSaveProvider(p.id),
              ),
              const SizedBox(width: 8),
              _circleBtn(Icons.share_outlined, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _header(ProviderModel p) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.name, style: AppTheme.serif(26)),
          const SizedBox(height: 6),
          Text('${p.emoji} ${p.category} · ⭐ ${p.rating.toStringAsFixed(1)} · ${p.reviewCount} reviews', style: AppTheme.sans(12, color: AppColors.soft)),
          const SizedBox(height: 10),
          Row(
            children: [
              OpenStatusPill(openingHours: p.openingHours),
              if (p.verified) ...[
                const SizedBox(width: 8),
                const Chip(label: Text('✓ Verified', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
              ],
              if (p.instantConfirm) ...[
                const SizedBox(width: 4),
                const Chip(label: Text('⚡ Instant', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
              ],
              if (p.isSoloPro) ...[
                const SizedBox(width: 4),
                Chip(label: const Text('⚡ Solo Pro', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(p.isSoloPro ? Icons.bolt_outlined : (p.isMobileProvider && p.providerType != 'salon' ? Icons.directions_car_outlined : Icons.location_on_outlined), size: 14, color: AppColors.matcha),
            const SizedBox(width: 4),
            Expanded(child: Text(p.isSoloPro ? '⚡ Solo Pro · Serves ${p.coverageLabel}' : p.locationBadge, style: AppTheme.sans(12, color: AppColors.mid))),
          ]),
          if (p.isSoloPro && p.workLocationsLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Works at: ${p.workLocationsLabel}', style: AppTheme.sans(11, color: AppColors.soft)),
          ] else if (p.isMobileProvider && p.travelInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(p.travelInfo, style: AppTheme.sans(11, color: AppColors.soft)),
          ],
        ],
      ),
    );
  }

  Widget _about(ProviderModel p) {
    final bio = p.bio.isNotEmpty ? p.bio : 'Premium ${p.category.toLowerCase()} services in ${p.area}. Book via Khade for home visits or salon appointments.';
    return _section('About', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bio, style: AppTheme.sans(13, color: AppColors.mid), maxLines: _bioExpanded ? null : 2, overflow: _bioExpanded ? null : TextOverflow.ellipsis),
        if (bio.length > 80)
          TextButton(onPressed: () => setState(() => _bioExpanded = !_bioExpanded), child: Text(_bioExpanded ? 'Show less' : 'Read more', style: AppTheme.sans(12, color: AppColors.matcha))),
      ],
    ));
  }

  Widget _servicesSection(ProviderModel p) {
    return _section('Services', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _serviceCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _serviceTab == i;
              return ChoiceChip(
                label: Text(_serviceCategories[i], style: AppTheme.sans(11)),
                selected: sel,
                onSelected: (_) => setState(() => _serviceTab = i),
                selectedColor: AppColors.matcha,
                labelStyle: TextStyle(color: sel ? Colors.white : AppColors.mid),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        for (final s in _filteredServices) _serviceCard(p, s),
      ],
    ));
  }

  Widget _serviceCard(ProviderModel p, ServiceModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: AppTheme.sans(14, weight: FontWeight.w600)),
              Text(s.duration, style: AppTheme.sans(11, color: AppColors.soft)),
            ]),
          ),
          Text(formatNaira(s.price), style: AppTheme.sans(14, color: AppColors.matcha, weight: FontWeight.w600)),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _bookService(p, s),
            style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
            child: Text('Book', style: AppTheme.sans(11, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _bookService(ProviderModel p, ServiceModel s) async {
    final result = await showBookingSheet(context, s);
    if (result == null || !mounted) return;
    context.push(
      '/booking?providerId=${p.id}&serviceId=${s.id}&qty=${result.quantity}&bookingType=${result.bookingType}',
    );
  }

  Widget _portfolioSection(ProviderModel p) {
    final items = KhadeRepository.instance.feedForProvider(p.id);
    if (items.isEmpty) return const SizedBox.shrink();
    return _section('Portfolio', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work by ${p.name.split(' ').first}', style: AppTheme.sans(12, color: AppColors.mid)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length.clamp(0, 12),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final post = items[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      KhadeImage(url: post.imageUrl, emoji: post.imageEmoji, emojiSize: 36),
                      if (post.isVideo) const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  Widget _teamSection(ProviderModel p) => _section('Team', SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: p.team.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final m = p.team[i];
            return Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(children: [
                CircleAvatar(radius: 22, backgroundColor: AppColors.matchaPale, child: Text(m.name[0], style: AppTheme.sans(14, color: AppColors.matcha))),
                const SizedBox(height: 6),
                Text(m.name, style: AppTheme.sans(11, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(m.role, style: AppTheme.sans(9, color: AppColors.soft), maxLines: 1),
              ]),
            );
          },
        ),
      ));

  Widget _reviewsSection(ProviderModel p, List<ReviewModel> reviews) => _section('Reviews', Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.rating.toStringAsFixed(1), style: AppTheme.serif(36, color: AppColors.matchaDeep)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < p.rating.round() ? AppColors.gold : AppColors.border)),
                Text('${p.reviewCount} reviews', style: AppTheme.sans(11, color: AppColors.soft)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Text('No reviews yet', style: AppTheme.sans(12, color: AppColors.soft))
          else
            for (final r in reviews.take(5))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 14, backgroundColor: AppColors.matchaPale, child: Text(r.authorName[0], style: AppTheme.sans(11))),
                    const SizedBox(width: 8),
                    Text(r.authorName, style: AppTheme.sans(12, weight: FontWeight.w500)),
                    const Spacer(),
                    ...List.generate(r.rating, (_) => const Icon(Icons.star, size: 10, color: AppColors.gold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(r.comment, style: AppTheme.sans(12, color: AppColors.mid)),
                ]),
              ),
          TextButton(onPressed: () => context.push('/review?providerId=${p.id}&providerName=${Uri.encodeComponent(p.name)}'), child: const Text('Write a Review →')),
        ],
      ));

  Widget _hoursSection(ProviderModel p) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const keys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = DateTime.now().weekday - 1;
    return _section('Opening Times', Column(
      children: List.generate(7, (i) {
        final label = days[i];
        final raw = p.openingHours?[keys[i]];
        String value = 'Closed';
        if (raw is Map && raw['open'] != null && raw['close'] != null) {
          value = '${formatOpeningHoursDisplay(raw['open'])} — ${formatOpeningHoursDisplay(raw['close'])}';
        }
        final isToday = i == today;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTheme.sans(12, color: isToday ? AppColors.matcha : AppColors.mid, weight: isToday ? FontWeight.w600 : FontWeight.w400))),
              Text(value, style: AppTheme.sans(12, color: AppColors.soft)),
            ],
          ),
        );
      }),
    ));
  }

  Widget _badgesSection(ProviderModel p) {
    final badges = <String>[
      if (p.verified) '✓ Verified',
      if (p.instantConfirm) '⚡ Instant Confirmation',
      '💳 Pay by App',
      if (p.doesHomeVisits) '🏠 Home Visits',
      if (p.hasSalon) '🏪 Salon Available',
      if (p.acceptsGroups) '👥 Group Bookings',
      if (p.isCertified) '🎓 Trained & Certified',
    ];
    return _section('Additional Info', Wrap(
      spacing: 8, runSpacing: 8,
      children: badges.map((b) => Chip(label: Text(b, style: AppTheme.sans(10)), backgroundColor: AppColors.matchaPale)).toList(),
    ));
  }

  Widget _mapSection(ProviderModel p) {
    final lat = p.latitude!;
    final lng = p.longitude!;
    return _section('Location', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 14, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [Marker(point: LatLng(lat, lng), width: 40, height: 40, child: Container(
                  decoration: const BoxDecoration(color: AppColors.matcha, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
                ))]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('${p.area}, Abuja', style: AppTheme.sans(12, color: AppColors.mid)),
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')),
          child: const Text('Open in Maps →'),
        ),
      ],
    ));
  }

  Widget _branchesSection(ProviderModel p) => _section('Other Locations', SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: p.branches.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final b = p.branches[i];
            return Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.branchName, style: AppTheme.sans(12, weight: FontWeight.w600)),
                Text(b.address, style: AppTheme.sans(10, color: AppColors.soft), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ));

  Widget _similarSection(ProviderModel p) {
    final similar = KhadeRepository.instance.providers
        .where((x) => x.id != p.id && x.category == p.category && x.area == p.area)
        .take(6)
        .toList();
    if (similar.isEmpty) return const SizedBox.shrink();
    return _section('Others You Might Like', SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: similar.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = similar[i];
          return GestureDetector(
            onTap: () => context.push('/provider/${s.id}'),
            child: Container(
              width: 140,
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: KhadeImage(url: s.imageUrl, fallbackUrl: s.imageUrl, gradient: [colorFromHex(s.gradientStart), colorFromHex(s.gradientEnd)])),
                Padding(padding: const EdgeInsets.all(8), child: Text(s.name, style: AppTheme.sans(11, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          );
        },
      ),
    ));
  }

  Widget _section(String title, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _stickyBar(ProviderModel p) => Positioned(
        left: 0, right: 0, bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Starting from', style: AppTheme.sans(10, color: AppColors.soft)),
                  Text(p.priceLabel, style: AppTheme.serif(18, color: AppColors.matchaDeep)),
                ])),
                FilledButton(
                  onPressed: () {
                    if (_services.length == 1) {
                      _bookService(p, _services.first);
                    } else {
                      Scrollable.ensureVisible(_servicesKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  child: Text('Book Now →', style: AppTheme.sans(13, color: Colors.white, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
}
