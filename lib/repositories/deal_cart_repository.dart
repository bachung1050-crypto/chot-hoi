import '../models/deal_cart_item.dart';
import '../models/marketplace.dart';
import '../models/product.dart';

/// The signed-in user's active Chốt Hời cart (`deal_carts` + `deal_cart_items`).
abstract interface class DealCartRepository {
  Future<List<DealCartItem>> getItems();

  /// Adds [product] bought on [offer]'s marketplace; creates the active cart if needed.
  Future<DealCartItem> addItem(Product product, MarketplaceOffer offer, {int quantity = 1});

  Future<void> updateQuantity(String itemId, int quantity);

  Future<void> removeItem(String itemId);

  Future<void> clear();
}
