import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/khade_image.dart';

class SavedProvidersScreen extends StatelessWidget {
  const SavedProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final saved = KhadeRepository.instance.savedProviders;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              BackHeader(title: 'Saved Providers', onBack: () => context.pop()),
              Expanded(
                child: saved.isEmpty
                    ? Center(child: Text('No saved providers yet.\nTap ♥ on Explore to save.', style: AppTheme.sans(14, color: AppColors.soft), textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: saved.length,
                        itemBuilder: (_, i) {
                          final p = saved[i];
                          return GestureDetector(
                            onTap: () => context.push('/booking?providerId=${p.id}'),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  SizedBox(width: 80, height: 80, child: KhadeImage(url: p.imageUrl, fallbackUrl: p.imageUrl, emojiSize: 28)),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name, style: AppTheme.serif(15)),
                                          Text('${p.category} · ⭐ ${p.rating.toStringAsFixed(1)}', style: AppTheme.sans(11, color: AppColors.soft)),
                                          Text(p.priceLabel, style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: AppColors.red),
                                    onPressed: () => KhadeRepository.instance.toggleSaveProvider(p.id),
                                  ),
                                ],
                              ),
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
}
