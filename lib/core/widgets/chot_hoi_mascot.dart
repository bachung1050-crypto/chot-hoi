import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';

/// Chốt Hời AI robot mascot.
class ChotHoiMascot extends StatelessWidget {
  const ChotHoiMascot({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.aiMascot,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Chốt Hời AI',
      errorBuilder: (_, _, _) => Icon(Icons.smart_toy_rounded, size: size * 0.8, color: AppColors.ai),
    );
  }
}
