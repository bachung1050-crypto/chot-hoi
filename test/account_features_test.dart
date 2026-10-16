import 'package:chot_hoi/core/utils/formatters.dart';
import 'package:chot_hoi/features/auth/providers/auth_providers.dart';
import 'package:chot_hoi/features/profile/providers/profile_providers.dart';
import 'package:chot_hoi/features/saved/providers/saved_products_provider.dart';
import 'package:chot_hoi/features/search/providers/ai_search_controller.dart';
import 'package:chot_hoi/features/search/providers/search_history_provider.dart';
import 'package:chot_hoi/mock/mock_data.dart';
import 'package:chot_hoi/models/app_notification.dart';
import 'package:chot_hoi/models/db/profile_record.dart';
import 'package:chot_hoi/models/search_history_entry.dart';
import 'package:chot_hoi/models/search_result.dart';
import 'package:chot_hoi/repositories/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_overrides.dart';

Future<ProviderContainer> _container({bool signedIn = true}) async {
  final container = ProviderContainer(overrides: mockRepositoryOverrides(signedIn: signedIn));
  addTearDown(container.dispose);
  container
    ..listen(currentUserIdProvider, (_, _) {})
    ..listen(profileProvider, (_, _) {})
    ..listen(notificationsProvider, (_, _) {})
    ..listen(searchHistoryProvider, (_, _) {})
    ..listen(searchCountProvider, (_, _) {})
    ..listen(savedProductsProvider, (_, _) {})
    ..listen(aiSearchProvider, (_, _) {});
  await _settle(container);
  return container;
}

Future<void> _settle(ProviderContainer container) async {
  await Future<void>.delayed(Duration.zero);
  await Future.wait([
    container.read(profileProvider.future),
    container.read(notificationsProvider.future),
    container.read(searchHistoryProvider.future),
    container.read(searchCountProvider.future),
  ]);
}

