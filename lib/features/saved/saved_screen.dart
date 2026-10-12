import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/product_horizontal_card.dart';
import '../../core/widgets/save_button.dart';
import '../../mock/mock_categories.dart';
import '../../models/product.dart';
import '../cart/providers/deal_cart_provider.dart';
import '../search/widgets/filter_chips.dart';
import 'providers/saved_products_provider.dart';

enum _SavedAction { addToCart, remove }

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String? _categoryId;

  void _onUnsaved(Product product) {
    AppSnackbar.show(
      context,
      'Đã bỏ lưu ${product.name}',
      icon: Icons.favorite_border_rounded,
      actionLabel: 'Hoàn tác',
      onAction: () => ref.read(savedProductsProvider.notifier).addSavedProduct(product),
    );
  }

  Future<void> _onAction(Product product, _SavedAction action) async {
    switch (action) {
      case _SavedAction.addToCart:
        final added = await ref.read(dealCartProvider.notifier).addToCart(product);
        if (!mounted) return;
        AppSnackbar.show(
          context,
          added ? 'Đã thêm vào Giỏ hời' : 'Sản phẩm đã có trong Giỏ hời',
          icon: Icons.shopping_cart_checkout_rounded,
          actionLabel: 'Xem giỏ',
          onAction: () => context.go(AppRoutes.cart),
        );
      case _SavedAction.remove:
        await ref.read(savedProductsProvider.notifier).removeSavedProduct(product.id);
        _onUnsaved(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedProductsProvider);
    final all = saved.value ?? const <Product>[];
    final categoryIds = {for (final p in all) p.categoryId}.toList();
    final selected = categoryIds.contains(_categoryId) ? _categoryId : null;
    final visible = selected == null ? all : all.where((p) => p.categoryId == selected).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(title: 'Sản phẩm đã lưu (${all.length})', onBack: () => context.go(AppRoutes.home)),
            if (all.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.screenPadding,
                  children: [
                    QuickFilterChip(
                      label: 'Tất cả',
                      selected: selected == null,
                      onTap: () => setState(() => _categoryId = null),
                    ),
                    for (final id in categoryIds) ...[
                      AppSpacing.gapSm,
                      QuickFilterChip(
                        label: MockCategories.byId(id).name,
                        selected: selected == id,
                        onTap: () => setState(() => _categoryId = id),
                      ),
                    ],
                  ],
                ),
              ),
            AppSpacing.gapMd,
            Expanded(
              child: saved.when(
                skipLoadingOnRefresh: true,
                loading: () => const Padding(padding: AppSpacing.screenPadding, child: ProductListSkeleton()),
                error: (error, _) =>
                    ErrorState(message: error.toString(), onRetry: () => ref.invalidate(savedProductsProvider)),
                data: (_) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: ref.read(savedProductsProvider.notifier).refresh,
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 420,
                              child: EmptyState(
                                icon: Icons.favorite_border_rounded,
                                title: 'Chưa có sản phẩm đã lưu',
                                message: 'Nhấn biểu tượng trái tim ở sản phẩm để lưu lại và theo dõi giá.',
                                actionLabel: 'Khám phá ngay',
                                onAction: () => context.go(AppRoutes.home),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => AppSpacing.gapMd,
                          itemBuilder: (context, index) {
                            final product = visible[index];
                            return ProductHorizontalCard(
                              product: product,
                              heroTag: 'saved-${product.id}',
                              showMarketplaces: false,
                              showDiscountOnImage: true,
                              trailing: Column(
                                children: [
                                  SaveButton(
                                    product: product,
                                    elevated: false,
                                    size: 20,
                                    onToggled: (nowSaved) {
                                      if (!nowSaved) _onUnsaved(product);
                                    },
                                  ),
                                  PopupMenuButton<_SavedAction>(
                                    tooltip: 'Tùy chọn',
                                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                                    onSelected: (action) => _onAction(product, action),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: _SavedAction.addToCart, child: Text('Thêm vào Giỏ hời')),
                                      PopupMenuItem(value: _SavedAction.remove, child: Text('Bỏ lưu')),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
