import 'package:flutter/material.dart';

import '../../models/marketplace.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/formatters.dart';
import 'marketplace_logo.dart';

/// One marketplace row in the price comparison list.
class MarketplacePriceCard extends StatelessWidget {
  const MarketplacePriceCard({super.key, required this.offer, required this.cheapestPrice, required this.onTap});

  static const double _logoSize = 28;

  final MarketplaceOffer offer;
  final int cheapestPrice;
  final VoidCallback onTap;

  bool get _isCheapest => offer.price == cheapestPrice;

  @override
  Widget build(BuildContext context) {
    final diff = Formatters.percentDiff(offer.price, cheapestPrice);
    final details = _OfferDetails.of(offer);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MarketplaceLogo(marketplace: offer.marketplace, size: _logoSize),
                AppSpacing.gapMd,
                Expanded(
                  flex: 4,
                  child: Text(
                    offer.marketplace.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  flex: 7,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 20,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.price(offer.price),
                            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      AppSpacing.gapSm,
                      if (!_isCheapest)
                        Text(
                          '($diff)',
                          style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                      const Spacer(),
                      if (_isCheapest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.brSm),
                          child: Text(
                            '🔥 Rẻ nhất',
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.caption.copyWith(color: AppColors.onDark, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (details != null)
              Padding(
                padding: const EdgeInsets.only(left: _logoSize + AppSpacing.md, top: AppSpacing.xs),
                child: details,
              ),
          ],
        ),
      ),
    );
  }
}

/// Secondary line: old price, discount, rating, seller and stock. Hidden when the
/// offer carries none of these (e.g. mock data).
class _OfferDetails extends StatelessWidget {
  const _OfferDetails(this.offer);

  static _OfferDetails? of(MarketplaceOffer offer) {
    final hasAny =
        offer.discountPercent > 0 || offer.rating != null || offer.sellerName != null || offer.stockStatus != null;
    return hasAny ? _OfferDetails(offer) : null;
  }

  final MarketplaceOffer offer;

  static String _stockLabel(String status) => switch (status) {
    'in_stock' => 'Còn hàng',
    'low_stock' => 'Sắp hết hàng',
    'out_of_stock' => 'Hết hàng',
    'pre_order' => 'Đặt trước',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: AppColors.textSecondary);
    final original = offer.originalPrice;
    final rating = offer.rating;
    final reviews = offer.reviewCount ?? 0;
    final seller = offer.sellerName;
    final stock = offer.stockStatus;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (offer.discountPercent > 0 && original != null) ...[
          Text(Formatters.price(original), style: AppTextStyles.priceOld.copyWith(fontSize: 12)),
          Text(
            '-${offer.discountPercent}%',
            style: style.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700),
          ),
        ],
        if (rating != null && rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
              const SizedBox(width: 2),
              Text(
                reviews > 0
                    ? '${rating.toStringAsFixed(1)} (${Formatters.compact(reviews)})'
                    : rating.toStringAsFixed(1),
                style: style,
              ),
            ],
          ),
        if (seller != null && seller.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(seller, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        if (stock != null)
          Text(
            _stockLabel(stock),
            style: style.copyWith(
              color: offer.inStock ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
