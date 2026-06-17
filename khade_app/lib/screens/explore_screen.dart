import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';
import '../widgets/filter_sheets.dart';
import '../widgets/khade_image.dart';
import '../widgets/provider_widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialCategorySlug});

  final String? initialCategorySlug;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int? _manualCat;
  String _query = '';
  ProviderFilters _filters = const ProviderFilters();
  String _viewMode = 'list'; // list | map
  ProviderModel? _selectedProvider;

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategorySlug != widget.initialCategorySlug) {
      _manualCat = null;
    }
  }

  int _activeCatIndex(List<CategoryModel> cats) {
    if (_manualCat != null) return _manualCat!.clamp(0, cats.length - 1);
    if (widget.initialCategorySlug != null && widget.initialCategorySlug!.isNotEmpty) {
      return KhadeRepository.instance.categoryIndexForSlug(widget.initialCategorySlug);
    }
    return 0;
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ProviderFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExploreFilterSheet(initial: _filters),
    );
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final cats = repo.displayCategories;
        final activeCat = _activeCatIndex(cats);
        final catLabel = cats.isNotEmpty ? cats[activeCat.clamp(0, cats.length - 1)].label : 'All';
        final providers = repo.filterProviders(categoryLabel: catLabel, query: _query, filters: _filters);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search providers, services, areas...',
                              hintStyle: AppTheme.sans(13, color: const Color(0xFFBBBBBB)),
                              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.soft),
                              filled: true,
                              fillColor: AppColors.cream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _viewMode = _viewMode == 'list' ? 'map' : 'list'),
                          style: IconButton.styleFrom(backgroundColor: AppColors.cream, side: const BorderSide(color: AppColors.border)),
                          icon: Icon(_viewMode == 'list' ? Icons.map_outlined : Icons.format_list_bulleted, color: AppColors.matcha),
                        ),
                        IconButton(
                          onPressed: _openFilters,
                          style: IconButton.styleFrom(
                            backgroundColor: !_filters.isDefault ? AppColors.matchaPale : AppColors.cream,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          icon: Icon(Icons.tune, color: !_filters.isDefault ? AppColors.matcha : AppColors.soft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('⚡ Solo Pros', _filters.soloProOnly, () {
                            setState(() => _filters = _filters.copyWith(soloProOnly: !_filters.soloProOnly, mobileOnly: false));
                          }),
                          _filterChip('🚗 Comes to me', _filters.mobileOnly, () {
                            setState(() => _filters = _filters.copyWith(mobileOnly: !_filters.mobileOnly, soloProOnly: false));
                          }),
                          _filterChip('Salon', _filters.venueType == 'salon', () {
                            setState(() => _filters = _filters.copyWith(venueType: _filters.venueType == 'salon' ? 'all' : 'salon', mobileOnly: false));
                          }),
                          _filterChip('Rating', _filters.sortBy == 'rating', () {
                            setState(() => _filters = _filters.copyWith(sortBy: 'rating'));
                          }),
                          _filterChip('Price ↑', _filters.sortBy == 'price_asc', () {
                            setState(() => _filters = _filters.copyWith(sortBy: 'price_asc'));
                          }),
                          _filterChip('Near', _filters.sortBy == 'distance', () {
                            setState(() => _filters = _filters.copyWith(sortBy: 'distance'));
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => CategoryChip(
                          slug: cats[i].slug,
                          emoji: cats[i].emoji,
                          label: cats[i].label,
                          imageUrl: cats[i].imageUrl,
                          active: activeCat == i,
                          onTap: () => setState(() => _manualCat = i),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const ConnectionBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text('${providers.length} providers nearby', style: AppTheme.sans(12, color: AppColors.soft)),
                  const Spacer(),
                  if (_filters.area != null)
                    Chip(label: Text(_filters.area!, style: AppTheme.sans(10)), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
            Expanded(
              child: _viewMode == 'map'
                  ? _MapView(providers: providers, selected: _selectedProvider, onSelect: (p) => setState(() => _selectedProvider = p), onOpen: (p) => context.push('/provider/${p.id}'))
                  : _ListView(providers: providers),
            ),
            if (_viewMode == 'map' && _selectedProvider != null)
              _MapBottomCard(provider: _selectedProvider!, onOpen: () => context.push('/provider/${_selectedProvider!.id}')),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: AppTheme.sans(11)),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.matchaPale,
        checkmarkColor: AppColors.matcha,
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.providers});
  final List<ProviderModel> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return Center(child: Text('No providers match your filters', style: AppTheme.sans(14, color: AppColors.soft)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
      itemCount: providers.length,
      itemBuilder: (_, i) => _ProviderTile(provider: providers[i]),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});
  final ProviderModel provider;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => context.push('/provider/${p.id}'),
          child: Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: KhadeImage(url: p.imageUrl, fallbackUrl: p.imageUrl, emoji: p.emoji, gradient: [colorFromHex(p.gradientStart), colorFromHex(p.gradientEnd)], emojiSize: 32)),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: AppTheme.sans(12, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        p.isSoloPro
                            ? '⚡ ${p.category} · Serves ${p.coverageLabel}'
                            : p.isMobileProvider && p.providerType != 'salon'
                                ? '🚗 ${p.baseArea ?? p.area}'
                                : '⭐ ${p.rating.toStringAsFixed(1)} · ${p.distanceKm}km · ${p.area}',
                        style: AppTheme.sans(10, color: AppColors.soft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(p.priceLabel, style: AppTheme.sans(11, color: AppColors.matcha, weight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => KhadeRepository.instance.toggleSaveProvider(p.id),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
              child: Icon(
                KhadeRepository.instance.isProviderSaved(p.id) ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: KhadeRepository.instance.isProviderSaved(p.id) ? AppColors.red : AppColors.soft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({required this.providers, required this.selected, required this.onSelect, required this.onOpen});
  final List<ProviderModel> providers;
  final ProviderModel? selected;
  final ValueChanged<ProviderModel> onSelect;
  final ValueChanged<ProviderModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final repo = KhadeRepository.instance;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(repo.userLat, repo.userLng),
        initialZoom: 12,
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.khade.app'),
        MarkerLayer(
          markers: [
            for (final p in providers)
              if (p.latitude != null && p.longitude != null)
                Marker(
                  point: LatLng(p.latitude!, p.longitude!),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => onSelect(p),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected?.id == p.id ? AppColors.matcha : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.matcha, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(p.rating.toStringAsFixed(1), style: AppTheme.sans(10, color: selected?.id == p.id ? Colors.white : AppColors.matcha, weight: FontWeight.w600)),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _MapBottomCard extends StatelessWidget {
  const _MapBottomCard({required this.provider, required this.onOpen});
  final ProviderModel provider;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.name, style: AppTheme.sans(14, weight: FontWeight.w600)),
                Text(provider.locationBadge, style: AppTheme.sans(11, color: AppColors.soft)),
                Text(provider.priceLabel, style: AppTheme.sans(12, color: AppColors.matcha)),
              ],
            ),
          ),
          FilledButton(onPressed: onOpen, style: FilledButton.styleFrom(backgroundColor: AppColors.matcha), child: const Text('View')),
        ],
      ),
    );
  }
}
