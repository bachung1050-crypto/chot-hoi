import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/marketplace_logo.dart';
import '../../../core/widgets/price_text.dart';
import '../../../mock/mock_categories.dart';
import '../../../models/deal_cart_item.dart';

class DealCartItemCard extends StatelessWidget {
  const DealCartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onBuy,
  });

  final DealCartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final icon = AppIcons.category(MockCategories.byId(product.categoryId).iconKey);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.product(product.id), extra: 'cart-${product.id}'),
            child: SizedBox.square(
              dimension: 84,
              child: Hero(
                tag: 'cart-${product.id}',
                child: AppNetworkImage(
                  url: product.imageUrl,
                  fallbackIcon: icon,
                  iconSize: 28,
                  borderRadius: AppRadius.brMd,
                ),
              ),
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
                    SizedBox.square(
                      dimension: 28,
                      child: IconButton(
                        tooltip: 'Xóa',
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                MarketplaceLabel(marketplace: item.offer.marketplace, colored: true),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: PriceText(
                        price: item.unitPrice,
                        originalPrice: product.originalPrice,
                        size: PriceTextSize.small,
                      ),
                    ),
                    if (item.discountPercent > 0) DiscountChip(percent: item.discountPercent),
                  ],
                ),
                AppSpacing.gapSm,
                Row(
                  children: [
                    _QuantityStepper(quantity: item.quantity, onChanged: onQuantityChanged),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: FilledButton(
                            onPressed: onBuy,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                              textStyle: AppTextStyles.label,
                            ),
                            child: const Text('Mua ngay'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  static const int maxQuantity = 9;

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, VoidCallback? onTap) => SizedBox.square(
      dimension: 30,
      child: IconButton(tooltip: tooltip, padding: EdgeInsets.zero, iconSize: 16, onPressed: onTap, icon: Icon(icon)),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, 'Giảm', quantity > 1 ? () => onChanged(quantity - 1) : null),
          SizedBox(
            width: 24,
            child: Text(Formatters.count(quantity), textAlign: TextAlign.center, style: AppTextStyles.label),
          ),
          button(Icons.add_rounded, 'Tăng', quantity < maxQuantity ? () => onChanged(quantity + 1) : null),
        ],
      ),
    );
  }
}
