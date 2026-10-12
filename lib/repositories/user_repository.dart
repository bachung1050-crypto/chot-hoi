import '../models/app_notification.dart';
import '../models/price_alert.dart';
import '../models/product.dart';
import '../models/user_profile.dart';

abstract interface class UserRepository {
  Future<UserProfile> getProfile();

  Future<List<PriceAlert>> getPriceAlerts();

  Future<void> setPriceAlertEnabled(String alertId, {required bool enabled});

  /// Turns on (or creates) a price alert for [product].
  Future<PriceAlert> trackPrice(Product product);

  Future<List<AppNotification>> getNotifications();

  Future<List<String>> getSearchHistory();
}
