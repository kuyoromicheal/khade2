import 'package:flutter/material.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_reel.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final posts = KhadeRepository.instance.feed;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              FeedReel(posts: posts),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('For You', style: AppTheme.sans(15, color: AppColors.white, weight: FontWeight.w600)),
                    const SizedBox(width: 24),
                    Text('Following', style: AppTheme.sans(15, color: Colors.white54)),
                  ],
                ),
              ),
              if (KhadeRepository.instance.isLive)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.matcha, borderRadius: BorderRadius.circular(8)),
                    child: Text('LIVE', style: AppTheme.sans(9, color: AppColors.white, weight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
