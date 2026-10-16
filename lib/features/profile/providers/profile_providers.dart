import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../../models/marketplace.dart';
import '../../../models/price_alert.dart';
import '../../../models/product.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/price_alert_repository.dart';
import '../../../repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';

/// Signed-in user's `profiles` row; null when signed out.
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    if (ref.watch(currentUserIdProvider) == null) return null;
    return ref.watch(profileRepositoryProvider).getProfile();
  }

  Future<void> updateProfile({String? displayName, String? phone, String? language}) async {
    final updated = await ref
        .read(profileRepositoryProvider)
        .updateProfile(displayName: displayName, phone: phone, language: language);
    state = AsyncData(updated);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

/// Signed-in user's notifications; empty when signed out.
class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  List<AppNotification> get _current => state.value ?? const [];

  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.watch(notificationRepositoryProvider).getNotifications();
  }

  /// Optimistic; rolled back if the update is rejected.
  Future<void> markAsRead(String id) async {
    final previous = _current;
    if (!previous.any((n) => n.id == id && !n.isRead)) return;
    state = AsyncData([for (final n in previous) n.id == id ? n.markRead() : n]);
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final previous = _current;
    state = AsyncData([for (final n in previous) n.markRead()]);
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0,
);

class PriceAlertsNotifier extends AsyncNotifier<List<PriceAlert>> {
  PriceAlertRepository get _repository => ref.read(priceAlertRepositoryProvider);

  List<PriceAlert> get _current => state.value ?? const [];

  /// Rebuilds on login/logout; signed-out users have no alerts.
  @override
  Future<List<PriceAlert>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.watch(priceAlertRepositoryProvider).getAlerts();
  }

  PriceAlert? alertFor(String productId) => _current.where((a) => a.product.id == productId).firstOrNull;

  Future<void> setEnabled(String alertId, {required bool enabled}) => _optimistic([
    for (final alert in _current) alert.id == alertId ? alert.copyWith(enabled: enabled) : alert,
  ], () => _repository.setActive(alertId, active: enabled));

  Future<void> updateTargetPrice(String alertId, int targetPrice) => _optimistic([
    for (final alert in _current) alert.id == alertId ? alert.copyWith(targetPrice: targetPrice, enabled: true) : alert,
  ], () => _repository.updateTargetPrice(alertId, targetPrice));

  Future<void> delete(String alertId) =>
      _optimistic(_current.where((a) => a.id != alertId).toList(), () => _repository.deleteAlert(alertId));

  /// Creates the alert for [product] or updates the existing one.
  Future<PriceAlert> saveAlert(Product product, {required int targetPrice, MarketplaceOffer? offer}) async {
    final alert = await _repository.saveAlert(product, targetPrice: targetPrice, offer: offer);
    state = AsyncData([alert, ..._current.where((a) => a.id != alert.id && a.product.id != product.id)]);
    return alert;
  }

  /// One-tap tracking with a default target 5% under the current price.
  Future<PriceAlert> trackPrice(Product product) =>
      saveAlert(product, targetPrice: defaultTargetPrice(product.currentPrice));

  static int defaultTargetPrice(int currentPrice) => (currentPrice * 0.95 / 10000).round() * 10000;

  Future<void> _optimistic(List<PriceAlert> next, Future<void> Function() request) async {
    final previous = _current;
    state = AsyncData(next);
    try {
      await request();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final priceAlertsProvider = AsyncNotifierProvider<PriceAlertsNotifier, List<PriceAlert>>(PriceAlertsNotifier.new);
