import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class ChotHoiLogo extends StatelessWidget {
  const ChotHoiLogo({super.key, this.size = 30});

  /// Diameter of the round mark; the wordmark scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: size * 0.7, fontWeight: FontWeight.w800, letterSpacing: -0.2, height: 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
          child: Icon(Icons.task_alt_rounded, color: AppColors.onDark, size: size * 0.66),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'CHỐT ',
                style: textStyle.copyWith(color: AppColors.text),
              ),
              TextSpan(
                text: 'HỜI',
                style: textStyle.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
