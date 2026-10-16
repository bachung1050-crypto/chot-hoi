import 'package:chot_hoi/core/utils/price_math.dart';
import 'package:chot_hoi/models/db/category_record.dart';
import 'package:chot_hoi/models/price_history.dart';
import 'package:chot_hoi/models/db/product_record.dart';
import 'package:chot_hoi/models/marketplace.dart';
import 'package:chot_hoi/repositories/supabase/product_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _listing(String id, String code, String name, num price, {bool active = true}) => {
  'id': id,
  'product_id': 'p-1',
  'marketplace_id': 'm-$code',
  'title': 'Samsung Galaxy S25 Ultra',
  'product_url': 'https://example.com/$code',
  'affiliate_url': 'https://aff.example.com/$code',
  'current_price': price,
  'original_price': 33588800.00,
  'stock_status': 'in_stock',
  'seller_name': 'CHỐT HỜI Official Store',
  'rating': 4.8,
  'review_count': 2800,
  'is_active': active,
  'marketplaces': {'id': 'm-$code', 'code': code, 'name': name, 'logo_url': null},
  'marketplace_product_images': [
    {'id': 'img2-$id', 'marketplace_product_id': id, 'image_url': 'https://img/$id-2.jpg', 'sort_order': 1},
    {'id': 'img-$id', 'marketplace_product_id': id, 'image_url': 'https://img/$id.jpg', 'sort_order': 0},
  ],
  'price_history': [
    {'id': 'h3-$id', 'marketplace_product_id': id, 'price': price, 'recorded_at': '2026-10-15T00:00:00Z'},
    {'id': 'h1-$id', 'marketplace_product_id': id, 'price': price + 2000000, 'recorded_at': '2026-09-01T00:00:00Z'},
    {'id': 'h2-$id', 'marketplace_product_id': id, 'price': price + 500000, 'recorded_at': '2026-09-20T00:00:00Z'},
  ],
};

/// Shape returned by `SupabaseProductRepository.getProductById` (detail select).
final Map<String, dynamic> supabaseProductRow = {
  'id': '251f9189-0b90-437a-ad87-50ba3bf0e99f',
  'name': 'Samsung Galaxy S25 Ultra',
  'slug': 'samsung-galaxy-s25-ultra',
  'description': 'Flagship Samsung Galaxy S25 Ultra.',
  'rating': 4.90,
  'review_count': 2800,
  'is_active': true,
  'specs': {
    'ram': '12GB',
    'storage': '256GB',
    'chip': 'Snapdragon 8 Elite',
    'display': '6.9 inch Dynamic AMOLED',
    'use_cases': ['photography', 'productivity'],
  },
  'brands': {'id': 'b-1', 'name': 'Samsung', 'slug': 'samsung'},
  'categories': {'id': 'c-1', 'name': 'Điện thoại', 'slug': 'dien-thoai', 'parent_id': null, 'level': 1},
  'marketplace_products': [
    _listing('mp-tiki', 'TIKI', 'Tiki', 30739750.00),
    _listing('mp-shopee', 'SHOPEE', 'Shopee', 29090300.00),
    _listing('mp-lazada', 'LAZADA', 'Lazada', 29990000.00),
    _listing('mp-tiktok', 'TIKTOK_SHOP', 'TikTok Shop', 29540150.00),
    _listing('mp-off', 'SHOPEE', 'Shopee', 1000.00, active: false),
  ],
  'review_summaries': [
    {
      'id': 'rs-1',
      'product_id': '251f9189-0b90-437a-ad87-50ba3bf0e99f',
      'pros': ['Camera đẹp', 'Pin trâu'],
      'cons': ['Giá cao'],
      'ai_score': 88,
      'model': 'demo',
      'total_reviews': 2800,
      'generated_at': '2026-10-15T12:00:00Z',
      'positive_summary': 'Người dùng đánh giá cao camera và pin.',
      'negative_summary':
          '{"highlights":["Camera tốt"],"warnings":["Giá cao"],"sentiment":"positive","confidence":0.88}',
    },
  ],
};

