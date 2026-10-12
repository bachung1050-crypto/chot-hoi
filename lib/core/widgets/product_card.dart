import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_categories.dart';
import '../../models/product.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'app_network_image.dart';
import 'deal_badge.dart';
import 'marketplace_logo.dart';
import 'price_text.dart';
import 'rating_widget.dart';
import 'save_button.dart';
import 'tap_scale.dart';

/// Vertical product card for the 2-column results grid.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.heroTag});

  final Product product;

  /// Must be unique per screen; passed to the detail route for the Hero flight.
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final category = MockCategories.byId(product.categoryId);
    return TapScale(
      onTap: () => context.push('/product/${product.id}', extra: heroTag),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.brLg, boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      fallbackIcon: AppIcons.category(category.iconKey),
                      borderRadius: AppRadius.brMd,
                    ),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(top: 6, left: 6, child: DiscountBadge(percent: product.discountPercent)),
                  Positioned(top: 2, right: 2, child: SaveButton(product: product, elevated: false, size: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 4, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.specsSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RatingWidget(rating: product.rating, reviewCount: product.reviewCount, size: 13),
                  const SizedBox(height: AppSpacing.xs),
                  PriceText(
                    price: product.currentPrice,
                    originalPrice: product.originalPrice,
                    discountPercent: product.discountPercent,
                    size: PriceTextSize.small,
                  ),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Flexible(child: MarketplaceLabel(marketplace: product.marketplace)),
                      const SizedBox(width: 6),
                      Text(
                        product.inStock ? 'Còn hàng' : 'Hết hàng',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: product.inStock ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
