import 'json_read.dart';
import 'product_record.dart';

/// Row of `public.saved_products` (unique per `user_id` + `product_id` in the app).
class SavedProduct {
  const SavedProduct({required this.id, required this.userId, required this.productId, this.createdAt, this.product});

  factory SavedProduct.fromJson(Map<String, dynamic> json) {
    final productJson = JsonRead.map(json['products']);
    return SavedProduct(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      createdAt: JsonRead.toDate(json['created_at']),
      product: productJson == null ? null : ProductRecord.fromJson(productJson),
    );
  }

  final String id;
  final String userId;
  final String productId;
  final DateTime? createdAt;

  /// Embedded `products(...)` when selected.
  final ProductRecord? product;
}
