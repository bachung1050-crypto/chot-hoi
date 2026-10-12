import '../../core/config/app_config.dart';
import '../../mock/mock_data.dart';
import '../../models/app_notification.dart';
import '../../models/deal_cart_item.dart';
import '../../models/price_alert.dart';
import '../../models/product.dart';
import '../../models/user_profile.dart';
import '../deal_cart_repository.dart';
import '../saved_products_repository.dart';
import '../user_repository.dart';

Product _productById(String id) => MockProducts.all.firstWhere((p) => p.id == id);

Future<T> _delay<T>(T value, [Duration latency = AppConfig.mockLatency]) => Future<T>.delayed(latency, () => value);

/// In-memory saved list seeded from [MockData.savedProductIds].
class MockSavedProductsRepository implements SavedProductsRepository {
  final List<String> _ids = [...MockData.savedProductIds];

  @override
  Future<List<Product>> getSavedProducts() => _delay(_ids.map(_productById).toList());

  @override
  Future<void> saveProduct(String productId) async {
    if (!_ids.contains(productId)) _ids.insert(0, productId);
  }

  @override
  Future<void> removeProduct(String productId) async => _ids.remove(productId);
}

/// In-memory Deal Cart seeded from [MockData.cartItems].
class MockDealCartRepository implements DealCartRepository {
  final List<DealCartItem> _items = [
    for (final seed in MockData.cartItems)
      () {
        final product = _productById(seed.productId);
        return DealCartItem(
          id: 'cart-${seed.productId}',
          product: product,
          offer: product.offers.firstWhere((o) => o.marketplace.code == seed.marketplace),
        );
      }(),
  ];

  @override
  Future<List<DealCartItem>> getItems() => _delay(List.of(_items));

  @override
  Future<void> upsertItem(DealCartItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  @override
  Future<void> removeItem(String itemId) async => _items.removeWhere((i) => i.id == itemId);

  @override
  Future<void> clear() async => _items.clear();
}

class MockUserRepository implements UserRepository {
  final List<PriceAlert> _alerts = [
    for (final seed in MockData.priceAlerts)
      PriceAlert(
        id: 'alert-${seed.productId}',
        product: _productById(seed.productId),
        targetPrice: seed.targetPrice,
        enabled: seed.enabled,
      ),
  ];

  @override
  Future<UserProfile> getProfile() => _delay(MockData.profile);

  @override
  Future<List<PriceAlert>> getPriceAlerts() => _delay(List.of(_alerts));

  @override
  Future<void> setPriceAlertEnabled(String alertId, {required bool enabled}) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) _alerts[index] = _alerts[index].copyWith(enabled: enabled);
  }

  @override
  Future<PriceAlert> trackPrice(Product product) async {
    final index = _alerts.indexWhere((a) => a.product.id == product.id);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(enabled: true);
      return _alerts[index];
    }
    final alert = PriceAlert(
      id: 'alert-${product.id}',
      product: product,
      targetPrice: (product.currentPrice * 0.95 / 10000).round() * 10000,
    );
    _alerts.insert(0, alert);
    return alert;
  }

  @override
  Future<List<AppNotification>> getNotifications() => _delay(MockData.notifications);

  @override
  Future<List<String>> getSearchHistory() => _delay(MockData.searchHistory);
}
