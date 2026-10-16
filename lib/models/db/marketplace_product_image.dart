import 'json_read.dart';

/// Row of `public.marketplace_product_images`.
class MarketplaceProductImage {
  const MarketplaceProductImage({
    required this.id,
    required this.marketplaceProductId,
    required this.imageUrl,
    this.imageType,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory MarketplaceProductImage.fromJson(Map<String, dynamic> json) => MarketplaceProductImage(
    id: json['id'] as String,
    marketplaceProductId: json['marketplace_product_id'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    imageType: json['image_type'] as String?,
    sortOrder: JsonRead.toInt(json['sort_order']),
    createdAt: JsonRead.toDate(json['created_at']),
  );

  final String id;
  final String marketplaceProductId;
  final String imageUrl;

  /// e.g. `product`.
  final String? imageType;
  final int sortOrder;
  final DateTime? createdAt;
}
