import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/ai_score_badge.dart';
import '../../../models/product.dart';

/// "Chốt Hời AI đánh giá" with the score block and highlight bullets.
class AiReviewCard extends StatelessWidget {
  const AiReviewCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.aiBubble, AppColors.aiLight],
        ),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.brSm),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  '${AppStrings.aiName} đánh giá',
                  style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AiScoreGauge(score: product.chotHoiScore),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  children: [
                    for (final highlight in product.aiHighlights)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                highlight,
                                style: AppTextStyles.small.copyWith(color: AppColors.text, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two-column pros/cons block.
class ProsConsCard extends StatelessWidget {
  const ProsConsCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    Widget column(String title, List<String> items, IconData icon, Color color) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.label.copyWith(color: color)),
            AppSpacing.gapSm,
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item, style: AppTextStyles.small.copyWith(color: AppColors.text)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column('Ưu điểm', product.pros, Icons.add_circle_rounded, AppColors.success),
        AppSpacing.gapLg,
        column('Nhược điểm', product.cons, Icons.remove_circle_rounded, AppColors.danger),
      ],
    );
  }
}
