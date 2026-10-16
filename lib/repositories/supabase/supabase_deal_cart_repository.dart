import '../../core/services/supabase_service.dart';
import '../../models/db/deal_cart.dart';
import '../../models/deal_cart_item.dart';
import '../../models/marketplace.dart';
import '../../models/product.dart';
import '../deal_cart_repository.dart';
import 'product_mapper.dart';

/// The user's active `deal_carts` row and its `deal_cart_items`.
/// Prices shown are live `marketplace_products.current_price`; `price_at_added` keeps the price at add time.
class SupabaseDealCartRepository implements DealCartRepository {
  const SupabaseDealCartRepository(this._db);

  final SupabaseService _db;

  static const String _activeStatus = 'active';
  static const String _defaultName = 'Giỏ hời';

  Future<String?> _activeCartId({required bool create}) async {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.dealCarts)
          .select()
          .eq('user_id', userId)
          .eq('status', _activeStatus)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) return DealCart.fromJson(rows.first).id;
      if (!create) return null;
      final created = await client
          .from(DbTables.dealCarts)
          .insert({'user_id': userId, 'name': _defaultName, 'status': _activeStatus})
          .select()
          .single();
      return DealCart.fromJson(created).id;
    });
  }

  @override
  Future<List<DealCartItem>> getItems() async {
    final cartId = await _activeCartId(create: false);
    if (cartId == null) return const [];
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.dealCartItems)
          .select('*,${ProductMapper.productEmbed}')
          .eq('cart_id', cartId)
          .order('created_at');
      return rows.map(DealCartItemRecord.fromJson).map(_toItem).nonNulls.toList();
    });
  }

  /// Skips items whose product no longer has an active listing.
  static DealCartItem? _toItem(DealCartItemRecord record) {
    final productRecord = record.product;
    final product = productRecord == null ? null : ProductMapper.toProduct(productRecord);
    if (product == null) return null;
    final offer =
        product.offers.where((o) => o.marketplaceProductId == record.marketplaceProductId).firstOrNull ??
        product.cheapestOffer;
    return DealCartItem(id: record.id, product: product, offer: offer, quantity: record.quantity);
  }

  @override
  Future<DealCartItem> addItem(Product product, MarketplaceOffer offer, {int quantity = 1}) async {
    ProductMapper.requireDbProductId(product.id);
    final marketplaceProductId = offer.marketplaceProductId;
    if (marketplaceProductId == null) throw const DataFailure('Không xác định được sàn của sản phẩm.');
    final cartId = (await _activeCartId(create: true))!;
    return _db.run((client) async {
      final existing = await client
          .from(DbTables.dealCartItems)
          .select()
          .eq('cart_id', cartId)
          .eq('marketplace_product_id', marketplaceProductId)
          .maybeSingle();
      if (existing != null) {
        final record = DealCartItemRecord.fromJson(existing);
        return DealCartItem(id: record.id, product: product, offer: offer, quantity: record.quantity);
      }
      final inserted = await client
          .from(DbTables.dealCartItems)
          .insert({
            'cart_id': cartId,
            'product_id': product.id,
            'marketplace_product_id': marketplaceProductId,
            'quantity': quantity,
            'price_at_added': offer.price,
          })
          .select()
          .single();
      return DealCartItem(id: inserted['id'] as String, product: product, offer: offer, quantity: quantity);
    });
  }

  @override
  Future<void> updateQuantity(String itemId, int quantity) {
    _db.requireUserId();
    return _db.run((client) => client.from(DbTables.dealCartItems).update({'quantity': quantity}).eq('id', itemId));
  }

  @override
  Future<void> removeItem(String itemId) {
    _db.requireUserId();
    return _db.run((client) => client.from(DbTables.dealCartItems).delete().eq('id', itemId));
  }

  @override
  Future<void> clear() async {
    final cartId = await _activeCartId(create: false);
    if (cartId == null) return;
    await _db.run((client) => client.from(DbTables.dealCartItems).delete().eq('cart_id', cartId));
  }
}
