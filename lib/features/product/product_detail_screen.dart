import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/marketplace_price_card.dart';
import '../../core/widgets/rating_widget.dart';
import '../../core/widgets/save_button.dart';
import '../../mock/mock_categories.dart';
import '../../models/marketplace.dart';
import '../../models/product.dart';
import '../auth/auth_guard.dart';
import '../cart/providers/deal_cart_provider.dart';
import '../profile/providers/profile_providers.dart';
import '../profile/widgets/price_alert_sheet.dart';
import '../saved/providers/saved_products_provider.dart';
import 'providers/product_providers.dart';
import 'providers/product_review_summary_provider.dart';
import 'widgets/ai_review_card.dart';
import 'widgets/price_history_chart.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId, this.heroTag});

  final String productId;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(selectedProductProvider(productId));
    final tag = heroTag ?? 'product-$productId';

    return product.when(
      data: (item) => item == null
          ? _MessageScaffold(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Không tìm thấy sản phẩm',
                message: 'Sản phẩm có thể đã ngừng bán hoặc liên kết không đúng.',
                actionLabel: 'Về trang chủ',
                onAction: () => context.go(AppRoutes.home),
              ),
            )
          : _ProductDetailView(product: item, heroTag: tag),
      loading: () => _MessageScaffold(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Hero(
                tag: tag,
                child: const ColoredBox(color: AppColors.surfaceMuted),
              ),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
      error: (error, _) => _MessageScaffold(
        child: ErrorState(message: error.toString(), onRetry: () => ref.invalidate(selectedProductProvider(productId))),
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.card),
      backgroundColor: AppColors.card,
      body: child,
    );
  }
}

class _ProductDetailView extends ConsumerWidget {
  const _ProductDetailView({required this.product, required this.heroTag});

  final Product product;
  final String heroTag;

