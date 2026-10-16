import 'package:chot_hoi/core/ai/ai_recommendation_service.dart';
import 'package:chot_hoi/core/ai/recommendation_scorer.dart';
import 'package:chot_hoi/core/ai/supabase_ai_recommendation_service.dart';
import 'package:chot_hoi/features/search/providers/ai_search_controller.dart';
import 'package:chot_hoi/models/marketplace.dart';
import 'package:chot_hoi/models/price_history.dart';
import 'package:chot_hoi/models/product.dart';
import 'package:chot_hoi/models/search_intent.dart';
import 'package:chot_hoi/repositories/mock/mock_product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_overrides.dart';

Product _product({
  required String id,
  required String name,
  required String brand,
  required int price,
  String categoryId = 'laptop',
  String specs = 'Ryzen 7 | 16GB | 512GB',
  double rating = 4.7,
  int reviewCount = 200,
  List<String> useCases = const ['code', 'gaming'],
  List<PriceHistoryPoint> history = const [],
  List<String> pros = const [],
  List<String> cons = const [],
  int? reviewAiScore,
}) {
  const marketplace = Marketplace(id: 'shopee', code: MarketplaceCode.shopee, name: 'Shopee');
  final offer = MarketplaceOffer(
    marketplace: marketplace,
    price: price,
    originalPrice: price + 1000000,
    productUrl: 'https://example.com',
    marketplaceProductId: 'mp-$id',
  );
  return Product(
    id: id,
    name: name,
    slug: id,
    description: name,
    tagline: 'tag',
    brand: brand,
    categoryId: categoryId,
    imageUrl: '',
    galleryUrls: const [],
    rating: rating,
    reviewCount: reviewCount,
    soldCount: 100,
    currentPrice: price,
    originalPrice: price + 1000000,
    discountPercent: 5,
    chotHoiScore: 85,
    isGoodDeal: true,
    inStock: true,
    marketplace: marketplace,
    marketplaceProductId: 'mp-$id',
    productUrl: 'https://example.com',
    affiliateUrl: '',
    specsSummary: specs,
    badges: const [],
    useCases: useCases,
    aiSummary: '',
    aiHighlights: const [],
    pros: pros,
    cons: cons,
    offers: [offer],
    priceHistory: history,
    reviewAiScore: reviewAiScore,
  );
}

