import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import 'app_colors.dart';

/// Maps backend-friendly string keys to icons and accent colors.
abstract final class AppIcons {
  static IconData category(String iconKey) => switch (iconKey) {
    'laptop' => Icons.laptop_mac_rounded,
    'headphones' => Icons.headphones_rounded,
    'phone' => Icons.smartphone_rounded,
    'mouse' => Icons.mouse_rounded,
    'keyboard' => Icons.keyboard_rounded,
    'monitor' => Icons.desktop_windows_rounded,
    'watch' => Icons.watch_rounded,
    'accessory' => Icons.cable_rounded,
    'home' => Icons.blender_rounded,
    'fashion' => Icons.checkroom_rounded,
    _ => Icons.shopping_bag_outlined,
  };

  static Color categoryTint(String iconKey) => switch (iconKey) {
    'laptop' || 'fashion' || 'mouse' => AppColors.primary,
    'phone' || 'headphones' || 'watch' => AppColors.ai,
    'home' || 'monitor' => AppColors.tiki,
    _ => AppColors.success,
  };
}

extension MarketplaceStyle on Marketplace {
  Color get brandColor => switch (code) {
    MarketplaceCode.shopee => AppColors.shopee,
    MarketplaceCode.tiktokShop => AppColors.tiktokShop,
    MarketplaceCode.lazada => AppColors.lazada,
    MarketplaceCode.tiki => AppColors.tiki,
  };

  String get monogram => switch (code) {
    MarketplaceCode.shopee => 'S',
    MarketplaceCode.tiktokShop => 'T',
    MarketplaceCode.lazada => 'L',
    MarketplaceCode.tiki => 'tiki',
  };
}