  void _openMarketplace(BuildContext context, WidgetRef ref, MarketplaceOffer offer) {
    AppSnackbar.show(
      context,
      'Bản demo: chuyển tới ${offer.marketplace.name} với giá ${Formatters.price(offer.price)}',
      icon: Icons.open_in_new_rounded,
      actionLabel: 'Thêm vào giỏ',
      onAction: () => _addToCart(context, ref, offer: offer),
    );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref, {MarketplaceOffer? offer}) async {
    final chosen = offer ?? product.cheapestOffer;
    final added = await runUserAction(
      context,
      ref,
      () => ref.read(dealCartProvider.notifier).addToCart(product, offer: chosen),
    );
    if (added == null || !context.mounted) return;
    AppSnackbar.show(
      context,
      added
          ? 'Đã thêm vào Giỏ hời (${chosen.marketplace.name})'
          : 'Sản phẩm trên ${chosen.marketplace.name} đã có trong Giỏ hời',
      icon: Icons.shopping_cart_checkout_rounded,
      actionLabel: 'Xem giỏ',
      onAction: () => context.go(AppRoutes.cart),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheapest = product.cheapestOffer;
    final reviewSummaryAsync = ref.watch(productReviewSummaryProvider(product.id));
    final reviewSummary = reviewSummaryAsync.asData?.value;
    final reviewLoading = reviewSummaryAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Gallery(product: product, heroTag: heroTag),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    RatingWidget(rating: product.rating, reviewCount: product.reviewCount, showReviewWord: true),
                    if (product.soldCount > 0) ...[
                      Container(width: 1, height: 12, color: AppColors.border),
                      Text('Đã bán ${Formatters.compact(product.soldCount)}+', style: AppTextStyles.small),
                    ],
                  ],
                ),
                AppSpacing.gapSm,
                Text(product.name, style: AppTextStyles.h1.copyWith(fontSize: 26)),
                const SizedBox(height: 4),
                Text(product.tagline, style: AppTextStyles.body.copyWith(color: AppColors.text)),
                AppSpacing.gapMd,
                Row(
                  children: [
                    for (final badge in product.badges.take(3)) ...[
                      if (badge != product.badges.first) AppSpacing.gapSm,
                      Expanded(
                        flex: badge.length + 6,
                        child: _TrustBadge(label: badge),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapLg,
                AiReviewCard(product: product, reviewSummary: reviewSummary, loading: reviewLoading),
                AppSpacing.gapXl,
                _Section(
                  title: 'So sánh giá giữa các sàn',
                  child: Column(
                    children: [
                      for (final offer in product.sortedOffers)
                        MarketplacePriceCard(
                          offer: offer,
                          cheapestPrice: cheapest.price,
                          onTap: () => _openMarketplace(context, ref, offer),
                        ),
                    ],
                  ),
                ),
                AppSpacing.gapXl,
                PriceHistoryCard(product: product),
                AppSpacing.gapXl,
                _Section(
                  title: 'Ưu & nhược điểm',
                  child: ProsConsCard(product: product, reviewSummary: reviewSummary),
                ),
                AppSpacing.gapXl,
                _Section(
                  title: 'Mô tả sản phẩm',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SpecRow(label: 'Thương hiệu', value: product.brand),
                      _SpecRow(label: 'Danh mục', value: MockCategories.byId(product.categoryId).name),
                      _SpecRow(label: 'Cấu hình', value: product.specsSummary),
                      AppSpacing.gapSm,
                      Text(product.description, style: AppTextStyles.body.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        product: product,
        onAddToCart: () => _addToCart(context, ref),
        onBuy: () => _openMarketplace(context, ref, cheapest),
      ),
    );
  }
}

class _Gallery extends ConsumerStatefulWidget {
  const _Gallery({required this.product, required this.heroTag});

  final Product product;
  final String heroTag;

  @override
  ConsumerState<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends ConsumerState<_Gallery> {
  int _page = 0;

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.product.productUrl));
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Đã sao chép liên kết sản phẩm', icon: Icons.link_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.galleryUrls.isEmpty ? [product.imageUrl] : product.galleryUrls;
    final icon = AppIcons.category(MockCategories.byId(product.categoryId).iconKey);
    final topInset = MediaQuery.paddingOf(context).top;
    final hasAlert = ref.watch(priceAlertsProvider).value?.any((a) => a.product.id == product.id) ?? false;

    return ColoredBox(
      color: AppColors.card,
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final image = Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    topInset + AppSpacing.xxxl,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: AppNetworkImage(
                    url: images[index],
                    fit: BoxFit.contain,
                    fallbackIcon: icon,
                    iconSize: 64,
                    borderRadius: AppRadius.brLg,
                  ),
                );
                return index == 0 ? Hero(tag: widget.heroTag, child: image) : image;
              },
            ),
            Positioned(
              top: topInset + AppSpacing.sm,
              left: AppSpacing.md,
              child: _RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Quay lại',
                onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
              ),
            ),
            Positioned(
              top: topInset + AppSpacing.sm,
              right: AppSpacing.md,
              child: Column(
                children: [
                  SaveButton(product: product, size: 20),
                  AppSpacing.gapSm,
                  _RoundIconButton(icon: Icons.share_outlined, tooltip: 'Chia sẻ', onTap: () => _share(context)),
                  AppSpacing.gapSm,
                  _RoundIconButton(
                    icon: hasAlert ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    tooltip: 'Báo khi giảm giá',
                    onTap: () => showPriceAlertSheet(context, ref, product),
                  ),
                ],
              ),
            ),
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.brPill),
                child: Text(
                  '${_page + 1}/${images.length}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.card),
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 18, color: AppColors.text),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.text, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Borderless titled block on the white page.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
        AppSpacing.gapSm,
        child,
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: AppTextStyles.small)),
          Expanded(
            child: Text(value, style: AppTextStyles.small.copyWith(color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.product, required this.onAddToCart, required this.onBuy});

  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isProductSavedProvider(product.id));

    Future<void> toggleSave() async {
      final nowSaved = await runUserAction(
        context,
        ref,
        () => ref.read(savedProductsProvider.notifier).toggle(product),
      );
      if (nowSaved == null || !context.mounted) return;
      AppSnackbar.show(
        context,
        nowSaved ? 'Đã lưu sản phẩm' : 'Đã bỏ lưu sản phẩm',
        icon: nowSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        actionLabel: nowSaved ? 'Xem' : null,
        onAction: nowSaved ? () => context.go(AppRoutes.saved) : null,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.card, boxShadow: AppShadows.bottomBar),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: toggleSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: saved ? AppColors.primary : AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                  icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 20),
                  label: Text(saved ? 'Đã lưu' : 'Lưu'),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddToCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(0, 46),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: const Text('Thêm vào giỏ hời'),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: AppRadius.brMd),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(0, 50),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                  ),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                  label: Text('Mua trên ${product.marketplace.name}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
