import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/khade_categories.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/tier_utils.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/khade_image.dart';
import '../widgets/category_grid.dart';
import '../widgets/provider_widgets.dart';
import '../widgets/tier_badge.dart';
import '../widgets/wallet_strip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCat = 0;
  Timer? _walletPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KhadeRepository.instance.loadRecentlyViewed();
      KhadeRepository.instance.refreshWalletTransactions();
    });
    _walletPoll = Timer.periodic(const Duration(seconds: 12), (_) {
      KhadeRepository.instance.refreshWalletTransactions();
    });
  }

  @override
  void dispose() {
    _walletPoll?.cancel();
    super.dispose();
  }

  String get _catLabel => KhadeCategories.home[_activeCat.clamp(0, KhadeCategories.home.length - 1)].label;

  Future<void> _openLocationPicker() async {
    await context.push('/location-picker');
  }

  void _openProvider(int id) => context.push('/provider/$id');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final user = repo.user;
        final cats = repo.displayCategories;
        final recommended = repo.recommendedProviders(categoryLabel: _catLabel).take(10).toList();
        final nearby = repo.nearbyProviders(categoryLabel: _catLabel);
        final recent = repo.recentlyViewed.take(10).toList();

        return Column(
          children: [
            _HomeHeader(
              greeting: TierUtils.greeting(),
              userName: user?.name.split(' ').first ?? 'Guest',
              tier: user?.tier ?? 'Bronze',
              locationLabel: repo.locationLabel,
              usingGps: repo.hasRealLocation,
              pinAdjusted: repo.pinAdjusted,
              unreadCount: repo.unreadNotificationCount,
              onOpenLocation: _openLocationPicker,
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/profile'),
            ),
            Expanded(
              child: repo.isLoading
                  ? const LoadingPlaceholder()
                  : RefreshIndicator(
                      color: AppColors.matcha,
                      onRefresh: () async {
                        await repo.refresh();
                        await repo.loadRecentlyViewed();
                        await repo.refreshWalletTransactions();
                      },
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const ConnectionBanner(),
                          if (!repo.inServiceArea)
                            Container(
                              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFE082)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 18, color: Color(0xFFC47D00)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Outside Abuja service area — update your delivery pin',
                                      style: AppTheme.sans(11, color: const Color(0xFFC47D00)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _SearchBar(onTap: () => context.go('/explore')),
                          const WalletStrip(),
                          CategoryGrid(
                            activeIndex: _activeCat,
                            onTap: (i) {
                              setState(() => _activeCat = i);
                              final slug = cats[i].slug;
                              if (slug != 'all') context.go('/explore?category=$slug');
                            },
                            onSeeAll: () => _showAllCategories(context, cats),
                          ),
                          if (recommended.isNotEmpty) ...[
                            SectionTitle(title: 'Recommended for You', action: 'See all', onAction: () => context.go('/explore')),
                            _ProviderCarousel(providers: recommended, onTap: _openProvider),
                          ],
                          if (recent.isNotEmpty) ...[
                            SectionTitle(title: 'Recently Viewed', action: 'See all', onAction: () => context.go('/explore')),
                            _ProviderCarousel(providers: recent, onTap: _openProvider),
                          ],
                          SectionTitle(title: 'Near You · ${repo.locationLabel.split(',').first}', action: 'Map', onAction: () => context.go('/explore')),
                          for (final p in nearby) _NearbyCard(provider: p, onTap: () => _openProvider(p.id)),
                          SectionTitle(title: 'Top Rated Near You', action: 'Explore', onAction: () => context.go('/explore')),
                          for (final p in recommended.take(2)) _NearbyCard(provider: p, onTap: () => _openProvider(p.id)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAllCategories(BuildContext context, List<CategoryModel> cats) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Categories', style: AppTheme.serif(22)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < cats.length; i++)
                    CategoryChip(
                      slug: cats[i].slug,
                      emoji: cats[i].emoji,
                      label: cats[i].label,
                      imageUrl: cats[i].imageUrl,
                      active: _activeCat == i,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _activeCat = i);
                        if (cats[i].slug != 'all') context.go('/explore?category=${cats[i].slug}');
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _feedPreview(BuildContext context, FeedPostModel post) => GestureDetector(
        onTap: () => context.go('/feed'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              KhadeImage(url: post.imageUrl, fallbackUrl: post.providerImageUrl ?? post.imageUrl),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                ),
              ),
              Positioned(
                left: 14, right: 14, bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.providerName, style: AppTheme.sans(13, color: AppColors.white, weight: FontWeight.w500)),
                    Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.sans(11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.userName,
    required this.tier,
    required this.locationLabel,
    required this.usingGps,
    required this.pinAdjusted,
    required this.unreadCount,
    required this.onOpenLocation,
    required this.onNotifications,
    required this.onProfile,
  });

  final String greeting;
  final String userName;
  final String tier;
  final String locationLabel;
  final bool usingGps;
  final bool pinAdjusted;
  final int unreadCount;
  final VoidCallback onOpenLocation;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
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
                      Text(greeting.toUpperCase(), style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1.2)),
                      Row(
                        children: [
                          Flexible(child: Text('$userName ✨', style: AppTheme.serif(22), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          TierBadge(tier: tier, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: onNotifications),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: unreadCount > 9 ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1) : null,
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 1.5)),
                          alignment: Alignment.center,
                          child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: AppTheme.sans(9, color: AppColors.white, weight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: onProfile,
                  child: CircleAvatar(radius: 17, backgroundColor: AppColors.matcha, child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'A', style: AppTheme.sans(13, color: AppColors.white, weight: FontWeight.w500))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onOpenLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pinAdjusted ? Icons.edit_location_alt : (usingGps ? Icons.my_location : Icons.location_on_outlined), size: 14, color: AppColors.matcha),
                    const SizedBox(width: 4),
                    Flexible(child: Text(locationLabel, style: AppTheme.sans(11, color: AppColors.matcha), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.matcha),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.search, size: 18, color: AppColors.soft),
          const SizedBox(width: 8),
          Text('Search services, providers, looks...', style: AppTheme.sans(13, color: const Color(0xFFBBBBBB))),
        ]),
      ),
    );
  }
}

