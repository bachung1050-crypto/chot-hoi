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

  final MarketplaceOffer offer;
  final int cheapestPrice;
  final VoidCallback onTap;

  bool get _isCheapest => offer.price == cheapestPrice;

  @override
  Widget build(BuildContext context) {
    final diff = Formatters.percentDiff(offer.price, cheapestPrice);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            MarketplaceLogo(marketplace: offer.marketplace, size: 28),
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
                        'Rẻ nhất',
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
      ),
    );
  }
}
