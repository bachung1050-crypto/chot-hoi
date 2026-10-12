import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: color),
            ),
            AppSpacing.gapXl,
            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
            AppSpacing.gapSm,
            Text(message, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            if (label != null && onAction != null) ...[
              AppSpacing.gapXl,
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Ôi, có lỗi rồi',
      message: message,
      color: AppColors.danger,
      actionLabel: onRetry == null ? null : 'Thử lại',
      onAction: onRetry,
    );
  }
}
