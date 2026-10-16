import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ai_score_badge.dart';
import '../../../models/product.dart';
import '../../../models/review_summary.dart';

/// "Chốt Hời AI đánh giá" with the score block and highlight bullets.
class AiReviewCard extends StatelessWidget {
  const AiReviewCard({super.key, required this.product, this.reviewSummary, this.loading = false});

  final Product product;
  final ReviewSummary? reviewSummary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final summary = reviewSummary;
    final highlights = summary != null && summary.highlights.isNotEmpty
        ? summary.highlights
        : product.aiHighlights;
    final summaryText = summary?.summary.isNotEmpty == true
        ? summary!.summary
        : (product.aiSummary.isNotEmpty ? product.aiSummary : null);
    final score = summary?.aiScore ?? product.reviewAiScore ?? product.chotHoiScore;
    final totalReviews = summary?.totalReviews ?? product.reviewCount;

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
                  '✦ ${AppStrings.aiName} phân tích đánh giá',
                  style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (totalReviews > 0) ...[
            AppSpacing.gapSm,
            Text(
              '⭐ ${product.rating.toStringAsFixed(1)}/5 từ ${Formatters.compact(totalReviews)} đánh giá',
              style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ],
          AppSpacing.gapMd,
          if (loading && summary == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AiScoreGauge(score: score),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summaryText != null && summaryText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            summaryText,
                            style: AppTextStyles.small.copyWith(color: AppColors.text, height: 1.4),
                          ),
                        ),
                      for (final highlight in highlights.take(4))
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
            if (summary != null && summary.warnings.isNotEmpty) ...[
              AppSpacing.gapMd,
              Text('Điểm cần lưu ý', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
              AppSpacing.gapSm,
              for (final warning in summary.warnings.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.priority_high_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(child: Text(warning, style: AppTextStyles.small.copyWith(height: 1.35))),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Two-column pros/cons block.
class ProsConsCard extends StatelessWidget {
  const ProsConsCard({super.key, required this.product, this.reviewSummary});

  final Product product;
  final ReviewSummary? reviewSummary;

  @override
  Widget build(BuildContext context) {
    final pros = reviewSummary != null && reviewSummary!.pros.isNotEmpty ? reviewSummary!.pros : product.pros;
    final cons = reviewSummary != null && reviewSummary!.cons.isNotEmpty ? reviewSummary!.cons : product.cons;

    Widget column(String title, List<String> items, IconData icon, Color color) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.label.copyWith(color: color)),
            AppSpacing.gapSm,
            if (items.isEmpty)
              Text('Chưa có dữ liệu', style: AppTextStyles.small.copyWith(color: AppColors.textSecondary))
            else
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
        column('Ưu điểm', pros, Icons.add_circle_rounded, AppColors.success),
        AppSpacing.gapLg,
        column('Nhược điểm', cons, Icons.remove_circle_rounded, AppColors.danger),
      ],
    );
  }
}
