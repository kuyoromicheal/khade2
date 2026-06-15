import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _activeCat = 0;
  String _query = '';
  ProviderFilters _filters = const ProviderFilters();

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
        final cats = repo.categories;
        final catLabel = cats.isNotEmpty ? cats[_activeCat.clamp(0, cats.length - 1)].label : 'All';
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
                              hintText: 'Search ${repo.providers.length} providers...',
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
                          onPressed: _openFilters,
                          style: IconButton.styleFrom(
                            backgroundColor: !_filters.isDefault ? AppColors.matchaPale : AppColors.cream,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          icon: Icon(Icons.tune, color: !_filters.isDefault ? AppColors.matcha : AppColors.soft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => CategoryChip(
                          emoji: cats[i].emoji,
                          label: cats[i].label,
                          imageUrl: cats[i].imageUrl,
                          active: _activeCat == i,
                          onTap: () => setState(() => _activeCat = i),
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
                  Text('${providers.length} providers', style: AppTheme.sans(12, color: AppColors.soft)),
                  const Spacer(),
                  if (_filters.area != null)
                    Chip(label: Text(_filters.area!, style: AppTheme.sans(10)), visualDensity: VisualDensity.compact),
                  if (_filters.verifiedOnly)
                    const Chip(label: Text('Verified', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
            Expanded(
              child: providers.isEmpty
                  ? Center(child: Text('No providers match your filters', style: AppTheme.sans(14, color: AppColors.soft)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
                      itemCount: providers.length,
                      itemBuilder: (_, i) {
                        final p = providers[i];
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/booking?providerId=${p.id}'),
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
                                          Text('⭐ ${p.rating.toStringAsFixed(1)} · ${p.distanceKm}km · ${p.etaLabel} · ${p.area}', style: AppTheme.sans(10, color: AppColors.soft), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
