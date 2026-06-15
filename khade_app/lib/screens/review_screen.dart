import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.providerId, this.providerName = 'Provider', this.bookingId});

  final int providerId;
  final String providerName;
  final int? bookingId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_comment.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review'), backgroundColor: AppColors.redDark),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await KhadeRepository.instance.submitReview(
      providerId: widget.providerId,
      rating: _rating,
      comment: _comment.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review published! Thank you ✦'), backgroundColor: AppColors.matcha),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(KhadeRepository.instance.lastError ?? 'Failed to submit'), backgroundColor: AppColors.redDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = KhadeRepository.instance.reviewsForProvider(widget.providerId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          BackHeader(title: 'Leave a Review', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(widget.providerName, style: AppTheme.serif(22)),
                Text('How was your experience?', style: AppTheme.sans(13, color: AppColors.soft)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: AppColors.gold, size: 36),
                        onPressed: () => setState(() => _rating = i),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _comment,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, minimumSize: const Size(double.infinity, 48)),
                  child: Text(_submitting ? 'Publishing...' : 'Publish Review'),
                ),
                if (existing.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('RECENT REVIEWS', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 10),
                  for (final r in existing.take(5))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(r.rating, (_) => const Icon(Icons.star, size: 14, color: AppColors.gold)),
                              const Spacer(),
                              Text(r.authorName, style: AppTheme.sans(11, color: AppColors.soft)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(r.comment, style: AppTheme.sans(13, color: AppColors.mid)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
