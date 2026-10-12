import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/marketplace_logo.dart';
import '../../models/marketplace.dart';
import '../../models/product.dart';
import '../../models/product_filter.dart';
import 'widgets/filter_chips.dart';

/// Products being filtered plus the filter currently applied.
class FilterScreenArgs {
  const FilterScreenArgs({required this.products, required this.initial});

  final List<Product> products;
  final ProductFilter initial;
}

/// Full filter page. Pops with the chosen [ProductFilter].
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, this.args});

  final FilterScreenArgs? args;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  static const double _priceStep = 1000000;
  static const List<double> _ratingOptions = [0, 4, 4.5, 4.8];
  static const int _collapsedBrandCount = 8;

  late ProductFilter _filter = widget.args?.initial ?? const ProductFilter();
  bool _showAllBrands = false;

  List<Product> get _products => widget.args?.products ?? const [];

  List<String> get _brands {
    final counts = <String, int>{};
    for (final p in _products) {
      counts[p.brand] = (counts[p.brand] ?? 0) + 1;
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  List<Marketplace> get _marketplaces {
    final seen = <MarketplaceCode, Marketplace>{};
    for (final p in _products) {
      for (final o in p.offers) {
        seen[o.marketplace.code] = o.marketplace;
      }
    }
    return seen.values.toList()..sort((a, b) => a.code.index.compareTo(b.code.index));
  }

  int get _matchCount => _products.where(_filter.matches).length;

  void _toggleBrand(String brand) {
    final brands = {..._filter.brands};
    if (!brands.remove(brand)) brands.add(brand);
    setState(() => _filter = _filter.copyWith(brands: brands));
  }

  void _toggleMarketplace(MarketplaceCode code) {
    final marketplaces = {..._filter.marketplaces};
    if (!marketplaces.remove(code)) marketplaces.add(code);
    setState(() => _filter = _filter.copyWith(marketplaces: marketplaces));
  }

  void _reset() {
    setState(() => _filter = ProductFilter(sort: _filter.sort));
  }

  @override
  Widget build(BuildContext context) {
    const ceiling = ProductFilter.priceCeiling;
    final range = RangeValues(
      _filter.minPrice.toDouble().clamp(0, ceiling.toDouble()),
      (_filter.maxPrice ?? ceiling).toDouble().clamp(0, ceiling.toDouble()),
    );
    final brands = _brands;
    final visibleBrands = _showAllBrands ? brands : brands.take(_collapsedBrandCount).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Bộ lọc',
              actions: [TextButton(onPressed: _reset, child: const Text('Xóa tất cả'))],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
                children: [
                  _SectionTitle(
                    'Khoảng giá',
                    trailing:
                        '${Formatters.shortMillions(range.start.round())} - '
                        '${range.end >= ceiling ? '${Formatters.shortMillions(ceiling)}+' : Formatters.shortMillions(range.end.round())}',
                  ),
                  RangeSlider(
                    values: range,
                    max: ceiling.toDouble(),
                    divisions: (ceiling / _priceStep).round(),
                    labels: RangeLabels(
                      Formatters.shortMillions(range.start.round()),
                      Formatters.shortMillions(range.end.round()),
                    ),
                    onChanged: (values) => setState(() {
                      final upper = values.end.round();
                      _filter = _filter.copyWith(
                        minPrice: values.start.round(),
                        maxPrice: () => upper >= ceiling ? null : upper,
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final mark in const [0, 10000000, 25000000, 50000000])
                          Text(mark == 0 ? '0đ' : Formatters.shortMillions(mark), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  const _SectionTitle('Thương hiệu'),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      QuickFilterChip(
                        label: 'Tất cả',
                        selected: _filter.brands.isEmpty,
                        onTap: () => setState(() => _filter = _filter.copyWith(brands: const {})),
                      ),
                      for (final brand in visibleBrands)
                        QuickFilterChip(
                          label: brand,
                          selected: _filter.brands.contains(brand),
                          onTap: () => _toggleBrand(brand),
                        ),
                      if (brands.length > _collapsedBrandCount)
                        TextButton(
                          onPressed: () => setState(() => _showAllBrands = !_showAllBrands),
                          child: Text(_showAllBrands ? 'Thu gọn' : 'Xem thêm'),
                        ),
                    ],
                  ),
                  AppSpacing.gapXl,
                  const _SectionTitle('Sàn thương mại điện tử'),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final marketplace in _marketplaces)
                        _MarketplaceCheck(
                          marketplace: marketplace,
                          checked: _filter.marketplaces.contains(marketplace.code),
                          onTap: () => _toggleMarketplace(marketplace.code),
                        ),
                    ],
                  ),
                  AppSpacing.gapXl,
                  const _SectionTitle('Đánh giá tối thiểu'),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final rating in _ratingOptions)
                        QuickFilterChip(
                          label: rating == 0 ? 'Tất cả' : '$rating+',
                          icon: rating == 0 ? null : Icons.star_rounded,
                          selected: _filter.minRating == rating,
                          onTap: () => setState(() => _filter = _filter.copyWith(minRating: rating)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.card, boxShadow: AppShadows.bottomBar),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _reset, child: const Text('Đặt lại')),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    flex: 2,
                    child: FilledButton(onPressed: () => context.pop(_filter), child: Text('Áp dụng ($_matchCount)')),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final value = trailing;
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h3)),
        if (value != null) Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

class _MarketplaceCheck extends StatelessWidget {
  const _MarketplaceCheck({required this.marketplace, required this.checked, required this.onTap});

  final Marketplace marketplace;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.md, 4),
        decoration: BoxDecoration(
          color: checked ? AppColors.primaryLight : AppColors.card,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: checked ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 32,
              child: Checkbox(value: checked, onChanged: (_) => onTap()),
            ),
            MarketplaceLogo(marketplace: marketplace),
            const SizedBox(width: 6),
            Text(marketplace.name, style: AppTextStyles.small.copyWith(color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
