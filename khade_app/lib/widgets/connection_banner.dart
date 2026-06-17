import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/khade_repository.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        if (repo.isLoading) return const SizedBox.shrink();

        final live = repo.isLive;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: live ? AppColors.matchaPale : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: live ? AppColors.matcha.withValues(alpha: 0.3) : const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              Icon(live ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 16, color: live ? AppColors.matcha : const Color(0xFFC47D00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  live
                      ? repo.databaseMode == 'supabase'
                          ? 'Live · Supabase · ${repo.providers.length} providers'
                          : 'Live · ${repo.providers.length} providers from server'
                      : 'Offline · ${repo.providers.length} providers cached · ${repo.apiUrl}',
                  style: AppTheme.sans(11, color: live ? AppColors.matchaDeep : const Color(0xFFC47D00)),
                ),
              ),
              if (!live)
                TextButton(
                  onPressed: repo.refresh,
                  style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text('Retry', style: AppTheme.sans(11, color: AppColors.matcha)),
                ),
            ],
          ),
        );
      },
    );
  }
}
