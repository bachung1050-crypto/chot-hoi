import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Soft purple card that frames any content produced by Chốt Hời AI.
class AiInsightCard extends StatelessWidget {
  const AiInsightCard({
    super.key,
    required this.title,
    required this.child,
    this.icon = Icons.auto_awesome_rounded,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.aiLight,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.ai.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.ai, size: 20),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w700),
                ),
              ),
              ?trailing,
            ],
          ),
          AppSpacing.gapMd,
          child,
        ],
      ),
    );
  }
}
