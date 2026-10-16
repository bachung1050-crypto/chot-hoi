import '../marketplace.dart';
import 'json_read.dart';
import 'marketplace_product_image.dart';
import 'price_history_entry.dart';
import 'review_record.dart';

/// Row of `public.marketplace_products`: one product listed on one marketplace.
/// [marketplace], [images], [priceHistory] and [reviews] are filled when the query embeds
/// `marketplaces(*)`, `marketplace_product_images(*)`, `price_history(*)` and `reviews(*)`.
class MarketplaceProduct {
  const MarketplaceProduct({
    required this.id,
    required this.productId,
    required this.marketplaceId,
    required this.title,
    required this.productUrl,
    required this.currentPrice,
    this.externalProductId,
    this.affiliateUrl,
    this.originalPrice,
    this.currency = 'VND',
    this.stockStatus,
    this.sellerName,
    this.sellerRating,
    this.rating,
    this.reviewCount = 0,
    this.isActive = true,
    this.lastSyncedAt,
    this.marketplace,
    this.images = const [],
    this.priceHistory = const [],
    this.reviews = const [],
  });

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    final marketplaceJson = JsonRead.map(json['marketplaces']);
    final images = JsonRead.list(json['marketplace_product_images']).map(MarketplaceProductImage.fromJson).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final history = JsonRead.list(json['price_history']).map(PriceHistoryEntry.fromJson).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final reviews = JsonRead.list(json['reviews']).map(ReviewRecord.fromJson).toList()
      ..sort((a, b) => (b.reviewDate ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.reviewDate ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ));
    return MarketplaceProduct(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      marketplaceId: json['marketplace_id'] as String? ?? '',
      externalProductId: json['external_product_id'] as String?,
      title: json['title'] as String? ?? '',
      productUrl: json['product_url'] as String? ?? '',
      affiliateUrl: json['affiliate_url'] as String?,
      currentPrice: JsonRead.toInt(json['current_price']),
      originalPrice: JsonRead.toIntOrNull(json['original_price']),
      currency: json['currency'] as String? ?? 'VND',
      stockStatus: json['stock_status'] as String?,
      sellerName: json['seller_name'] as String?,
      sellerRating: json['seller_rating'] == null ? null : JsonRead.toDouble(json['seller_rating']),
      rating: json['rating'] == null ? null : JsonRead.toDouble(json['rating']),
      reviewCount: JsonRead.toInt(json['review_count']),
      isActive: json['is_active'] as bool? ?? true,
      lastSyncedAt: JsonRead.toDate(json['last_synced_at']),
      marketplace: marketplaceJson == null ? null : Marketplace.fromJson(marketplaceJson),
      images: images,
      priceHistory: history,
      reviews: reviews,
    );
  }

  final String id;
  final String productId;
  final String marketplaceId;
  final String? externalProductId;
  final String title;
  final String productUrl;
  final String? affiliateUrl;
  final int currentPrice;
  final int? originalPrice;
  final String currency;

  /// e.g. `in_stock`.
  final String? stockStatus;
  final String? sellerName;
  final double? sellerRating;
  final double? rating;
  final int reviewCount;
  final bool isActive;
  final DateTime? lastSyncedAt;
  final Marketplace? marketplace;
  final List<MarketplaceProductImage> images;

  /// Oldest first.
  final List<PriceHistoryEntry> priceHistory;

  /// Newest first when embedded from `reviews(*)`.
  final List<ReviewRecord> reviews;

  bool get inStock => stockStatus == null || stockStatus == 'in_stock';

  /// Link to open when the user buys: affiliate link first, plain product page otherwise.
  String get buyUrl {
    final affiliate = affiliateUrl;
    return affiliate != null && affiliate.isNotEmpty ? affiliate : productUrl;
  }
}
