// Runs against the real Supabase project only when credentials are provided:
//   flutter test --dart-define-from-file=env.json test/supabase_product_repository_live_test.dart
import 'package:chot_hoi/core/config/supabase_config.dart';
import 'package:chot_hoi/core/services/supabase_service.dart';
import 'package:chot_hoi/repositories/supabase/supabase_product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final skip = SupabaseConfig.isConfigured ? false : 'Pass --dart-define-from-file=env.json to run';
  late SupabaseProductRepository repository;

  setUpAll(() {
    final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    repository = SupabaseProductRepository(SupabaseService(client));
  });

  test('loads products with marketplace offers', () async {
    final products = await repository.getProducts();
    expect(products, isNotEmpty);
    for (final p in products) {
      expect(p.offers, isNotEmpty, reason: p.name);
      expect(p.currentPrice, p.cheapestOffer.price);
    }
  }, skip: skip);

  test('product detail loads 4 marketplaces, images and price history in one call', () async {
    final first = (await repository.getProducts()).first;
    final detail = (await repository.getProductById(first.id))!;

    final offers = detail.sortedOffers;
    expect(offers.map((o) => o.marketplace.code).toSet(), hasLength(4));
    for (var i = 1; i < offers.length; i++) {
      expect(offers[i].price, greaterThanOrEqualTo(offers[i - 1].price));
    }
    expect(detail.currentPrice, offers.first.price);
    expect(detail.galleryUrls, isNotEmpty);
    for (final offer in offers) {
      expect(offer.priceHistory, isNotEmpty, reason: offer.marketplace.name);
      final dates = offer.priceHistory.map((p) => p.date).toList();
      expect([...dates]..sort(), dates, reason: 'history must be oldest first');
      if ((offer.originalPrice ?? 0) > offer.price) expect(offer.discountPercent, greaterThan(0));
    }
    expect(detail.priceHistory, isNotEmpty);
  }, skip: skip);

  test('home sections and categories load', () async {
    expect(await repository.getCategories(), isNotEmpty);
    expect(await repository.getTodayDeals(), isNotEmpty);
    expect(await repository.getRecommendations(), isNotEmpty);
  }, skip: skip);

  test('product by id, category and search queries', () async {
    final first = (await repository.getProducts()).first;
    expect((await repository.getProductById(first.id))?.name, first.name);

    final laptops = await repository.getProductsByCategory('laptop');
    expect(laptops, isNotEmpty);
    expect(laptops.every((p) => p.categoryId == 'laptop'), isTrue);

    final byCategory = await repository.searchProducts('Tìm laptop dưới 25 triệu để code');
    expect(byCategory.intent.categoryId, 'laptop');
    expect(byCategory.intent.maxPrice, 25000000);
    expect(byCategory.products, isNotEmpty);

    final byBrand = await repository.searchProducts('Sony');
    expect(byBrand.products.every((p) => p.brand == 'Sony'), isTrue);

    final byText = await repository.searchProducts('Galaxy S25');
    expect(byText.products.map((p) => p.name), contains('Samsung Galaxy S25 Ultra'));
  }, skip: skip);
}
