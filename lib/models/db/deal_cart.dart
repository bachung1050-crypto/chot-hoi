import 'json_read.dart';
import 'product_record.dart';

/// Row of `public.deal_carts`: the app's own cart (not a marketplace cart).
class DealCart {
  const DealCart({required this.id, required this.userId, this.name, this.status, this.createdAt, this.updatedAt});

  factory DealCart.fromJson(Map<String, dynamic> json) => DealCart(
    id: json['id'] as String,
    userId: json['user_id'] as String? ?? '',
    name: json['name'] as String?,
    status: json['status'] as String?,
    createdAt: JsonRead.toDate(json['created_at']),
    updatedAt: JsonRead.toDate(json['updated_at']),
  );

  final String id;
  final String userId;
  final String? name;

  /// e.g. `active`.
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// Row of `public.deal_cart_items`: one product from one marketplace in a cart.
class DealCartItemRecord {
  const DealCartItemRecord({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.marketplaceProductId,
    required this.quantity,
    this.priceAtAdded,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory DealCartItemRecord.fromJson(Map<String, dynamic> json) {
    final productJson = JsonRead.map(json['products']);
    return DealCartItemRecord(
      id: json['id'] as String,
      cartId: json['cart_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      marketplaceProductId: json['marketplace_product_id'] as String? ?? '',
      quantity: JsonRead.toInt(json['quantity'], 1),
      priceAtAdded: JsonRead.toIntOrNull(json['price_at_added']),
      createdAt: JsonRead.toDate(json['created_at']),
      updatedAt: JsonRead.toDate(json['updated_at']),
      product: productJson == null ? null : ProductRecord.fromJson(productJson),
    );
  }

  final String id;
  final String cartId;
  final String productId;
  final String marketplaceProductId;
  final int quantity;

  /// Marketplace price when the item was added.
  final int? priceAtAdded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Embedded `products(...)` with its listings when selected.
  final ProductRecord? product;
}
