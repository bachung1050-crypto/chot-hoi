import 'package:chot_hoi/core/ai/recommendation_scorer.dart';
import 'package:chot_hoi/core/utils/product_specs.dart';
import 'package:chot_hoi/models/marketplace.dart';
import 'package:chot_hoi/models/product.dart';
import 'package:chot_hoi/models/search_intent.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required String id,
  required Map<String, dynamic> specs,
  String brand = 'ASUS',
  int price = 21000000,
}) {
  const marketplace = Marketplace(id: 'shopee', code: MarketplaceCode.shopee, name: 'Shopee');
  return Product(
    id: id,
    name: id,
    slug: id,
    description: '',
    tagline: '',
    brand: brand,
    categoryId: 'laptop',
    imageUrl: '',
    galleryUrls: const [],
    rating: 4.5,
    reviewCount: 100,
    soldCount: 0,
    currentPrice: price,
    originalPrice: price + 1000000,
    discountPercent: 5,
    chotHoiScore: 80,
    isGoodDeal: true,
    inStock: true,
    marketplace: marketplace,
    marketplaceProductId: 'mp-$id',
    productUrl: 'https://example.com',
    affiliateUrl: '',
    specsSummary: ProductSpecs.summary(specs),
    badges: const [],
    useCases: ProductSpecs.useCases(specs),
    specs: specs,
    aiSummary: '',
    aiHighlights: const [],
    pros: const [],
    cons: const [],
    offers: [
      MarketplaceOffer(
        marketplace: marketplace,
        price: price,
        productUrl: 'https://example.com',
        marketplaceProductId: 'mp-$id',
      ),
    ],
    priceHistory: const [],
  );
}

void main() {
  group('ProductSpecs', () {
    test('parses ram GB from specs.ram only', () {
      expect(ProductSpecs.ramGb({'ram': '16GB'}), 16);
      expect(ProductSpecs.ramGb({'ram': '8 GB'}), 8);
      expect(ProductSpecs.ramGb({'storage': '512GB SSD'}), isNull);
      expect(ProductSpecs.ramGb({}), isNull);
    });
  });

  group('RecommendationScorer RAM via specs', () {
    const intent = SearchIntent(
      query: 'Laptop RAM 16GB',
      category: 'laptop',
      maxPrice: 25000000,
      minRam: 16,
      useCase: 'coding',
    );

    test('RAM 16GB meets requirement and explains accurately', () {
      final product = _product(
        id: 'ok',
        specs: {
          'ram': '16GB',
          'cpu': 'Intel Core Ultra 7',
          'use_cases': ['coding'],
        },
      );
      final rec = RecommendationScorer.score(intent, [product]).first;
      expect(product.ramGb, 16);
      expect(rec.pros.any((p) => p.contains('RAM 16GB đáp ứng')), isTrue);
      expect(rec.cons.any((c) => c.contains('Chưa có dữ liệu RAM')), isFalse);
    });

    test('RAM 8GB below requirement reduces explanation and does not claim pass', () {
      final product = _product(
        id: 'low',
        specs: {'ram': '8GB', 'cpu': 'Apple A18 Pro', 'use_cases': ['productivity']},
      );
      final rec = RecommendationScorer.score(intent, [product]).first;
      expect(rec.cons.any((c) => c.contains('RAM 8GB thấp hơn yêu cầu tối thiểu 16GB')), isTrue);
    });

    test('missing specs.ram does not invent a pass', () {
      final product = _product(
        id: 'none',
        specs: {'anc': 'ANC', 'battery': '40 hours'}, // headphone-like — no ram
      );
      final rec = RecommendationScorer.score(intent, [product]).first;
      expect(product.ramGb, isNull);
      expect(rec.cons.any((c) => c.contains('Chưa có dữ liệu RAM để xác minh')), isTrue);
      expect(rec.pros.any((p) => p.contains('đáp ứng yêu cầu tối thiểu')), isFalse);
    });

    test('product with enough RAM scores higher than under-spec RAM', () {
      final enough = _product(id: '16', specs: {'ram': '16GB', 'use_cases': ['coding']});
      final low = _product(id: '8', specs: {'ram': '8GB', 'use_cases': ['coding']});
      final enoughScore = RecommendationScorer.score(intent, [enough]).first.specScore;
      final lowScore = RecommendationScorer.score(intent, [low]).first.specScore;
      expect(enoughScore, greaterThan(lowScore));
    });
  });
}
