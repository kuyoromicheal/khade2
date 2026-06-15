import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ExploreFilterSheet extends StatefulWidget {
  const ExploreFilterSheet({super.key, required this.initial});

  final ProviderFilters initial;

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late int _minPrice;
  late int _maxPrice;
  late double _maxDistance;
  String? _area;
  late String _sortBy;
  late bool _verifiedOnly;

  static const _areas = ['Wuse II', 'Maitama', 'Garki', 'Gwarinpa', 'Asokoro', 'Utako', 'Jabi'];

  @override
  void initState() {
    super.initState();
    _minPrice = widget.initial.minPrice;
    _maxPrice = widget.initial.maxPrice;
    _maxDistance = widget.initial.maxDistance;
    _area = widget.initial.area;
    _sortBy = widget.initial.sortBy;
    _verifiedOnly = widget.initial.verifiedOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Filters & Sort', style: AppTheme.serif(22)),
              const SizedBox(height: 20),
              Text('PRICE RANGE (₦)', style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1)),
              RangeSlider(
                values: RangeValues(_minPrice.toDouble(), _maxPrice.toDouble()),
                min: 0,
                max: 50000,
                divisions: 50,
                activeColor: AppColors.matcha,
                labels: RangeLabels('₦$_minPrice', '₦$_maxPrice'),
                onChanged: (v) => setState(() { _minPrice = v.start.round(); _maxPrice = v.end.round(); }),
              ),
              Text('MAX DISTANCE: ${_maxDistance.toStringAsFixed(0)} km', style: AppTheme.sans(12, color: AppColors.mid)),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 25,
                divisions: 24,
                activeColor: AppColors.matcha,
                onChanged: (v) => setState(() => _maxDistance = v),
              ),
              Text('AREA', style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All areas'),
                    selected: _area == null,
                    onSelected: (_) => setState(() => _area = null),
                    selectedColor: AppColors.matchaPale,
                  ),
                  for (final a in _areas)
                    FilterChip(
                      label: Text(a),
                      selected: _area == a,
                      onSelected: (_) => setState(() => _area = a),
                      selectedColor: AppColors.matchaPale,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('SORT BY', style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final opt in [
                    ('featured', 'Featured'),
                    ('distance', 'Nearest'),
                    ('price_asc', 'Price ↑'),
                    ('price_desc', 'Price ↓'),
                    ('rating', 'Top rated'),
                  ])
                    ChoiceChip(
                      label: Text(opt.$2),
                      selected: _sortBy == opt.$1,
                      onSelected: (_) => setState(() => _sortBy = opt.$1),
                      selectedColor: AppColors.matchaPale,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Verified only', style: AppTheme.sans(13)),
                value: _verifiedOnly,
                activeThumbColor: AppColors.matcha,
                onChanged: (v) => setState(() => _verifiedOnly = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, const ProviderFilters()),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        ProviderFilters(
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          maxDistance: _maxDistance,
                          area: _area,
                          sortBy: _sortBy,
                          verifiedOnly: _verifiedOnly,
                        ),
                      ),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.matcha),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedCommentSheet extends StatefulWidget {
  const FeedCommentSheet({super.key, required this.postId, required this.postCaption});

  final int postId;
  final String postCaption;

  @override
  State<FeedCommentSheet> createState() => _FeedCommentSheetState();
}

class _FeedCommentSheetState extends State<FeedCommentSheet> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await KhadeRepository.instance.loadComments(widget.postId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await KhadeRepository.instance.addComment(widget.postId, text);
    if (mounted) {
      setState(() => _sending = false);
      if (ok) _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Text('Comments', style: AppTheme.serif(20)),
            ListenableBuilder(
              listenable: KhadeRepository.instance,
              builder: (context, _) {
                final count = KhadeRepository.instance.commentsForPost(widget.postId).length;
                return Text('$count comments', style: AppTheme.sans(11, color: AppColors.soft));
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.matcha))
                  : ListenableBuilder(
                      listenable: KhadeRepository.instance,
                      builder: (context, _) {
                        final comments = KhadeRepository.instance.commentsForPost(widget.postId);
                        if (comments.isEmpty) {
                          return Center(child: Text('Be the first to comment', style: AppTheme.sans(13, color: AppColors.soft)));
                        }
                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (_, i) {
                            final c = comments[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(radius: 16, backgroundColor: AppColors.matchaPale, child: Text(c.authorName[0], style: AppTheme.sans(12, color: AppColors.matcha))),
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
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: AppColors.cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(Icons.send, color: _sending ? AppColors.soft : AppColors.matcha),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
