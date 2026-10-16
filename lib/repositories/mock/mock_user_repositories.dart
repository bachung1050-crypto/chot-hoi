import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../../mock/mock_data.dart';
import '../../models/app_notification.dart';
import '../../models/deal_cart_item.dart';
import '../../models/marketplace.dart';
import '../../models/price_alert.dart';
import '../../models/product.dart';
import '../../models/search_history_entry.dart';
import '../../models/search_result.dart';
import '../../models/user_profile.dart';
import '../deal_cart_repository.dart';
import '../notification_repository.dart';
import '../price_alert_repository.dart';
import '../profile_repository.dart';
import '../saved_products_repository.dart';
import '../search_history_repository.dart';

Product _productById(String id) => MockProducts.all.firstWhere((p) => p.id == id);

Future<T> _delay<T>(T value, [Duration latency = AppConfig.mockLatency]) => Future<T>.delayed(latency, () => value);

/// In-memory saved list seeded from [MockData.savedProductIds].
class MockSavedProductsRepository implements SavedProductsRepository {
  final List<String> _ids = [...MockData.savedProductIds];

  @override
  Future<List<Product>> getSavedProducts() =>
      _delay([for (final id in _ids) ...MockProducts.all.where((p) => p.id == id)]);

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
        final offer = product.offers.firstWhere((o) => o.marketplace.code == seed.marketplace);
        return DealCartItem(id: _itemId(product, offer), product: product, offer: offer);
      }(),
  ];

  static String _itemId(Product product, MarketplaceOffer offer) => 'cart-${product.id}-${offer.marketplace.id}';

  @override
  Future<List<DealCartItem>> getItems() => _delay(List.of(_items));

  @override
  Future<DealCartItem> addItem(Product product, MarketplaceOffer offer, {int quantity = 1}) async {
    final id = _itemId(product, offer);
    final existing = _items.where((i) => i.id == id).firstOrNull;
    if (existing != null) return existing;
    final item = DealCartItem(id: id, product: product, offer: offer, quantity: quantity);
    _items.add(item);
    return item;
  }

  @override
  Future<void> updateQuantity(String itemId, int quantity) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) _items[index] = _items[index].copyWith(quantity: quantity);
  }

  @override
  Future<void> removeItem(String itemId) async => _items.removeWhere((i) => i.id == itemId);

  @override
  Future<void> clear() async => _items.clear();
}

/// In-memory alerts seeded from [MockData.priceAlerts].
class MockPriceAlertRepository implements PriceAlertRepository {
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
  Future<List<PriceAlert>> getAlerts() => _delay(List.of(_alerts));

  @override
  Future<PriceAlert> saveAlert(Product product, {required int targetPrice, MarketplaceOffer? offer}) async {
    final alert = PriceAlert(id: 'alert-${product.id}', product: product, targetPrice: targetPrice, offer: offer);
    _alerts
      ..removeWhere((a) => a.id == alert.id)
      ..insert(0, alert);
    return alert;
  }

  @override
  Future<void> updateTargetPrice(String alertId, int targetPrice) async => _update(alertId, targetPrice: targetPrice);

  @override
  Future<void> setActive(String alertId, {required bool active}) async => _update(alertId, enabled: active);

  @override
  Future<void> deleteAlert(String alertId) async => _alerts.removeWhere((a) => a.id == alertId);

  void _update(String alertId, {bool? enabled, int? targetPrice}) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) _alerts[index] = _alerts[index].copyWith(enabled: enabled, targetPrice: targetPrice);
  }
}

/// Per-user data keyed by the mock signed-in user; only the demo user is seeded.
abstract class _PerUserMock<T> {
  _PerUserMock(this._currentUserId);

  final String? Function() _currentUserId;
  final Map<String, T> _byUser = {};

  T seed(String userId);

  T get data {
    final userId = _currentUserId() ?? (throw const AuthRequiredFailure());
    return _byUser.putIfAbsent(userId, () => seed(userId));
  }
}

class MockProfileRepository extends _PerUserMock<UserProfile> implements ProfileRepository {
  MockProfileRepository(super.currentUserId);

  @override
  UserProfile seed(String userId) => userId == MockData.profile.id
      ? MockData.profile
      : UserProfile(id: userId, name: userId.replaceFirst('user-', '').split('@').first, email: '', avatarUrl: '');

  @override
  Future<UserProfile> getProfile() => _delay(data);

  @override
  Future<UserProfile> updateProfile({String? displayName, String? phone, String? language}) async {
    final updated = data.copyWith(name: displayName?.trim(), phone: phone?.trim(), language: language);
    _byUser[updated.id] = updated;
    return updated;
  }
}

class MockSearchHistoryRepository extends _PerUserMock<List<SearchHistoryEntry>> implements SearchHistoryRepository {
  MockSearchHistoryRepository(super.currentUserId);

  int _nextId = 0;

  @override
  List<SearchHistoryEntry> seed(String userId) => userId == MockData.profile.id
      ? [for (final query in MockData.searchHistory) SearchHistoryEntry(id: 'h${_nextId++}', query: query)]
      : [];

  @override
  Future<List<SearchHistoryEntry>> getRecent({int limit = 20}) => _delay(data.take(limit).toList());

  @override
  Future<SearchHistoryEntry?> add(String query, {SearchIntent? intent, int? resultCount}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || (data.isNotEmpty && SearchHistoryEntry.sameQuery(data.first.query, trimmed))) return null;
    final entry = SearchHistoryEntry(
      id: 'h${_nextId++}',
      query: trimmed,
      parsedIntent: intent?.toJson() ?? const {},
      resultCount: resultCount,
      createdAt: DateTime.now(),
    );
    data.insert(0, entry);
    return entry;
  }

  @override
  Future<void> deleteQuery(String query) async => data.removeWhere((e) => e.query == query);

  @override
  Future<void> clear() async => data.clear();

  @override
  Future<int> count() async => data.length;
}

class MockNotificationRepository extends _PerUserMock<List<AppNotification>> implements NotificationRepository {
  MockNotificationRepository(super.currentUserId);

  @override
  List<AppNotification> seed(String userId) => userId == MockData.profile.id ? [...MockData.notifications] : [];

  @override
  Future<List<AppNotification>> getNotifications({int limit = 50}) => _delay(data.take(limit).toList());

  @override
  Future<void> markAsRead(String id) async {
    final list = data;
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1) list[index] = list[index].markRead();
  }

  @override
  Future<void> markAllAsRead() async {
    final list = data;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].markRead();
    }
  }
}
