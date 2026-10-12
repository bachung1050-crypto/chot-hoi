import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actionLabel = AppStrings.seeAll,
    this.actionColor = AppColors.primary,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final icon = leading;
    return Row(
      children: [
        if (icon != null) ...[icon, const SizedBox(width: 6)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              if (sub != null) Text(sub, style: AppTextStyles.small),
            ],
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: actionColor,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}