void main() {
  group('auth', () {
    test('1 register signs in a new user with an empty account', () async {
      final container = await _container(signedIn: false);
      final auth = container.read(authRepositoryProvider);

      final needsConfirmation = await auth.signUp(email: 'new@chothoi.vn', password: 'secret123', displayName: 'Mới');
      await _settle(container);

      expect(needsConfirmation, isFalse);
      expect(container.read(currentUserIdProvider), isNotNull);
      expect(container.read(profileProvider).value?.id, container.read(currentUserIdProvider));
      expect(container.read(searchHistoryProvider).value, isEmpty);
      expect(container.read(notificationsProvider).value, isEmpty);
    });

    test('2-3 login loads the user, logout clears it', () async {
      final container = await _container(signedIn: false);
      final auth = container.read(authRepositoryProvider);
      expect(container.read(profileProvider).value, isNull);

      await auth.signIn(email: MockData.profile.email, password: 'secret123');
      await _settle(container);
      expect(container.read(profileProvider).value?.name, MockData.profile.name);

      await auth.signOut();
      await _settle(container);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(profileProvider).value, isNull);
    });

    test('4 session survives an app restart (same auth store, new provider scope)', () async {
      final overrides = mockRepositoryOverrides();
      final first = ProviderContainer(overrides: overrides);
      final userId = first.read(currentUserIdProvider);
      first.dispose();

      final restarted = ProviderContainer(overrides: overrides);
      addTearDown(restarted.dispose);
      expect(restarted.read(currentUserIdProvider), userId);
      expect(userId, isNotNull);
    });
  });

  group('profile', () {
    test('5-6 loads and updates the own profile', () async {
      final container = await _container();
      final profile = container.read(profileProvider).value!;
      expect(profile.phone, MockData.profile.phone);
      expect(profile.language, 'vi');

      await container
          .read(profileProvider.notifier)
          .updateProfile(displayName: 'Trần Thị B', phone: '0911222333', language: 'en');
      final updated = container.read(profileProvider).value!;
      expect(updated.name, 'Trần Thị B');
      expect(updated.phone, '0911222333');
      expect(updated.language, 'en');

      container.invalidate(profileProvider);
      expect((await container.read(profileProvider.future))!.name, 'Trần Thị B', reason: 'persisted');
    });
  });

  group('search history', () {
    test('7 a finished search is saved once with intent and result count', () async {
      final container = await _container();
      final before = container.read(searchCountProvider).value!;
      final search = container.read(aiSearchProvider.notifier);

      await search.searchProducts('laptop dưới 25 triệu ASUS');
      await Future<void>.delayed(Duration.zero);
      final latest = container.read(searchHistoryProvider).value!.first;
      expect(latest.query, 'laptop dưới 25 triệu ASUS');
      expect(latest.resultCount, container.read(aiSearchProvider).allProducts.length);
      expect(latest.parsedIntent['max_price'], 25000000);

      await search.searchProducts('Laptop dưới 25 triệu asus ');
      await Future<void>.delayed(Duration.zero);
      final entries = container.read(searchHistoryProvider).value!;
      expect(entries.where((e) => SearchHistoryEntry.sameQuery(e.query, latest.query)), hasLength(1));
      expect(await container.read(searchCountProvider.future), before + 1);
    });

    test('8 recent queries are distinct and deletable; clear empties them', () async {
      final container = await _container();
      final first = container.read(recentSearchQueriesProvider).first;

      await container.read(searchHistoryProvider.notifier).deleteQuery(first);
      expect(container.read(recentSearchQueriesProvider), isNot(contains(first)));

      await container.read(searchHistoryProvider.notifier).clear();
      expect(container.read(recentSearchQueriesProvider), isEmpty);
      expect(await container.read(searchCountProvider.future), 0);
    });

    test('signed out searches are not recorded', () async {
      final container = await _container(signedIn: false);
      await container.read(aiSearchProvider.notifier).searchProducts('tai nghe');
      expect(container.read(searchHistoryProvider).value, isEmpty);
    });
  });

  group('notifications', () {
    test('9-10 lists, marks one read and then all read', () async {
      final container = await _container();
      final list = container.read(notificationsProvider).value!;
      expect(list, hasLength(MockData.notifications.length));
      final unread = container.read(unreadNotificationCountProvider);
      expect(unread, greaterThan(1));

      await container.read(notificationsProvider.notifier).markAsRead(list.firstWhere((n) => !n.isRead).id);
      expect(container.read(unreadNotificationCountProvider), unread - 1);

      await container.read(notificationsProvider.notifier).markAllAsRead();
      expect(container.read(unreadNotificationCountProvider), 0);
    });
  });

  test('11-12 logout hides user data; another user never sees it', () async {
    final container = await _container();
    final auth = container.read(authRepositoryProvider);
    await container.read(notificationsProvider.notifier).markAllAsRead();

    await auth.signOut();
    await _settle(container);
    expect(container.read(profileProvider).value, isNull);
    expect(container.read(notificationsProvider).value, isEmpty);
    expect(container.read(searchHistoryProvider).value, isEmpty);
    expect(container.read(unreadNotificationCountProvider), 0);

    await auth.signIn(email: 'other@chothoi.vn', password: 'secret123');
    await _settle(container);
    expect(container.read(profileProvider).value?.name, isNot(MockData.profile.name));
    expect(container.read(notificationsProvider).value, isEmpty);
    expect(container.read(searchHistoryProvider).value, isEmpty);

    await auth.signOut();
    await auth.signIn(email: MockData.profile.email, password: 'secret123');
    await _settle(container);
    expect(container.read(searchHistoryProvider).value, isNotEmpty);
    expect(container.read(unreadNotificationCountProvider), 0, reason: 'read state kept for the first user');
  });

  group('row mapping', () {
    final now = DateTime.utc(2026, 10, 15, 12);

    test('notifications row', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'user_id': 'u1',
        'type': 'price_alert',
        'title': 'Giá đã giảm',
        'body': 'Còn 8.990.000đ',
        'data': {'product_id': 'p1'},
        'is_read': false,
        'created_at': '2026-10-15T11:54:00Z',
      }, now: now.toLocal());
      expect(n.type, NotificationType.priceDrop);
      expect(n.message, 'Còn 8.990.000đ');
      expect(n.productId, 'p1');
      expect(n.timeLabel, '6 phút trước');
      expect(n.markRead().isRead, isTrue);
    });

    test('unknown notification type and missing data', () {
      final n = AppNotification.fromJson({'id': 'n2', 'type': null, 'data': null, 'is_read': null});
      expect(n.type, NotificationType.system);
      expect(n.productId, isNull);
      expect(n.isRead, isFalse);
      expect(n.timeLabel, '');
    });

    test('search_histories row and intent json', () {
      final entry = SearchHistoryEntry.fromJson({
        'id': 'h1',
        'query': 'tai nghe',
        'parsed_intent': {'max_price': 10000000},
        'result_count': 3,
        'created_at': '2026-10-15T00:00:00Z',
      });
      expect(entry.parsedIntent['max_price'], 10000000);
      expect(entry.resultCount, 3);
      const intent = SearchIntent(query: 'x', category: 'laptop', brands: ['ASUS'], dealsOnly: true);
      expect(intent.toJson(), {
        'category': 'laptop',
        'brands': ['ASUS'],
        'deals_only': true,
      });
      expect(intent.categoryId, 'laptop');
    });

    test('profiles row', () {
      final p = ProfileRecord.fromJson({
        'id': 'u1',
        'display_name': 'A',
        'avatar_url': null,
        'phone': '090',
        'language': 'en',
        'is_premium': true,
      });
      expect(p.language, 'en');
      expect(p.isPremium, isTrue);
    });

    test('time ago labels', () {
      expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'Vừa xong');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 giờ trước');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 3)), now: now), '3 ngày trước');
    });
  });
}
