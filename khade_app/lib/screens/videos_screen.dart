import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_reel.dart';

/// TikTok-style vertical video feed (separate from photo Feed tab).
class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final posts = KhadeRepository.instance.videoFeed;
        if (posts.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Looks')),
            body: Center(child: Text('No videos yet', style: AppTheme.sans(14, color: Colors.white54))),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              FeedReel(posts: posts),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
