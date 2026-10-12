import 'package:flutter/material.dart';

import '../../models/deal_verdict.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Compact "✦ Chốt Hời 94" pill.
class AiScoreBadge extends StatelessWidget {
  const AiScoreBadge({super.key, required this.score, this.showMax = false});

  final int score;
  final bool showMax;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(color: AppColors.aiLight, borderRadius: AppRadius.brPill),
      child: Text(
        showMax ? '✦ Chốt Hời: $score/100' : '✦ Chốt Hời $score',
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(color: AppColors.ai, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Large "8.9/10 · Đáng mua" score block used in the AI review card.
class AiScoreGauge extends StatelessWidget {
  const AiScoreGauge({super.key, required this.score});

  /// 0-100 score.
  final int score;

  @override
  Widget build(BuildContext context) {
    final verdict = DealVerdict.fromScore(score);
    final color = score >= 80 ? AppColors.success : AppColors.warning;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          width: 108,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: score >= 80 ? AppColors.successLight : AppColors.warningLight,
            borderRadius: AppRadius.brMd,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.military_tech_rounded, color: color, size: 30),
                    Icon(Icons.auto_awesome_rounded, color: color, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: (value * 10).toStringAsFixed(1),
                        style: AppTextStyles.display.copyWith(fontSize: 32, color: color, height: 1.1),
                      ),
                      TextSpan(
                        text: '/10',
                        style: AppTextStyles.label.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                Text(
                  verdict.label,
                  style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
