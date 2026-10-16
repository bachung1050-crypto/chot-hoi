import 'brand.dart';
import 'category_record.dart';
import 'json_read.dart';
import 'marketplace_product.dart';
import 'review_summary_record.dart';

/// Row of `public.products` with optional embedded `brands`, `categories`,
/// `marketplace_products` and `review_summaries`. Converted to the UI [Product]
/// by `ProductMapper`.
class ProductRecord {
  const ProductRecord({
    required this.id,
    required this.name,
    required this.slug,
    this.brandId,
    this.categoryId,
    this.description,
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.brand,
    this.category,
    this.marketplaceProducts = const [],
    this.reviewSummaries = const [],
    this.specs = const {},
  });

  factory ProductRecord.fromJson(Map<String, dynamic> json) {
    final brandJson = JsonRead.map(json['brands']);
    final categoryJson = JsonRead.map(json['categories']);
    final summaries = JsonRead.list(json['review_summaries']).map(ReviewSummaryRecord.fromJson).toList()
      ..sort((a, b) => (b.generatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.generatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ));
    return ProductRecord(
      id: json['id'] as String,
      brandId: json['brand_id'] as String?,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      rating: JsonRead.toDouble(json['rating']),
      reviewCount: JsonRead.toInt(json['review_count']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: JsonRead.toDate(json['created_at']),
      updatedAt: JsonRead.toDate(json['updated_at']),
      brand: brandJson == null ? null : Brand.fromJson(brandJson),
      category: categoryJson == null ? null : CategoryRecord.fromJson(categoryJson),
      marketplaceProducts: JsonRead.list(json['marketplace_products']).map(MarketplaceProduct.fromJson).toList(),
      reviewSummaries: summaries,
      specs: JsonRead.objectMap(json['specs']),
    );
  }

  final String id;
  final String? brandId;
  final String? categoryId;
  final String name;
  final String slug;
  final String? description;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Brand? brand;
  final CategoryRecord? category;
  final List<MarketplaceProduct> marketplaceProducts;

  /// Newest first when embedded from `review_summaries(*)`.
  final List<ReviewSummaryRecord> reviewSummaries;

  /// `products.specs` JSONB (category-specific keys).
  final Map<String, dynamic> specs;
}
