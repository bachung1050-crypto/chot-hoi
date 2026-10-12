import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Screen title row: optional back arrow, title and trailing actions.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.showBack = true, this.onBack, this.actions = const []});

  final String title;
  final bool showBack;

  /// Defaults to popping the route, or going Home when nothing can be popped.
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.text),
              onPressed:
                  onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
            )
          else
            const SizedBox(width: AppSpacing.screen),
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h2),
          ),
          ...actions,
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
