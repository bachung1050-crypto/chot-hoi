import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/chot_hoi_mascot.dart';
import '../../../mock/mock_categories.dart';
import '../../../models/search_result.dart';

/// Mascot card "Tìm thấy N sản phẩm" introducing the ranked results.
class ResultSummaryCard extends StatelessWidget {
  const ResultSummaryCard({super.key, required this.intent, required this.count});

  final SearchIntent intent;
  final int count;

  String get _description {
    final categoryId = intent.categoryId;
    final subject = categoryId == null ? 'sản phẩm' : MockCategories.byId(categoryId).name.toLowerCase();
    return 'Dưới đây là những $subject phù hợp nhất cho nhu cầu của bạn.';
  }

  @override
  Widget build(BuildContext context) {
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
      child: Row(
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
    );
  }
}
