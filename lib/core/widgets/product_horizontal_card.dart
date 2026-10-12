import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_categories.dart';
import '../../models/product.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/formatters.dart';
import 'ai_score_badge.dart';
import 'app_network_image.dart';
import 'deal_badge.dart';
import 'marketplace_logo.dart';
import 'price_text.dart';
import 'rating_widget.dart';
import 'save_button.dart';
import 'tap_scale.dart';

/// Image-left product row used for AI results, recommendations and saved items.
class ProductHorizontalCard extends StatelessWidget {
  const ProductHorizontalCard({
    super.key,
    required this.product,
    required this.heroTag,
    this.rank,
    this.showScore = false,
    this.showMarketplaces = true,
    this.showDiscountOnImage = false,
    this.elevated = false,
    this.trailing,
  });

  final Product product;
  final String heroTag;

  /// Shows a 1/2/3 medal badge when set.
  final int? rank;
  final bool showScore;
  final bool showMarketplaces;
  final bool showDiscountOnImage;

  /// Borderless card with a soft shadow, larger image and a single red price row.
  final bool elevated;

  /// Replaces the default [SaveButton].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final category = MockCategories.byId(product.categoryId);
    final position = rank;

    return TapScale(
      scale: 0.98,
      onTap: () => context.push('/product/${product.id}', extra: heroTag),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.brLg,
          border: elevated ? null : Border.all(color: AppColors.border),
          boxShadow: elevated ? AppShadows.card : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: elevated ? 100 : 92,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      fallbackIcon: AppIcons.category(category.iconKey),
                      iconSize: 28,
                      borderRadius: AppRadius.brMd,
                    ),
                  ),
                  if (position != null) Positioned(top: 6, left: 6, child: _RankBadge(rank: position)),
                  if (showDiscountOnImage && product.discountPercent > 0)
                    Positioned(top: 4, left: 4, child: DiscountBadge(percent: product.discountPercent)),
                ],
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (elevated) trailing ?? SaveButton(product: product, elevated: false, size: 20),
                    ],
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
                  if (elevated)
                    _InlinePrice(product: product)
                  else
                    PriceText(
                      price: product.currentPrice,
                      originalPrice: product.originalPrice,
                      discountPercent: product.discountPercent,
                      size: PriceTextSize.small,
                    ),
                  if (showScore) ...[
                    AppSpacing.gapSm,
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AiScoreBadge(score: product.chotHoiScore, showMax: true),
                        DealBadge(verdict: product.verdict),
                      ],
                    ),
                  ],
                  if (showMarketplaces && elevated) ...[
                    AppSpacing.gapSm,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          for (final offer in product.sortedOffers.take(3)) ...[
                            if (offer != product.sortedOffers.first) const SizedBox(width: 10),
                            MarketplaceLabel(marketplace: offer.marketplace),
                          ],
                        ],
                      ),
                    ),
                  ] else if (showMarketplaces) ...[
                    AppSpacing.gapSm,
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final offer in product.sortedOffers.take(3))
                          MarketplaceLabel(marketplace: offer.marketplace),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!elevated) ...[AppSpacing.gapXs, trailing ?? SaveButton(product: product, elevated: false, size: 20)],
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.rankSecond,
      3 => AppColors.rankThird,
      _ => AppColors.textTertiary,
    };
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(color: AppColors.onDark, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// "23.490.000đ  26.990.000đ  -13%" on one line.
class _InlinePrice extends StatelessWidget {
  const _InlinePrice({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final original = product.originalPrice;
    final hasOriginal = original > product.currentPrice;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            Formatters.price(product.currentPrice),
            style: AppTextStyles.price.copyWith(fontSize: 17, color: AppColors.danger),
          ),
          if (hasOriginal) ...[AppSpacing.gapSm, Text(Formatters.price(original), style: AppTextStyles.priceOld)],
          if (product.discountPercent > 0) ...[AppSpacing.gapSm, DiscountChip(percent: product.discountPercent)],
        ],
      ),
    );
  }
}