class _ProviderCarousel extends StatelessWidget {
  const _ProviderCarousel({required this.providers, required this.onTap});
  final List<ProviderModel> providers;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = providers[i];
          return _RecCard(provider: p, onTap: () => onTap(p.id));
        },
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({required this.provider, required this.onTap});
  final ProviderModel provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: KhadeImage(
                url: provider.imageUrl,
                fallbackUrl: provider.imageUrl,
                gradient: [colorFromHex(provider.gradientStart), colorFromHex(provider.gradientEnd)],
                emojiSize: 32,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name, style: AppTheme.serif(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${provider.emoji} ${provider.category} · ⭐ ${provider.rating.toStringAsFixed(1)}', style: AppTheme.sans(10, color: AppColors.soft), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${provider.distanceKm}km · ${provider.priceLabel}', style: AppTheme.sans(11, color: AppColors.matcha, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.provider, required this.onTap});
  final ProviderModel provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72, height: 72,
                  child: KhadeImage(url: provider.imageUrl, fallbackUrl: provider.imageUrl, gradient: [colorFromHex(provider.gradientStart), colorFromHex(provider.gradientEnd)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: AppTheme.sans(14, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${provider.emoji} ${provider.category} · ⭐ ${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})', style: AppTheme.sans(11, color: AppColors.soft)),
                    Text('${provider.area} · ${provider.priceLabel}', style: AppTheme.sans(11, color: AppColors.matcha)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(8)),
                child: Text('${provider.distanceKm}km', style: AppTheme.sans(10, color: AppColors.matcha, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
