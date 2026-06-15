import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class FeedCommentSheet extends StatefulWidget {
  const FeedCommentSheet({super.key, required this.postId});

  final int postId;

  @override
  State<FeedCommentSheet> createState() => _FeedCommentSheetState();
}

class _FeedCommentSheetState extends State<FeedCommentSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    KhadeRepository.instance.loadComments(widget.postId);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await KhadeRepository.instance.addComment(widget.postId, _text.text.trim());
    if (mounted) {
      _text.clear();
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final comments = KhadeRepository.instance.commentsForPost(widget.postId);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scroll) => Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${comments.length} Comments', style: AppTheme.serif(18)),
                ),
                Expanded(
                  child: comments.isEmpty
                      ? Center(child: Text('Be the first to comment', style: AppTheme.sans(13, color: AppColors.soft)))
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.matchaPale,
                                    child: Text(c.authorName.isNotEmpty ? c.authorName[0] : '?', style: AppTheme.sans(12, color: AppColors.matcha)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.authorName, style: AppTheme.sans(12, weight: FontWeight.w600)),
                                        Text(c.text, style: AppTheme.sans(13, color: AppColors.mid)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              filled: true,
                              fillColor: AppColors.cream,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(backgroundColor: AppColors.matcha),
                          icon: _sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send, size: 18),
                        ),
                      ],
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
}

void showFeedComments(BuildContext context, int postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FeedCommentSheet(postId: postId),
  );
}
