import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/tap_scale.dart';

/// Robot hero banner opening the AI search. The artwork is transparent PNG
/// with the robot breaking out of the card, so it is not clipped.
class AiBanner extends StatelessWidget {
  const AiBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${AppStrings.aiName}. ${AppStrings.tagline}',
      child: TapScale(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: AppAssets.aiBannerAspectRatio,
          child: Image.asset(
            AppAssets.aiBanner,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: AppRadius.brLg),
            ),
          ),
        ),
      ),
    );
  }
}
