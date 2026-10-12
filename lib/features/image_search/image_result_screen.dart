import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/marketplace_logo.dart';
import '../../core/widgets/product_horizontal_card.dart';
import '../../core/widgets/tap_scale.dart';
import '../../models/image_search_result.dart';
import '../../models/marketplace.dart';
import 'providers/image_search_controller.dart';
import 'widgets/image_search_widgets.dart';

/// Step 4: recognised product, attributes and the same product on each marketplace.
class ImageResultScreen extends ConsumerStatefulWidget {
  const ImageResultScreen({super.key});

  @override
  ConsumerState<ImageResultScreen> createState() => _ImageResultScreenState();
}

class _ImageResultScreenState extends ConsumerState<ImageResultScreen> {
  bool _showSimilar = false;

  Future<void> _share(ImageSearchResult result) async {
    await Clipboard.setData(ClipboardData(text: result.product.productUrl));
    if (!mounted) return;
    AppSnackbar.show(context, 'Đã sao chép liên kết sản phẩm', icon: Icons.link_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(imageSearchProvider).result;

    if (result == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'Kết quả tìm kiếm'),
              Expanded(
                child: EmptyState(
                  icon: Icons.image_search_rounded,
                  title: 'Chưa có kết quả',
                  message: 'Hãy chụp hoặc chọn một ảnh sản phẩm để bắt đầu.',
                  actionLabel: 'Tìm bằng hình ảnh',
                  onAction: () => context.pushReplacement(AppRoutes.imageSearch),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final product = result.product;
    final cheapest = product.cheapestOffer;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Kết quả tìm kiếm',
              actions: [
                IconButton(
                  tooltip: 'Chia sẻ',
                  onPressed: () => _share(result),
                  icon: const Icon(Icons.ios_share_rounded, color: AppColors.text),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  _RecognizedCard(result: result),
                  AppSpacing.gapXl,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Sản phẩm tương tự ',
                          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: '(${result.resultCount} kết quả)', style: AppTextStyles.small),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                  for (final offer in product.sortedOffers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _OfferRow(
                        offer: offer,
                        originalPrice: product.originalPrice,
                        isCheapest: offer == cheapest,
                        onTap: () => context.push(AppRoutes.imageDeal),
                      ),
                    ),
                  if (result.similarProducts.isNotEmpty) ...[
                    AppSpacing.gapXs,
                    TapScale(
                      scale: 0.98,
                      onTap: () => setState(() => _showSimilar = !_showSimilar),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.brMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _showSimilar
                                    ? 'Ẩn sản phẩm tương tự'
                                    : 'Xem thêm ${result.similarProducts.length} sản phẩm tương tự',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showSimilar ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: AppColors.text,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showSimilar)
                      for (final similar in result.similarProducts)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: ProductHorizontalCard(
                            product: similar,
                            heroTag: 'image-${similar.id}',
                            elevated: true,
                          ),
                        ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: GradientActionButton(
                label: 'Xem đánh giá deal',
                icon: Icons.local_fire_department_rounded,
                showChevron: true,
                onPressed: () => context.push(AppRoutes.imageDeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizedCard extends StatelessWidget {
  const _RecognizedCard({required this.result});

  final ImageSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.brLg, boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 120,
                child: AppNetworkImage(
                  url: result.imageUrl,
                  borderRadius: AppRadius.brMd,
                  fallbackIcon: Icons.headphones_rounded,
                  iconSize: 40,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppStrings.aiName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text('Có vẻ là', style: AppTextStyles.small.copyWith(color: AppColors.text)),
                    Text(
                      result.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: const BoxDecoration(color: AppColors.aiLight, borderRadius: AppRadius.brSm),
                      child: Text(
                        'Độ chính xác: ${result.accuracyPercent}%',
                        style: AppTextStyles.caption.copyWith(color: AppColors.aiDeep, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in result.tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.brSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(tag, style: AppTextStyles.caption.copyWith(color: AppColors.text)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer, required this.originalPrice, required this.isCheapest, required this.onTap});

  final MarketplaceOffer offer;
  final int originalPrice;
  final bool isCheapest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            MarketplaceLogo(marketplace: offer.marketplace, size: 32),
            AppSpacing.gapMd,
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      offer.marketplace.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (isCheapest) ...[
                    const SizedBox(width: 6),
                    const Flexible(
                      child: FittedBox(fit: BoxFit.scaleDown, child: _CheapestTag()),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapSm,
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.price(offer.price),
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isCheapest ? AppColors.danger : AppColors.text,
                      ),
                    ),
                    if (originalPrice > offer.price)
                      Text(Formatters.price(originalPrice), style: AppTextStyles.priceOld),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _CheapestTag extends StatelessWidget {
  const _CheapestTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(color: AppColors.danger, borderRadius: AppRadius.brSm),
      child: Text(
        'Rẻ nhất',
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(color: AppColors.onDark, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
