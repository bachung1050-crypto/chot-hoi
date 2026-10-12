import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/formatters.dart';

enum PriceTextSize { small, medium, large }

/// Current price in brand orange, with the struck-through original price and discount.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.size = PriceTextSize.medium,
  });

  final int price;
  final int? originalPrice;
  final int? discountPercent;
  final PriceTextSize size;

  @override
  Widget build(BuildContext context) {
    final priceStyle = switch (size) {
      PriceTextSize.small => AppTextStyles.price.copyWith(fontSize: 14),
      PriceTextSize.medium => AppTextStyles.price,
      PriceTextSize.large => AppTextStyles.priceLarge,
    };
    final original = originalPrice;
    final discount = discountPercent;
    final showOriginal = original != null && original > price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(Formatters.price(price), style: priceStyle),
        ),
        if (showOriginal)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    Formatters.price(original),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: size == PriceTextSize.large
                        ? AppTextStyles.priceOld.copyWith(fontSize: 14)
                        : AppTextStyles.priceOld,
                  ),
                ),
                if (discount != null && discount > 0) ...[const SizedBox(width: 6), DiscountChip(percent: discount)],
              ],
            ),
          ),
      ],
    );
  }
}

/// Soft "-13%" chip used next to prices.
class DiscountChip extends StatelessWidget {
  const DiscountChip({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.brSm),
      child: Text(
        '-$percent%',
        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
