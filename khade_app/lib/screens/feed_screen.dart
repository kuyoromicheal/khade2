import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_post_card.dart';

enum FeedTab { forYou, following, trending }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedTab _tab = FeedTab.forYou;
  bool _refreshing = false;

  List<dynamic> get _posts {
    final repo = KhadeRepository.instance;
    return switch (_tab) {
      FeedTab.forYou => repo.feedForYou(),
      FeedTab.following => repo.feedFollowing(),
      FeedTab.trending => repo.feedTrending(),
    };
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await KhadeRepository.instance.initialize();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final posts = _posts;
        final stories = repo.storyProviders();

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text('khade', style: AppTheme.serif(22, color: AppColors.matchaDeep)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: AppColors.matcha),
                        onPressed: () => context.push('/videos'),
                        tooltip: 'Watch looks',
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _tabBtn('For You', FeedTab.forYou),
                    _tabBtn('Following', FeedTab.following),
                    _tabBtn('Trending', FeedTab.trending),
                  ],
                ),
                if (stories.isNotEmpty)
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: stories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final p = stories[i];
                        return GestureDetector(
                          onTap: () => context.push('/provider/${p.id}'),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.matcha, width: 2)),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.matchaPale,
                                  child: Text(p.emoji, style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 64,
                                child: Text(p.name.split(' ').first, style: AppTheme.sans(9), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: posts.isEmpty
                      ? Center(child: Text('No posts yet', style: AppTheme.sans(14, color: AppColors.soft)))
                      : RefreshIndicator(
                          color: AppColors.matcha,
                          onRefresh: _refresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: posts.length,
                            itemBuilder: (_, i) => FeedPostCard(post: posts[i]),
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

  Widget _tabBtn(String label, FeedTab tab) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Text(label, style: AppTheme.sans(13, color: active ? AppColors.matcha : AppColors.soft, weight: active ? FontWeight.w600 : FontWeight.w400)),
            if (active) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 24, color: AppColors.matcha),
          ],
        ),
      ),
    );
  }
}
