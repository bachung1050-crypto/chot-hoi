import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_icons.dart';

/// 3D category illustration with a vector-icon fallback.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.iconKey, this.size = 32});

  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vector = Icon(AppIcons.category(iconKey), size: size * 0.85, color: AppIcons.categoryTint(iconKey));
    final asset = AppAssets.categoryImage(iconKey);
    if (asset == null) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: vector),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => vector,
    );
  }
}
