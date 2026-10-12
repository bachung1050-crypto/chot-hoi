import 'package:flutter/material.dart';

import '../../models/deal_verdict.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Solid orange "-13%" badge placed over product images.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.brPill),
      child: Text(
        '-$percent%',
        style: AppTextStyles.caption.copyWith(color: AppColors.onDark, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

/// Verdict pill such as "🔥 Đáng mua" or the "🔥 DEAL HỜI" promo tag.
class DealBadge extends StatelessWidget {
  const DealBadge({super.key, required this.verdict}) : _hot = false;

  const DealBadge.hot({super.key}) : verdict = DealVerdict.mustBuy, _hot = true;

  final DealVerdict verdict;
  final bool _hot;

  Color get _color => switch (verdict) {
    DealVerdict.mustBuy => AppColors.primary,
    DealVerdict.goodPrice => AppColors.success,
    DealVerdict.consider => AppColors.warning,
    DealVerdict.wait => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final label = _hot ? '🔥 DEAL HỜI' : '${verdict.emoji} ${verdict.label}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.brPill),
      child: Text(
        label,
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
