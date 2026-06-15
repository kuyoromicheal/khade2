import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/khade_image.dart';
import '../widgets/provider_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCat = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final user = repo.user;
        final cats = repo.categories;
        final catLabel = cats.isNotEmpty ? cats[_activeCat.clamp(0, cats.length - 1)].label : 'All';
        final featured = repo.featured;
        final topProviders = repo.byCategory(catLabel);

        return Column(
          children: [
            _HomeHeader(
              userName: user?.name.split(' ').first ?? 'Guest',
              onNotifications: () => context.push('/notifications'),
              onProfile: () => context.go('/profile'),
            ),
            Expanded(
              child: repo.isLoading
                  ? const LoadingPlaceholder()
                  : RefreshIndicator(
                      color: AppColors.matcha,
                      onRefresh: repo.refresh,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const ConnectionBanner(),
                          _SearchBar(onTap: () => context.go('/explore')),
                          if (cats.isNotEmpty)
                            _CategoryRow(
                              categories: cats,
                              active: _activeCat,
                              onTap: (i) => setState(() => _activeCat = i),
                            ),
                          _PromoBanner(onBook: () => context.push('/booking?providerId=${featured.isNotEmpty ? featured.first.id : 1}')),
                          SectionTitle(title: 'Featured Near You', action: 'See all', onAction: () => context.go('/explore')),
                          _FeaturedRow(providers: featured.take(10).toList()),
                          SectionTitle(title: 'Top Providers', action: '${repo.providers.length} total', onAction: () => context.go('/explore')),
                          for (final p in topProviders.take(5)) _providerCard(context, p),
                          SectionTitle(title: 'Inspiration', action: 'See all', onAction: () => context.go('/feed')),
                          for (final post in repo.feed.take(1)) _feedPreview(context, post),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _providerCard(BuildContext context, ProviderModel p) => ProviderCard(
        emoji: p.emoji,
        name: p.name,
        category: p.category,
        rating: p.rating.toStringAsFixed(1),
        reviews: p.reviewCount,
        distance: p.distanceLabel,
        area: p.area,
        price: p.priceLabel,
        badge: p.badge ?? 'Verified',
        gradient: [colorFromHex(p.gradientStart), colorFromHex(p.gradientEnd)],
        imageUrl: p.imageUrl,
        onTap: () => context.push('/booking?providerId=${p.id}'),
      );

  Widget _feedPreview(BuildContext context, FeedPostModel post) => GestureDetector(
        onTap: () => context.go('/feed'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 200,
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
              const Positioned(right: 14, top: 14, child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32)),
            ],
          ),
        ),
      );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userName, required this.onNotifications, required this.onProfile});
  final String userName;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GOOD MORNING', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
                    Text('$userName ✨', style: AppTheme.serif(24)),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(icon: const Icon(Icons.notifications_outlined, size: 22), onPressed: onNotifications),
                        Positioned(top: 10, right: 10, child: Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.cream, width: 1.5)))),
                      ],
                    ),
                    GestureDetector(
                      onTap: onProfile,
                      child: CircleAvatar(radius: 17, backgroundColor: AppColors.matcha, child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'A', style: AppTheme.sans(13, color: AppColors.white, weight: FontWeight.w500))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.matcha),
                const SizedBox(width: 4),
                Text('Maitama, Abuja', style: AppTheme.sans(11, color: AppColors.matcha)),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.matcha),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [const Icon(Icons.search, size: 18, color: AppColors.soft), const SizedBox(width: 8), Text('Search ${KhadeRepository.instance.providers.length} providers...', style: AppTheme.sans(13, color: const Color(0xFFBBBBBB)))]),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories, required this.active, required this.onTap});
  final List<CategoryModel> categories;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => CategoryChip(
          emoji: categories[i].emoji,
          label: categories[i].label,
          imageUrl: categories[i].imageUrl,
          active: active == i,
          onTap: () => onTap(i),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onBook});
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.matchaDeep, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Text('✦ LIMITED OFFER', style: AppTheme.sans(10, color: AppColors.gold).copyWith(letterSpacing: 2)),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your first\nbooking is on us', style: AppTheme.serif(22, weight: FontWeight.w300, color: AppColors.cream)),
                const SizedBox(height: 12),
                FilledButton(onPressed: onBook, style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.dark, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), minimumSize: Size.zero), child: Text('Book Now →', style: AppTheme.sans(11, weight: FontWeight.w500))),
              ],
            ),
          ),
          const Positioned(right: 0, top: 20, child: Text('🌿', style: TextStyle(fontSize: 52, color: Color(0x4DFFFFFF)))),
        ],
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.providers});
  final List<ProviderModel> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final p in providers)
            _FeatCard(
              emoji: p.emoji,
              name: p.name,
              sub: '⭐ ${p.rating.toStringAsFixed(1)} · ${p.distanceKm}km',
              price: p.priceLabel,
              imageUrl: p.imageUrl,
              colors: [colorFromHex(p.gradientStart), colorFromHex(p.gradientEnd)],
              onTap: () => context.push('/booking?providerId=${p.id}'),
            ),
        ],
      ),
    );
  }
}

class _FeatCard extends StatelessWidget {
  const _FeatCard({required this.emoji, required this.name, required this.sub, required this.price, required this.onTap, required this.colors, this.imageUrl});
  final String emoji, name, sub, price;
  final String? imageUrl;
  final VoidCallback onTap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 110, child: KhadeImage(url: imageUrl, fallbackUrl: imageUrl, gradient: colors, emojiSize: 36)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.serif(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(sub, style: AppTheme.sans(10, color: AppColors.soft)),
                  Text(price, style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