void main() {
  final row = supabaseProductRow;

  test('maps a products row with listings into the UI Product', () {
    final product = ProductMapper.toProduct(ProductRecord.fromJson(row))!;

    expect(product.brand, 'Samsung');
    expect(product.categoryId, 'phone');
    expect(product.offers, hasLength(4));
    expect(product.marketplace.code, MarketplaceCode.shopee);
    expect(product.currentPrice, 29090300);
    expect(product.originalPrice, 33588800);
    expect(product.discountPercent, 13);
    expect(product.highestOfferPrice, 30739750);
    expect(product.affiliateUrl, 'https://aff.example.com/SHOPEE');
    expect(product.imageUrl, 'https://img/mp-shopee.jpg');
    expect(product.galleryUrls.take(2), ['https://img/mp-shopee.jpg', 'https://img/mp-shopee-2.jpg']);
    expect(product.sortedOffers.map((o) => o.marketplace.name), ['Shopee', 'TikTok Shop', 'Lazada', 'Tiki']);
  });

  test('offers carry listing details and their own sorted price history', () {
    final product = ProductMapper.toProduct(ProductRecord.fromJson(row))!;
    final tiki = product.offers.firstWhere((o) => o.marketplace.code == MarketplaceCode.tiki);

    expect(tiki.sellerName, 'CHỐT HỜI Official Store');
    expect(tiki.originalPrice, 33588800);
    expect(tiki.discountPercent, 8);
    expect(tiki.rating, 4.8);
    expect(tiki.reviewCount, 2800);
    expect(tiki.stockStatus, 'in_stock');
    expect(tiki.priceHistory.map((p) => p.price), [32739750, 31239750, 30739750]);
    expect(product.priceHistory.last.price, product.currentPrice);
  });

  test('maps review_summaries into pros/cons and reviewAiScore', () {
    final product = ProductMapper.toProduct(ProductRecord.fromJson(row))!;
    expect(product.pros, ['Camera đẹp', 'Pin trâu']);
    expect(product.cons, ['Giá cao']);
    expect(product.reviewAiScore, 88);
    expect(product.rating, 4.90);
    expect(product.reviewCount, 2800);
    expect(product.aiSummary, contains('camera'));
    expect(product.aiHighlights, ['Camera tốt']);
  });

  test('maps products.specs JSONB into specsSummary, useCases and ramGb', () {
    final product = ProductMapper.toProduct(ProductRecord.fromJson(row))!;
    expect(product.ramGb, 12);
    expect(product.useCases, ['photography', 'productivity']);
    expect(product.specsSummary, contains('12GB'));
    expect(product.specs['chip'], 'Snapdragon 8 Elite');
  });

  test('falls back to listing rating/review_count when product aggregates are zero', () {
    final bare = {
      ...row,
      'rating': 0,
      'review_count': 0,
      'review_summaries': <Object>[],
    };
    final product = ProductMapper.toProduct(ProductRecord.fromJson(bare))!;
    expect(product.rating, 4.8); // cheapest shopee listing
    expect(product.reviewCount, 2800);
    expect(product.reviewAiScore, isNull);
    expect(product.pros, isEmpty);
  });

  test('price history stats: lowest, highest, average, trend', () {
    final product = ProductMapper.toProduct(ProductRecord.fromJson(row))!;
    final stats = PriceHistoryStats.fromPoints(product.priceHistory)!;

    expect(stats.lowest, 29090300);
    expect(stats.highest, 31090300);
    expect(stats.average, (31090300 + 29590300 + 29090300) ~/ 3);
    expect(stats.trend, PriceTrend.down);
    expect(PriceHistoryStats.fromPoints(const []), isNull);
  });

  test('discount is only computed when original > current', () {
    expect(PriceMath.discountPercent(originalPrice: 10000000, currentPrice: 8490000), 15);
    expect(PriceMath.discountPercent(originalPrice: 8000000, currentPrice: 8490000), 0);
    expect(PriceMath.discountPercent(originalPrice: null, currentPrice: 8490000), 0);
  });

  test('skips products without an active supported listing', () {
    final record = ProductRecord.fromJson({...row, 'marketplace_products': <Object>[]});
    expect(ProductMapper.toProduct(record), isNull);
  });

  test('category slug maps to the UI key and back', () {
    final category = ProductMapper.toCategory(
      CategoryRecord.fromJson({'id': 'c', 'name': 'Chuột máy tính', 'slug': 'chuot-may-tinh'}),
    );
    expect(category.id, 'mouse');
    expect(ProductMapper.categorySlug('mouse'), 'chuot-may-tinh');
  });
}
