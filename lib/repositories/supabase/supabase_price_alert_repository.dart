import '../../core/services/supabase_service.dart';
import '../../models/db/price_alert_record.dart';
import '../../models/marketplace.dart';
import '../../models/price_alert.dart';
import '../../models/product.dart';
import '../price_alert_repository.dart';
import 'product_mapper.dart';

/// `price_alerts` of the signed-in user. The backend later sets `triggered_at`
/// and creates a notification when `current_price <= target_price`.
class SupabasePriceAlertRepository implements PriceAlertRepository {
  const SupabasePriceAlertRepository(this._db);

  final SupabaseService _db;

  @override
  Future<List<PriceAlert>> getAlerts() {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.priceAlerts)
          .select('*,${ProductMapper.productEmbed}')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map(PriceAlertRecord.fromJson).map(_toAlert).nonNulls.toList();
    });
  }

  static PriceAlert? _toAlert(PriceAlertRecord record) {
    final productRecord = record.product;
    final product = productRecord == null ? null : ProductMapper.toProduct(productRecord);
    if (product == null) return null;
    return PriceAlert(
      id: record.id,
      product: product,
      targetPrice: record.targetPrice,
      enabled: record.isActive,
      offer: product.offers.where((o) => o.marketplaceProductId == record.marketplaceProductId).firstOrNull,
      triggeredAt: record.triggeredAt,
    );
  }

  @override
  Future<PriceAlert> saveAlert(Product product, {required int targetPrice, MarketplaceOffer? offer}) {
    final userId = _db.requireUserId();
    ProductMapper.requireDbProductId(product.id);
    final watched = offer ?? product.cheapestOffer;
    final values = {
      'marketplace_product_id': watched.marketplaceProductId,
      'target_price': targetPrice,
      'current_price': watched.price,
      'is_active': true,
      'triggered_at': null,
    };
    return _db.run((client) async {
      final existing = await client
          .from(DbTables.priceAlerts)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', product.id)
          .limit(1);
      final Map<String, dynamic> row;
      if (existing.isEmpty) {
        row = await client
            .from(DbTables.priceAlerts)
            .insert({'user_id': userId, 'product_id': product.id, ...values})
            .select()
            .single();
      } else {
        row = await client
            .from(DbTables.priceAlerts)
            .update(values)
            .eq('id', existing.first['id'] as String)
            .select()
            .single();
      }
      return PriceAlert(id: row['id'] as String, product: product, targetPrice: targetPrice, offer: watched);
    });
  }

  @override
  Future<void> updateTargetPrice(String alertId, int targetPrice) {
    _db.requireUserId();
    return _db.run(
      (client) => client
          .from(DbTables.priceAlerts)
          .update({'target_price': targetPrice, 'is_active': true, 'triggered_at': null})
          .eq('id', alertId),
    );
  }

  @override
  Future<void> setActive(String alertId, {required bool active}) {
    _db.requireUserId();
    return _db.run((client) => client.from(DbTables.priceAlerts).update({'is_active': active}).eq('id', alertId));
  }

  @override
  Future<void> deleteAlert(String alertId) {
    _db.requireUserId();
    return _db.run((client) => client.from(DbTables.priceAlerts).delete().eq('id', alertId));
  }
}
