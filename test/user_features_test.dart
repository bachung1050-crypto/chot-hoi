import 'package:chot_hoi/features/auth/providers/auth_providers.dart';
import 'package:chot_hoi/features/cart/providers/deal_cart_provider.dart';
import 'package:chot_hoi/features/profile/providers/profile_providers.dart';
import 'package:chot_hoi/features/saved/providers/saved_products_provider.dart';
import 'package:chot_hoi/mock/mock_data.dart';
import 'package:chot_hoi/models/db/deal_cart.dart';
import 'package:chot_hoi/models/db/price_alert_record.dart';
import 'package:chot_hoi/models/db/saved_product.dart';
import 'package:chot_hoi/repositories/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_overrides.dart';
import 'product_mapper_test.dart' show supabaseProductRow;

Future<ProviderContainer> _container({bool signedIn = true}) async {
  final container = ProviderContainer(overrides: mockRepositoryOverrides(signedIn: signedIn));
  addTearDown(container.dispose);
  container
    ..listen(currentUserIdProvider, (_, _) {})
    ..listen(savedProductsProvider, (_, _) {})
    ..listen(dealCartProvider, (_, _) {})
    ..listen(priceAlertsProvider, (_, _) {});
  await _settle(container);
  return container;
}

/// Lets the auth stream emit and the user-owned providers reload.
Future<void> _settle(ProviderContainer container) async {
  await Future<void>.delayed(Duration.zero);
  await Future.wait([
    container.read(savedProductsProvider.future),
    container.read(dealCartProvider.future),
    container.read(priceAlertsProvider.future),
  ]);
}

void main() {
  final unsaved = MockProducts.all.firstWhere((p) => !MockData.savedProductIds.contains(p.id) && p.offers.length >= 2);

  group('saved products', () {
    test('favorite then unfavorite updates the list immediately', () async {
      final container = await _container();
      final notifier = container.read(savedProductsProvider.notifier);
      final before = container.read(savedCountProvider);

      final pending = notifier.toggle(unsaved);
      expect(container.read(isProductSavedProvider(unsaved.id)), isTrue, reason: 'optimistic');
      expect(await pending, isTrue);
      expect(container.read(savedCountProvider), before + 1);

      expect(await notifier.toggle(unsaved), isFalse);
      expect(container.read(isProductSavedProvider(unsaved.id)), isFalse);
      expect(container.read(savedCountProvider), before);
    });

    test('signed out shows nothing and keeps no fake user', () async {
      final container = await _container(signedIn: false);
      expect(container.read(currentUserIdProvider), isNull);
      expect(container.read(savedProductsProvider).value, isEmpty);
      expect(container.read(dealCartProvider).value, isEmpty);
      expect(container.read(priceAlertsProvider).value, isEmpty);
      expect(await container.read(profileProvider.future), isNull);
    });
  });

  group('deal cart', () {
    test('add per marketplace, change quantity, subtotal and remove', () async {
      final container = await _container();
      final notifier = container.read(dealCartProvider.notifier);
      await notifier.clear();

      final [first, second, ...] = unsaved.sortedOffers;
      expect(await notifier.addToCart(unsaved, offer: first), isTrue);
      expect(await notifier.addToCart(unsaved, offer: first), isFalse, reason: 'same marketplace is deduped');
      expect(await notifier.addToCart(unsaved, offer: second), isTrue, reason: 'another marketplace is a new line');
      expect(container.read(dealCartCountProvider), 2);

      final firstItem = container.read(dealCartProvider).value!.firstWhere((i) => i.offer == first);
      await notifier.updateQuantity(firstItem.id, 3);
      final summary = container.read(dealCartSummaryProvider);
      expect(summary.itemCount, 4);
      expect(summary.total, first.price * 3 + second.price);

      await notifier.removeFromCart(firstItem.id);
      expect(container.read(dealCartCountProvider), 1);
      expect(container.read(dealCartSummaryProvider).total, second.price);
    });
  });

  group('price alerts', () {
    test('create, toggle off and on, update target, delete', () async {
      final container = await _container();
      final notifier = container.read(priceAlertsProvider.notifier);

      final created = await notifier.saveAlert(unsaved, targetPrice: 1000000, offer: unsaved.cheapestOffer);
      expect(notifier.alertFor(unsaved.id)?.targetPrice, 1000000);
      expect(created.currentPrice, unsaved.cheapestOffer.price);

      await notifier.setEnabled(created.id, enabled: false);
      expect(notifier.alertFor(unsaved.id)?.enabled, isFalse);
      await notifier.setEnabled(created.id, enabled: true);
      expect(notifier.alertFor(unsaved.id)?.enabled, isTrue);

      await notifier.updateTargetPrice(created.id, 900000);
      expect(notifier.alertFor(unsaved.id)?.targetPrice, 900000);

      await notifier.saveAlert(unsaved, targetPrice: 800000);
      expect(container.read(priceAlertsProvider).value!.where((a) => a.product.id == unsaved.id), hasLength(1));

      await notifier.delete(created.id);
      expect(notifier.alertFor(unsaved.id), isNull);
    });

    test('default target is 5% under the current price, rounded to 10.000đ', () {
      expect(PriceAlertsNotifier.defaultTargetPrice(25990000), 24690000);
    });
  });

  test('logout clears user data and login brings the same user data back', () async {
    final container = await _container();
    await container.read(savedProductsProvider.notifier).addSavedProduct(unsaved);
    final saved = container.read(savedCountProvider);
    final auth = container.read(authRepositoryProvider);

    await auth.signOut();
    await _settle(container);
    expect(container.read(currentUserIdProvider), isNull);
    expect(container.read(savedCountProvider), 0);
    expect(container.read(dealCartCountProvider), 0);

    await auth.signIn(email: MockData.profile.email, password: 'secret');
    await _settle(container);
    expect(container.read(currentUserIdProvider), MockData.profile.id);
    expect(container.read(savedCountProvider), saved);
    expect(container.read(isProductSavedProvider(unsaved.id)), isTrue);
  });

  group('user table records', () {
    test('saved_products row with embedded product', () {
      final saved = SavedProduct.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'product_id': 'p1',
        'created_at': '2026-10-01T00:00:00Z',
        'products': supabaseProductRow,
      });
      expect(saved.userId, 'u1');
      expect(saved.product?.name, isNotEmpty);
    });

    test('deal_cart_items row', () {
      final item = DealCartItemRecord.fromJson({
        'id': 'i1',
        'cart_id': 'c1',
        'product_id': 'p1',
        'marketplace_product_id': 'm1',
        'quantity': 2,
        'price_at_added': '1990000.00',
      });
      expect(item.quantity, 2);
      expect(item.priceAtAdded, 1990000);
      expect(item.product, isNull);
    });

    test('price_alerts row', () {
      final alert = PriceAlertRecord.fromJson({
        'id': 'a1',
        'user_id': 'u1',
        'product_id': 'p1',
        'marketplace_product_id': null,
        'target_price': 1500000,
        'current_price': '1690000',
        'is_active': false,
        'triggered_at': null,
      });
      expect(alert.targetPrice, 1500000);
      expect(alert.currentPrice, 1690000);
      expect(alert.isActive, isFalse);
      expect(alert.marketplaceProductId, isNull);
    });
  });
}
