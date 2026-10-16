import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/ai_score_badge.dart';
import '../../../core/widgets/chot_hoi_mascot.dart';
import '../../../mock/mock_categories.dart';
import '../../../models/ai_score_explanation.dart';
import '../../../models/product_recommendation.dart';
import '../../../models/search_result.dart';

/// Mascot card "Tìm thấy N sản phẩm" introducing the ranked results.
/// When [best] is set, also shows the Chốt Hời AI fit score + explanation.
class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({super.key, required this.intent, required this.count, this.best});

  final SearchIntent intent;
  final int count;
  final ProductRecommendation? best;

  String get _description {
    final categoryId = intent.categoryId;
    final subject = categoryId == null ? 'sản phẩm' : MockCategories.byId(categoryId).name.toLowerCase();
    return 'Dưới đây là những $subject phù hợp nhất cho nhu cầu của bạn.';
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = best;
    final explanation = recommendation?.explanation;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
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
              const ChotHoiMascot(size: 64),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm thấy $count sản phẩm',
                      style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(_description, style: AppTextStyles.small.copyWith(height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
          if (recommendation != null) ...[
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.72),
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.ai.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '✦ Chốt Hời AI',
                          style: AppTextStyles.label.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                        ),
                      ),
                      AiScoreBadge(score: recommendation.score, showMax: true),
                    ],
                  ),
                  if (explanation != null) ...[
                    const SizedBox(height: 8),
                    _VerdictChip(verdict: explanation.verdict),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Phù hợp nhất với nhu cầu của bạn',
                    style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    explanation?.summary.isNotEmpty == true ? explanation!.summary : recommendation.reason,
                    style: AppTextStyles.small.copyWith(height: 1.4),
                  ),
                  if (_reasonLines(recommendation, explanation).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '👍 Vì sao đáng xem',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final line in _reasonLines(recommendation, explanation).take(4))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: AppRadius.brPill,
                            ),
                            child: Text(
                              line,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (explanation?.priceInsight?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InsightLine(label: '💰 Giá', text: explanation!.priceInsight!),
                  ],
                  if (explanation?.reviewInsight?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _InsightLine(label: '⭐ Đánh giá', text: explanation!.reviewInsight!),
                  ],
                  if (explanation?.matchInsight?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    _InsightLine(label: '🎯 Khớp nhu cầu', text: explanation!.matchInsight!),
                  ],
                  if (_warningLines(recommendation, explanation).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Lưu ý',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    for (final warning in _warningLines(recommendation, explanation).take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• $warning', style: AppTextStyles.caption.copyWith(height: 1.35)),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<String> _reasonLines(ProductRecommendation rec, AiScoreExplanation? explanation) {
    if (explanation != null && explanation.reasons.isNotEmpty) return explanation.reasons;
    return rec.pros;
  }

  static List<String> _warningLines(ProductRecommendation rec, AiScoreExplanation? explanation) {
    if (explanation != null && explanation.warnings.isNotEmpty) return explanation.warnings;
    return rec.cons;
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});

  final String verdict;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (verdict == AiScoreExplanation.verdictBuy) {
      bg = AppColors.successLight;
      fg = AppColors.success;
    } else if (verdict == AiScoreExplanation.verdictAvoid) {
      bg = AppColors.dangerLight;
      fg = AppColors.danger;
    } else {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brPill),
      child: Text(verdict, style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          TextSpan(text: text, style: AppTextStyles.caption.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}
