import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/product_filter.dart';

/// Pill chip that turns orange when selected, or solid [selectedFill] when given.
class QuickFilterChip extends StatelessWidget {
  const QuickFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedFill,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedFill;

  @override
  Widget build(BuildContext context) {
    final fill = selectedFill;
    final solid = selected && fill != null;
    final color = solid ? AppColors.onDark : (selected ? AppColors.primary : AppColors.text);
    final leading = icon;
    return Material(
      color: solid ? fill : (selected ? AppColors.primaryLight : AppColors.card),
      shape: StadiumBorder(side: BorderSide(color: solid ? fill : (selected ? AppColors.primary : AppColors.border))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[Icon(leading, size: 16, color: color), const SizedBox(width: 4)],
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square icon button that opens the full filter screen, with an active-count badge.
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({super.key, required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: activeCount > 0,
      backgroundColor: AppColors.ai,
      label: Text('$activeCount'),
      child: Material(
        color: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brSm,
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: AppRadius.brSm,
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.tune_rounded, size: 18, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}

/// "Đề xuất tốt nhất / Giá thấp nhất / Đánh giá cao" separate pill tabs.
class SortTabs extends StatelessWidget {
  const SortTabs({super.key, required this.selected, required this.onChanged});

  final ProductSort selected;
  final ValueChanged<ProductSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final sort in ProductSort.values) ...[
          if (sort != ProductSort.values.first) AppSpacing.gapSm,
          Expanded(
            flex: sort.label.length,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(sort),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 9),
                decoration: ShapeDecoration(
                  color: sort == selected ? AppColors.aiLight : AppColors.card,
                  shape: StadiumBorder(
                    side: BorderSide(color: sort == selected ? AppColors.aiLight : AppColors.border),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    sort.label,
                    maxLines: 1,
                    style: AppTextStyles.small.copyWith(
                      color: sort == selected ? AppColors.ai : AppColors.text,
                      fontWeight: sort == selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
