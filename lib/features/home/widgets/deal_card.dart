import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/deal_badge.dart';
import '../../../core/widgets/rating_widget.dart';
import '../../../core/widgets/save_button.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../mock/mock_categories.dart';
import '../../../models/product.dart';

/// Compact "Deal hời hôm nay" card: image, discount, heart, name, price, rating.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.product, required this.heroTag, required this.width});

  final Product product;
  final String heroTag;
  final double width;

  @override
  Widget build(BuildContext context) {
    final icon = AppIcons.category(MockCategories.byId(product.categoryId).iconKey);
    return TapScale(
      onTap: () => context.push(AppRoutes.product(product.id), extra: heroTag),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.brMd, boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      fallbackIcon: icon,
                      iconSize: 28,
                      borderRadius: AppRadius.brSm,
                    ),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(top: 4, left: 4, child: DiscountBadge(percent: product.discountPercent)),
                  Positioned(top: 0, right: 0, child: SaveButton(product: product, elevated: false, size: 18)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 11, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.price(product.currentPrice),
                      style: AppTextStyles.price.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  RatingWidget(rating: product.rating, reviewCount: product.reviewCount, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
