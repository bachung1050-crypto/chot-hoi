import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';

/// Right-aligned chat bubble with the user's question.
class UserQueryBubble extends StatelessWidget {
  const UserQueryBubble({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.aiBubble,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            query,
            style: AppTextStyles.body.copyWith(color: AppColors.aiDeep, fontWeight: FontWeight.w500, height: 1.45),
          ),
        ),
      ),
    );
  }
}

/// Progress list "Đang phân tích yêu cầu..." with green check marks.
class SearchSteps extends StatelessWidget {
  const SearchSteps({
    super.key,
    required this.completedSteps,
    required this.isLoading,
    this.labels,
  });

  final int completedSteps;
  final bool isLoading;

  /// Optional override (agent tool status). Defaults to [AppStrings.searchSteps].
  final List<String>? labels;

  @override
  Widget build(BuildContext context) {
    final steps = labels ?? AppStrings.searchSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StepRow(
              label: steps[i],
              state: i < completedSteps || !isLoading
                  ? _StepState.done
                  : i == completedSteps
                  ? _StepState.running
                  : _StepState.pending,
            ),
          ),
      ],
    );
  }
}

enum _StepState { done, running, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = switch (state) {
      _StepState.done => const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
      _StepState.running => const SizedBox.square(
        dimension: 22,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.ai),
        ),
      ),
      _StepState.pending => const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.border, size: 22),
    };
    return Row(
      children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: indicator),
        AppSpacing.gapMd,
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: state == _StepState.pending ? AppColors.textTertiary : AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
