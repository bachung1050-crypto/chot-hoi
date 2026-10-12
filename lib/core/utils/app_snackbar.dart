import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final label = actionLabel;
    final action = onAction;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 2200),
          persist: false,
          content: Row(
            children: [
              Icon(icon, color: AppColors.onDark, size: 20),
              AppSpacing.gapMd,
              Expanded(child: Text(message)),
            ],
          ),
          action: label != null && action != null
              ? SnackBarAction(label: label, textColor: AppColors.primaryLight, onPressed: action)
              : null,
        ),
      );
  }
}
