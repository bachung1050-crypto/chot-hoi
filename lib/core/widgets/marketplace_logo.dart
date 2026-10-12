import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import 'app_network_image.dart';

/// Marketplace logo; renders a brand-colored monogram when no logo URL exists.
class MarketplaceLogo extends StatelessWidget {
  const MarketplaceLogo({super.key, required this.marketplace, this.size = 18});

  final Marketplace marketplace;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final url = marketplace.logoUrl;
    if (url != null) {
      return SizedBox.square(
        dimension: size,
        child: AppNetworkImage(url: url, borderRadius: radius, iconSize: size * 0.6),
      );
    }
    final monogram = marketplace.monogram;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: marketplace.brandColor, borderRadius: radius),
      child: Text(
        monogram,
        maxLines: 1,
        style: TextStyle(
          color: AppColors.onDark,
          fontWeight: FontWeight.w900,
          fontSize: size * (monogram.length > 1 ? 0.34 : 0.6),
          height: 1,
        ),
      ),
    );
  }
}

/// Logo followed by the marketplace name.
class MarketplaceLabel extends StatelessWidget {
  const MarketplaceLabel({super.key, required this.marketplace, this.colored = false});

  final Marketplace marketplace;
  final bool colored;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarketplaceLogo(marketplace: marketplace, size: 16),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            marketplace.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colored ? marketplace.brandColor : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
