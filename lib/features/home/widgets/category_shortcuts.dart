import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../models/category.dart';

/// Row of five category tiles under the search bar.
class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({super.key, required this.categories, required this.onSelected});

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final category in categories)
          Expanded(
            child: TapScale(
              onTap: () => onSelected(category),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.card, AppColors.categoryTint(category.iconKey)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.card, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.categoryTint(category.iconKey).withValues(alpha: 0.9),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CategoryIcon(iconKey: category.iconKey, size: 38),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Đang đáng mua" lavender chips with a category illustration.
class WorthBuyingChips extends StatelessWidget {
  const WorthBuyingChips({super.key, required this.categories, required this.onSelected});

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: categories.length,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
        itemBuilder: (context, index) {
          final category = categories[index];
          return TapScale(
            onTap: () => onSelected(category),
            child: Container(
              padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.aiLight, borderRadius: AppRadius.brMd),
              child: Row(
                children: [
                  CategoryIcon(iconKey: category.iconKey, size: 26),
                  const SizedBox(width: 6),
                  Text(category.name, style: AppTextStyles.caption.copyWith(color: AppColors.text, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
