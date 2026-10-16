import 'json_read.dart';
import 'product_record.dart';

/// Row of `public.price_alerts`. The UI uses [PriceAlert].
class PriceAlertRecord {
  const PriceAlertRecord({
    required this.id,
    required this.userId,
    required this.productId,
    required this.targetPrice,
    this.marketplaceProductId,
    this.currentPrice,
    this.isActive = true,
    this.triggeredAt,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory PriceAlertRecord.fromJson(Map<String, dynamic> json) {
    final productJson = JsonRead.map(json['products']);
    return PriceAlertRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      marketplaceProductId: json['marketplace_product_id'] as String?,
      targetPrice: JsonRead.toInt(json['target_price']),
      currentPrice: JsonRead.toIntOrNull(json['current_price']),
      isActive: json['is_active'] as bool? ?? true,
      triggeredAt: JsonRead.toDate(json['triggered_at']),
      createdAt: JsonRead.toDate(json['created_at']),
      updatedAt: JsonRead.toDate(json['updated_at']),
      product: productJson == null ? null : ProductRecord.fromJson(productJson),
    );
  }

  final String id;
  final String userId;
  final String productId;

  /// Null means "any marketplace".
  final String? marketplaceProductId;
  final int targetPrice;

  /// Price when the alert was created or last updated.
  final int? currentPrice;
  final bool isActive;

  /// Set by the backend when `current_price <= target_price`.
  final DateTime? triggeredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProductRecord? product;
}
