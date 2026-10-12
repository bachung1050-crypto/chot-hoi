import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/product_card.dart';
import '../../mock/mock_categories.dart';
import '../../models/product.dart';
import '../../models/product_filter.dart';
import 'filter_screen.dart';
import 'providers/search_results_provider.dart';
import 'widgets/filter_chips.dart';

/// 2-column grid of products for a keyword query or a category.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query, this.categoryId});

  final String query;
  final String? categoryId;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  ProductFilter _filter = const ProductFilter();

  ResultsQuery get _args => (query: widget.query, categoryId: widget.categoryId);

  String get _title {
    final categoryId = widget.categoryId;
    if (categoryId != null) return MockCategories.byId(categoryId).name;
    return widget.query.isEmpty ? 'Tất cả sản phẩm' : widget.query;
  }

  Future<void> _openFilter(List<Product> products) async {
    final result = await context.push<ProductFilter>(
      AppRoutes.filter,
      extra: FilterScreenArgs(products: products, initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  Future<void> _pickSort() async {
    final sort = await showModalBottomSheet<ProductSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ProductSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _filter.sort ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            AppSpacing.gapSm,
          ],
        ),
      ),
    );
    if (sort != null) setState(() => _filter = _filter.copyWith(sort: sort));
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_args));
    final all = results.value ?? const <Product>[];
    final products = _filter.apply(all);
    final upper = _filter.maxPrice;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: AppRadius.brPill,
                      onTap: () => context.go(AppRoutes.search),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.brPill,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            AppSpacing.gapSm,
                            Expanded(
                              child: Text(
                                _title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screenPadding,
                children: [
                  QuickFilterChip(
                    label: _filter.activeCount > 0 ? 'Bộ lọc (${_filter.activeCount})' : 'Bộ lọc',
                    icon: Icons.tune_rounded,
                    selected: _filter.activeCount > 0,
                    onTap: () => _openFilter(all),
                  ),
                  AppSpacing.gapSm,
                  QuickFilterChip(
                    label: upper != null ? 'Dưới ${Formatters.shortMillions(upper)}' : 'Giá',
                    icon: Icons.keyboard_arrow_down_rounded,
                    selected: upper != null || _filter.minPrice > 0,
                    onTap: () => _openFilter(all),
                  ),
                  AppSpacing.gapSm,
                  QuickFilterChip(
                    label: _filter.brands.isEmpty ? 'Thương hiệu' : _filter.brands.join(', '),
                    icon: Icons.keyboard_arrow_down_rounded,
                    selected: _filter.brands.isNotEmpty,
                    onTap: () => _openFilter(all),
                  ),
                  AppSpacing.gapSm,
                  QuickFilterChip(
                    label: _filter.minRating > 0 ? '${_filter.minRating}+ sao' : 'Đánh giá',
                    icon: Icons.keyboard_arrow_down_rounded,
                    selected: _filter.minRating > 0,
                    onTap: () => _openFilter(all),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.when(
                loading: () =>
                    const Padding(padding: EdgeInsets.all(AppSpacing.screen), child: ProductListSkeleton(count: 4)),
                error: (error, _) =>
                    ErrorState(message: error.toString(), onRetry: () => ref.invalidate(searchResultsProvider(_args))),
                data: (_) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.refresh(searchResultsProvider(_args).future),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Expanded(child: Text('Tìm thấy ${products.length} sản phẩm', style: AppTextStyles.h3)),
                              TextButton.icon(
                                onPressed: _pickSort,
                                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                                label: Text(_filter.sort.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (products.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Không có sản phẩm phù hợp',
                            message: 'Thử bỏ bớt bộ lọc hoặc tìm với từ khóa khác.',
                            actionLabel: _filter.activeCount > 0 ? 'Bỏ lọc' : null,
                            onAction: _filter.activeCount > 0
                                ? () => setState(() => _filter = ProductFilter(sort: _filter.sort))
                                : null,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xl),
                          sliver: SliverGrid.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisExtent: 330,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index], heroTag: 'grid-${products[index].id}'),
                          ),
                        ),
                    ],
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
