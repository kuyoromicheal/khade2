import 'package:flutter/material.dart';
import '../constants/khade_categories.dart';
import '../constants/category_icons.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'provider_widgets.dart';

/// Two-row category grid (Fresha-style) with "More +" chip.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.onSeeAll,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onSeeAll;

  static const _matcha = CategoryIcons.matcha;

  @override
  Widget build(BuildContext context) {
    final preview = KhadeCategories.homePreview;
    final row1 = preview.take(5).toList();
    final row2 = preview.skip(5).take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        children: [
          _row(row1, 0),
          const SizedBox(height: 10),
          Row(
            children: [
              ...row2.asMap().entries.map((e) => Expanded(child: _chip(preview.indexOf(e.value), e.value))),
              Expanded(child: _moreChip(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<CategoryModel> cats, int offset) {
    return Row(
      children: cats.asMap().entries.map((e) {
        final idx = KhadeCategories.home.indexOf(e.value);
        return Expanded(child: _chip(idx, e.value));
      }).toList(),
    );
  }

  Widget _chip(int index, CategoryModel cat) {
    final active = activeIndex == index;
    return CategoryChip(
      slug: cat.slug,
      label: cat.label,
      emoji: cat.emoji,
      imageUrl: cat.imageUrl,
      active: active,
      onTap: () => onTap(index),
    );
  }

  Widget _moreChip(BuildContext context) {
    return GestureDetector(
      onTap: onSeeAll ?? () {},
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                color: AppColors.white,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: _matcha, size: 26),
            ),
            const SizedBox(height: 6),
            Text('More +', style: AppTheme.sans(10, color: AppColors.mid), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