void main() {
  final intent = const SearchIntent(
    query: 'Laptop dưới 25 triệu để code',
    category: 'laptop',
    brands: ['ASUS', 'Lenovo'],
    maxPrice: 25000000,
    minRam: 16,
    useCase: 'code',
  );

  final products = [
    _product(id: 'asus', name: 'ASUS TUF', brand: 'ASUS', price: 22990000),
    _product(id: 'lenovo', name: 'Lenovo LOQ', brand: 'Lenovo', price: 21990000),
    _product(
      id: 'hp',
      name: 'HP Victus',
      brand: 'HP',
      price: 24990000,
      specs: 'i5 | 8GB | 512GB',
      useCases: const ['gaming'],
    ),
    _product(id: 'over', name: 'ASUS Premium', brand: 'ASUS', price: 32000000, rating: 4.9, reviewCount: 50),
  ];

  group('RecommendationScorer', () {
    test('1-2 laptop code + ASUS/Lenovo ranks preferred brands under budget first', () {
      final recs = RecommendationScorer.score(intent, products);
      expect(recs, isNotEmpty);
      expect(recs.first.isBestChoice, isTrue);
      expect(recs.first.rank, 1);
      expect(['asus', 'lenovo'], contains(recs.first.productId));
      expect(recs.every((r) => r.score >= 0 && r.score <= 100), isTrue);

      final over = recs.firstWhere((r) => r.productId == 'over');
      final best = recs.first;
      expect(best.score, greaterThan(over.score));
    });

    test('3 phone Samsung under 15M', () {
      final phoneIntent = const SearchIntent(category: 'điện thoại', brands: ['Samsung'], maxPrice: 15000000);
      final phones = [
        _product(
          id: 's25',
          name: 'Galaxy S25',
          brand: 'Samsung',
          price: 14990000,
          categoryId: 'phone',
          specs: '8GB | 256GB',
          useCases: const [],
        ),
        _product(
          id: 'pixel',
          name: 'Pixel',
          brand: 'Google',
          price: 12000000,
          categoryId: 'phone',
          specs: '8GB',
          useCases: const [],
        ),
      ];
      final recs = RecommendationScorer.score(phoneIntent, phones);
      expect(recs.first.productId, 's25');
      expect(recs.first.preferenceScore, 100);
    });

    test('4 empty product list', () {
      expect(RecommendationScorer.score(intent, const []), isEmpty);
    });

    test('7-8 missing price history and reviews stay neutral, do not crash', () {
      final bare = _product(
        id: 'bare',
        name: 'Bare',
        brand: 'ASUS',
        price: 20000000,
        rating: 0,
        reviewCount: 0,
        history: const [],
      );
      final recs = RecommendationScorer.score(intent, [bare]);
      expect(recs, hasLength(1));
      expect(recs.first.priceHistoryScore, 50);
      expect(recs.first.reviewScore, 50);
      expect(recs.first.reason, isNotEmpty);
    });

    test('price history near historical low scores higher than near high', () {
      final now = DateTime.now().toUtc();
      final lowHistory = [
        PriceHistoryPoint(date: now.subtract(const Duration(days: 30)), price: 24000000),
        PriceHistoryPoint(date: now.subtract(const Duration(days: 15)), price: 22000000),
        PriceHistoryPoint(date: now.subtract(const Duration(days: 1)), price: 20000000),
      ];
      final highHistory = [
        PriceHistoryPoint(date: now.subtract(const Duration(days: 30)), price: 18000000),
        PriceHistoryPoint(date: now.subtract(const Duration(days: 15)), price: 19000000),
        PriceHistoryPoint(date: now.subtract(const Duration(days: 1)), price: 20000000),
      ];
      final atLow = _product(id: 'low', name: 'Low', brand: 'ASUS', price: 20000000, history: lowHistory);
      final atHigh = _product(id: 'high', name: 'High', brand: 'ASUS', price: 20000000, history: highHistory);
      final lowRec = RecommendationScorer.score(intent, [atLow]).first;
      final highRec = RecommendationScorer.score(intent, [atHigh]).first;
      expect(lowRec.priceHistoryScore, greaterThan(highRec.priceHistoryScore));
    });

    test('review_summaries ai_score blends into reviewScore without inventing rating', () {
      final withSummary = _product(
        id: 'sum',
        name: 'Summary',
        brand: 'ASUS',
        price: 20000000,
        rating: 0,
        reviewCount: 0,
        reviewAiScore: 9, // 0–10 scale → 90
        pros: const ['Pin tốt'],
      );
      final rec = RecommendationScorer.score(intent, [withSummary]).first;
      expect(rec.reviewScore, 90);
      expect(rec.pros, contains('Pin tốt'));
    });

    test('weights are applied (sum of weighted parts ≈ score)', () {
      final rec = RecommendationScorer.score(intent, products).first;
      final expected =
          (rec.priceScore * 0.30 +
                  rec.specScore * 0.25 +
                  rec.reviewScore * 0.20 +
                  rec.priceHistoryScore * 0.15 +
                  rec.preferenceScore * 0.10)
              .round();
      expect(rec.score, expected.clamp(0, 100));
    });

    test('never exceeds candidate limit', () {
      final many = [for (var i = 0; i < 30; i++) _product(id: 'p$i', name: 'P$i', brand: 'ASUS', price: 20000000 + i)];
      expect(RecommendationScorer.score(intent, many), hasLength(RecommendationScorer.candidateLimit));
    });
  });

  group('FallbackAiRecommendationService (no OpenAI)', () {
    test('5 recommend without OpenAI key', () async {
      const service = FallbackAiRecommendationService();
      final recs = await service.recommend(intent, products);
      expect(recs.first.isBestChoice, isTrue);
      expect(recs.first.pros, isNotEmpty);
    });

    test('Edge Function name is ai-recommend', () {
      expect(SupabaseAiRecommendationService.functionName, 'ai-recommend');
    });
  });

  group('search controller wires recommendation', () {
    test('search reorders by recommendation and exposes best pick', () async {
      final container = ProviderContainer(
        overrides: [
          ...mockRepositoryOverrides(),
          // Fast mock products for the known AI search query path
        ],
      );
      addTearDown(container.dispose);

      // Use mock product repository via overrides (already in mockRepositoryOverrides).
      final notifier = container.read(aiSearchProvider.notifier);
      await notifier.searchProducts('Tìm laptop dưới 25 triệu để code, ưu tiên ASUS hoặc Lenovo');

      final state = container.read(aiSearchProvider);
      expect(state.status, AiSearchStatus.success);
      expect(state.bestRecommendation, isNotNull);
      expect(state.bestRecommendation!.score, greaterThan(0));
      expect(state.result!.recommendations, isNotEmpty);
      expect(state.allProducts.first.id, state.bestRecommendation!.productId);
    });

    test('6 empty / no-match query stays empty without crashing', () async {
      final container = ProviderContainer(overrides: mockRepositoryOverrides());
      addTearDown(container.dispose);
      await container.read(aiSearchProvider.notifier).searchProducts('xyzabc không có sản phẩm');
      final state = container.read(aiSearchProvider);
      expect(state.status, anyOf(AiSearchStatus.empty, AiSearchStatus.success));
      if (state.status == AiSearchStatus.empty) {
        expect(state.bestRecommendation, isNull);
      }
    });
  });

  test('MockProductRepository still returns products for recommendation input', () async {
    final repo = MockProductRepository(latency: Duration.zero);
    final result = await repo.searchProducts('Tìm laptop dưới 25 triệu để code');
    expect(result.products, isNotEmpty);
    final recs = RecommendationScorer.score(result.intent, result.products);
    expect(recs.first.isBestChoice, isTrue);
  });
}
