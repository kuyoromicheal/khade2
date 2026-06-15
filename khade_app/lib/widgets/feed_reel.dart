import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../utils/media_url.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_sheets.dart';
import '../widgets/khade_image.dart';

/// TikTok-style full-screen vertical feed reel with category-matched short videos.
class FeedReel extends StatefulWidget {
  const FeedReel({super.key, required this.posts, this.initialIndex = 0});

  final List<FeedPostModel> posts;
  final int initialIndex;

  @override
  State<FeedReel> createState() => _FeedReelState();
}

class _FeedReelState extends State<FeedReel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _controller.addListener(() {
      final page = _controller.page?.round();
      if (page != null && page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openComments(FeedPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedCommentSheet(postId: post.id, postCaption: post.caption),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return Center(child: Text('No posts yet', style: AppTheme.sans(14, color: AppColors.soft)));
    }

    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        return PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: widget.posts.length,
          itemBuilder: (_, i) {
            final post = widget.posts[i];
            final liked = repo.likedPostIds.contains(post.id);
            final saved = repo.savedPostIds.contains(post.id);
            return _ReelPage(
              key: ValueKey(post.id),
              post: post,
              active: i == _currentPage,
              liked: liked,
              saved: saved,
              likeCount: post.likes,
              onLike: () => repo.toggleLikePost(post.id),
              onSave: () {
                repo.toggleSavePost(post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(saved ? 'Removed from saved' : 'Saved to collection'), backgroundColor: AppColors.matcha, duration: const Duration(seconds: 1)),
                );
              },
              onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied'), backgroundColor: AppColors.matcha, duration: Duration(seconds: 1)),
              ),
              onComment: () => _openComments(post),
              onBook: () => context.push('/booking?providerId=${post.providerId}'),
            );
          },
        );
      },
    );
  }
}

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    super.key,
    required this.post,
    required this.active,
    required this.liked,
    required this.saved,
    required this.likeCount,
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onComment,
    required this.onBook,
  });

  final FeedPostModel post;
  final bool active;
  final bool liked;
  final bool saved;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onBook;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _video?.play();
      } else {
        _video?.pause();
      }
    }
    if (widget.post.videoUrl != oldWidget.post.videoUrl) {
      _disposeVideo();
      _initVideo();
    }
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
    _videoReady = false;
    _videoFailed = false;
  }

  VideoPlayerController _createVideoController(String url) {
    if (url.startsWith('assets/')) {
      return VideoPlayerController.asset(url);
    }
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }

  void _initVideo() {
    if (!widget.post.isVideo) return;
    final url = resolveMediaUrl(widget.post.videoUrl);
    if (url.isEmpty) {
      setState(() => _videoFailed = true);
      return;
    }
    _video = _createVideoController(url)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _videoReady = true;
          _videoFailed = false;
        });
        _video!.setLooping(true);
        _video!.setVolume(1.0);
        if (widget.active) _video!.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _videoReady = false;
          _videoFailed = true;
        });
      });
  }

  void _retryVideo() {
    _disposeVideo();
    _initVideo();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final showVideo = post.isVideo && _video != null && _videoReady;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showVideo)
          Stack(
            fit: StackFit.expand,
            children: [
              KhadeImage(url: post.imageUrl, fallbackUrl: post.providerImageUrl),
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(width: _video!.value.size.width, height: _video!.value.size.height, child: VideoPlayer(_video!)),
              ),
            ],
          )
        else
          KhadeImage(url: post.imageUrl, fallbackUrl: post.providerImageUrl, emojiSize: 72),
        if (post.isVideo && !_videoReady && !_videoFailed)
          const Center(child: CircularProgressIndicator(color: AppColors.white)),
        if (post.isVideo && _videoFailed)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 40),
                const SizedBox(height: 8),
                Text('Video unavailable', style: AppTheme.sans(12, color: Colors.white70)),
                TextButton(onPressed: _retryVideo, child: const Text('Retry')),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
        if (post.isVideo && showVideo)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 52,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(post.category, style: AppTheme.sans(10, color: AppColors.white)),
                ],
              ),
            ),
          ),
        if (post.badge != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 48,
            left: post.isVideo && showVideo ? 120 : 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
              child: Text(post.badge!, style: AppTheme.sans(11, color: AppColors.white)),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              KhadeAvatar(url: post.providerAvatarUrl, fallbackUrl: post.providerImageUrl ?? post.imageUrl, radius: 22),
              const SizedBox(height: 20),
              _ActionBtn(icon: widget.liked ? Icons.favorite : Icons.favorite_border, label: '${widget.likeCount}', color: widget.liked ? AppColors.red : AppColors.white, onTap: widget.onLike),
              const SizedBox(height: 16),
              _ActionBtn(icon: Icons.chat_bubble_outline, label: '${post.comments}', onTap: widget.onComment),
              const SizedBox(height: 16),
              _ActionBtn(icon: Icons.share_outlined, label: 'Share', onTap: widget.onShare),
              const SizedBox(height: 16),
              _ActionBtn(icon: widget.saved ? Icons.bookmark : Icons.bookmark_border, label: 'Save', color: widget.saved ? AppColors.gold : AppColors.white, onTap: widget.onSave),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 72,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('@${post.providerName.replaceAll(' ', '')}', style: AppTheme.sans(14, color: AppColors.white, weight: FontWeight.w600)),
              Text('${post.category} · ${post.area} · ⭐ ${post.rating.toStringAsFixed(1)}', style: AppTheme.sans(11, color: Colors.white70)),
              const SizedBox(height: 8),
              Text(post.caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTheme.sans(13, color: AppColors.white).copyWith(height: 1.4)),
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.onBook, style: FilledButton.styleFrom(backgroundColor: AppColors.matcha), child: const Text('Book Now')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, this.color = AppColors.white, this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.sans(10, color: AppColors.white)),
        ],
      ),
    );
  }
}
