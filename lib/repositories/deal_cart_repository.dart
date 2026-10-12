import '../models/deal_cart_item.dart';

abstract interface class DealCartRepository {
  Future<List<DealCartItem>> getItems();

  Future<void> upsertItem(DealCartItem item);

  Future<void> removeItem(String itemId);

  Future<void> clear();
}
