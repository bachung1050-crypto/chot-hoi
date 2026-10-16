// Runs the Phase 3 user flows against the real Supabase project with a confirmed account:
//   flutter test --dart-define-from-file=env.json --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=... \
//     test/supabase_user_data_live_test.dart
// Everything created here is removed again at the end.
import 'package:chot_hoi/core/config/supabase_config.dart';
import 'package:chot_hoi/core/services/supabase_service.dart';
import 'package:chot_hoi/models/product.dart';
import 'package:chot_hoi/repositories/supabase/supabase_auth_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_deal_cart_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_price_alert_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_product_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_saved_products_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

void main() {
  final skip = SupabaseConfig.isConfigured && _email.isNotEmpty && _password.isNotEmpty
      ? false
      : 'Pass env.json plus TEST_EMAIL / TEST_PASSWORD to run';

  late SupabaseClient client;
  late SupabaseService db;
  late SupabaseAuthRepository auth;
  late SupabaseSavedProductsRepository saved;
  late SupabaseDealCartRepository cart;
  late SupabasePriceAlertRepository alerts;
  late Product product;

  setUpAll(() async {
    if (skip != false) return;
    client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    db = SupabaseService(client);
    auth = SupabaseAuthRepository(db);
    saved = SupabaseSavedProductsRepository(db);
    cart = SupabaseDealCartRepository(db);
    alerts = SupabasePriceAlertRepository(db);
    product = (await SupabaseProductRepository(db).getProducts()).firstWhere((p) => p.offers.length >= 2);
    await auth.signIn(email: _email, password: _password);
  });

  tearDownAll(() async {
    if (skip != false) return;
    if (auth.currentUserId != null) {
      await saved.removeProduct(product.id);
      await cart.clear();
      for (final alert in await alerts.getAlerts()) {
        if (alert.product.id == product.id) await alerts.deleteAlert(alert.id);
      }
      await auth.signOut();
    }
    await client.dispose();
  });

  test('1-3 favorite, no duplicates, saved tab, unfavorite', () async {
    await saved.saveProduct(product.id);
    await saved.saveProduct(product.id);
    final rows = await client
        .from(DbTables.savedProducts)
        .select('id')
        .eq('user_id', auth.currentUserId!)
        .eq('product_id', product.id);
    expect(rows, hasLength(1));
    expect((await saved.getSavedProducts()).map((p) => p.id), contains(product.id));

    await saved.removeProduct(product.id);
    expect((await saved.getSavedProducts()).map((p) => p.id), isNot(contains(product.id)));
  }, skip: skip);

  test('4-8 cart: add, other marketplace, quantity, subtotal, remove', () async {
    await cart.clear();
    final [first, second, ...] = product.sortedOffers;
    final a = await cart.addItem(product, first);
    final again = await cart.addItem(product, first);
    expect(again.id, a.id, reason: 'same marketplace is not duplicated');
    final b = await cart.addItem(product, second);
    expect(b.id, isNot(a.id));

    await cart.updateQuantity(a.id, 3);
    final items = await cart.getItems();
    expect(items, hasLength(2));
    final loadedA = items.firstWhere((i) => i.id == a.id);
    expect(loadedA.quantity, 3);
    expect(loadedA.offer.marketplace.code, first.marketplace.code);
    expect(items.fold(0, (sum, i) => sum + i.subtotal), first.price * 3 + second.price);

    await cart.removeItem(a.id);
    expect((await cart.getItems()).map((i) => i.id), [b.id]);
  }, skip: skip);

  test('9-11 price alert: create, toggle off/on, delete', () async {
    final target = product.currentPrice - 100000;
    final alert = await alerts.saveAlert(product, targetPrice: target, offer: product.cheapestOffer);
    var loaded = (await alerts.getAlerts()).firstWhere((a) => a.id == alert.id);
    expect(loaded.targetPrice, target);
    expect(loaded.enabled, isTrue);
    expect(loaded.offer?.marketplace.code, product.cheapestOffer.marketplace.code);

    await alerts.setActive(alert.id, active: false);
    loaded = (await alerts.getAlerts()).firstWhere((a) => a.id == alert.id);
    expect(loaded.enabled, isFalse);
    await alerts.setActive(alert.id, active: true);
    loaded = (await alerts.getAlerts()).firstWhere((a) => a.id == alert.id);
    expect(loaded.enabled, isTrue);

    await alerts.deleteAlert(alert.id);
    expect((await alerts.getAlerts()).map((a) => a.id), isNot(contains(alert.id)));
  }, skip: skip);

  test('12 logout hides data, login returns the same user data', () async {
    await saved.saveProduct(product.id);
    final userId = auth.currentUserId;

    await auth.signOut();
    expect(auth.currentUserId, isNull);
    expect(saved.getSavedProducts, throwsA(isA<AuthRequiredFailure>()));
    final anonymous = await client.from(DbTables.savedProducts).select('id');
    expect(anonymous, isEmpty, reason: 'RLS must hide other users\' rows');

    await auth.signIn(email: _email, password: _password);
    expect(auth.currentUserId, userId);
    expect((await saved.getSavedProducts()).map((p) => p.id), contains(product.id));
  }, skip: skip);
}
