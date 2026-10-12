import 'marketplace.dart';
import 'product.dart';

enum ProductSort {
  recommended('Đề xuất tốt nhất'),
  priceLow('Giá thấp nhất'),
  ratingHigh('Đánh giá cao');

  const ProductSort(this.label);

  final String label;
}

class ProductFilter {
  const ProductFilter({
    this.minPrice = 0,
    this.maxPrice,
    this.brands = const {},
    this.marketplaces = const {},
    this.minRating = 0,
    this.purpose,
    this.sort = ProductSort.recommended,
  });

  static const int priceCeiling = 50000000;

  final int minPrice;
  final int? maxPrice;
  final Set<String> brands;
  final Set<MarketplaceCode> marketplaces;
  final double minRating;
  final String? purpose;
  final ProductSort sort;

  int get activeCount => [
    minPrice > 0 || maxPrice != null,
    brands.isNotEmpty,
    marketplaces.isNotEmpty,
    minRating > 0,
    purpose != null,
  ].where((active) => active).length;

  ProductFilter copyWith({
    int? minPrice,
    int? Function()? maxPrice,
    Set<String>? brands,
    Set<MarketplaceCode>? marketplaces,
    double? minRating,
    String? Function()? purpose,
    ProductSort? sort,
  }) {
    return ProductFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      brands: brands ?? this.brands,
      marketplaces: marketplaces ?? this.marketplaces,
      minRating: minRating ?? this.minRating,
      purpose: purpose != null ? purpose() : this.purpose,
      sort: sort ?? this.sort,
    );
  }

  bool matches(Product p) {
    final upper = maxPrice;
    if (p.currentPrice < minPrice) return false;
    if (upper != null && p.currentPrice > upper) return false;
    if (brands.isNotEmpty && !brands.contains(p.brand)) return false;
    if (marketplaces.isNotEmpty && !p.offers.any((o) => marketplaces.contains(o.marketplace.code))) {
      return false;
    }
    if (p.rating < minRating) return false;
    final need = purpose;
    if (need != null && !p.useCases.contains(need)) return false;
    return true;
  }

  /// Filters and sorts while preserving the incoming (relevance) order for [ProductSort.recommended].
  List<Product> apply(List<Product> source) {
    final result = source.where(matches).toList();
    switch (sort) {
      case ProductSort.recommended:
        break;
      case ProductSort.priceLow:
        result.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case ProductSort.ratingHigh:
        result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }
}
