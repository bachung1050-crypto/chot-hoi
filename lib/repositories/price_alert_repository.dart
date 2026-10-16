import '../models/marketplace.dart';
import '../models/price_alert.dart';
import '../models/product.dart';

/// The signed-in user's `price_alerts`. Triggering and notifications run on the backend.
abstract interface class PriceAlertRepository {
  Future<List<PriceAlert>> getAlerts();

  /// Creates an alert for [product], or updates the existing one to [targetPrice] and re-activates it.
  Future<PriceAlert> saveAlert(Product product, {required int targetPrice, MarketplaceOffer? offer});

  Future<void> updateTargetPrice(String alertId, int targetPrice);

  Future<void> setActive(String alertId, {required bool active});

  Future<void> deleteAlert(String alertId);
}
