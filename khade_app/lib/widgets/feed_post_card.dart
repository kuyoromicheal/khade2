import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_comment_sheet.dart';
import '../widgets/khade_image.dart';

class FeedPostCard extends StatefulWidget {
  const FeedPostCard({super.key, required this.post});
  final FeedPostModel post;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late bool _liked;
  late int _likes;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _liked = KhadeRepository.instance.likedPostIds.contains(widget.post.id);
    _likes = widget.post.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    KhadeRepository.instance.toggleLikePost(widget.post.id);
  }

  void _onImageTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 300)) {
      if (!_liked) _toggleLike();
    }
    _lastTap = now;
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedCommentSheet(postId: widget.post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final saved = KhadeRepository.instance.savedPostIds.contains(p.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/provider/${p.providerId}'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.matchaPale,
                    child: Text(p.providerEmoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/provider/${p.providerId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nameLine, style: AppTheme.sans(13, weight: FontWeight.w600)),
                        Text('${p.category} · ⭐ ${p.rating.toStringAsFixed(1)}', style: AppTheme.sans(10, color: AppColors.soft)),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/provider/${p.providerId}'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
                  child: Text('Book', style: AppTheme.sans(11, color: Colors.white)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _onImageTap,
            child: AspectRatio(
              aspectRatio: 1,
              child: KhadeImage(url: p.imageUrl, fallbackUrl: p.providerImageUrl, emoji: p.imageEmoji, emojiSize: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
            child: Row(
              children: [
                IconButton(onPressed: _toggleLike, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.red : AppColors.dark, size: 26)),
                IconButton(onPressed: _openComments, icon: const Icon(Icons.chat_bubble_outline, size: 26)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, size: 26)),
                const Spacer(),
                IconButton(
                  onPressed: () => KhadeRepository.instance.toggleSavePost(p.id),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 26),
                ),
              ],
            ),
          ),
          if (_likes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('$_likes ${_likes == 1 ? 'like' : 'likes'}', style: AppTheme.sans(12, weight: FontWeight.w600)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: RichText(
              text: TextSpan(
                style: AppTheme.sans(12, color: AppColors.mid),
                children: [
                  TextSpan(text: '${p.providerName} ', style: AppTheme.sans(12, weight: FontWeight.w600, color: AppColors.dark)),
                  TextSpan(text: p.caption),
                ],
              ),
            ),
          ),
          if (p.comments > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: GestureDetector(
                onTap: _openComments,
                child: Text('View all ${p.comments} comments', style: AppTheme.sans(11, color: AppColors.soft)),
              ),
            ),
        ],
      ),
    );
  }
}

extension on FeedPostModel {
  String get nameLine => providerName;
}
