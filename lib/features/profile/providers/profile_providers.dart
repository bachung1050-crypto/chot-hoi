import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../../models/price_alert.dart';
import '../../../models/product.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/repository_providers.dart';

final profileProvider = FutureProvider<UserProfile>((ref) => ref.watch(userRepositoryProvider).getProfile());

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(userRepositoryProvider).getNotifications(),
);

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0,
);

final searchHistoryProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(userRepositoryProvider).getSearchHistory(),
);

class PriceAlertsNotifier extends AsyncNotifier<List<PriceAlert>> {
  @override
  Future<List<PriceAlert>> build() => ref.read(userRepositoryProvider).getPriceAlerts();

  Future<void> setEnabled(String alertId, {required bool enabled}) async {
    final current = state.value ?? const [];
    state = AsyncData([for (final alert in current) alert.id == alertId ? alert.copyWith(enabled: enabled) : alert]);
    await ref.read(userRepositoryProvider).setPriceAlertEnabled(alertId, enabled: enabled);
  }

  Future<PriceAlert> trackPrice(Product product) async {
    final alert = await ref.read(userRepositoryProvider).trackPrice(product);
    final current = state.value ?? const [];
    state = AsyncData([alert, ...current.where((a) => a.id != alert.id)]);
    return alert;
  }
}

final priceAlertsProvider = AsyncNotifierProvider<PriceAlertsNotifier, List<PriceAlert>>(PriceAlertsNotifier.new);
