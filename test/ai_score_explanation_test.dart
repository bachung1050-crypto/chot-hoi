import 'package:chot_hoi/core/ai/ai_recommendation_service.dart';
import 'package:chot_hoi/core/ai/deterministic_score_explainer.dart';
import 'package:chot_hoi/core/ai/recommendation_scorer.dart';
import 'package:chot_hoi/core/ai/supabase_ai_recommendation_service.dart';
import 'package:chot_hoi/models/ai_score_explanation.dart';
import 'package:chot_hoi/models/marketplace.dart';
import 'package:chot_hoi/models/price_history.dart';
import 'package:chot_hoi/models/product.dart';
import 'package:chot_hoi/models/product_recommendation.dart';
import 'package:chot_hoi/models/search_intent.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required String id,
  required int price,
  double rating = 4.8,
  int reviewCount = 890,
  List<PriceHistoryPoint> history = const [],
}) {
  const marketplace = Marketplace(id: 'shopee', code: MarketplaceCode.shopee, name: 'Shopee');
  return Product(
    id: id,
    name: 'ASUS Vivobook',
    slug: id,
    description: 'Laptop 16GB',
    tagline: '',
    brand: 'ASUS',
    categoryId: 'laptop',
    imageUrl: '',
    galleryUrls: const [],
    rating: rating,
    reviewCount: reviewCount,
    soldCount: 0,
    currentPrice: price,
    originalPrice: price + 3000000,
    discountPercent: 10,
    chotHoiScore: 80,
    isGoodDeal: true,
    inStock: true,
    marketplace: marketplace,
    marketplaceProductId: 'mp-$id',
    productUrl: 'https://example.com',
    affiliateUrl: '',
    specsSummary: 'Ryzen 7 | 16GB | 512GB',
    badges: const [],
    useCases: const ['code'],
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
    priceHistory: history,
  );
}

void main() {
  group('AiScoreExplanation verdict bands', () {
    test('score >= 80 → ĐÁNG MUA', () {
      expect(AiScoreExplanation.verdictForScore(80), AiScoreExplanation.verdictBuy);
      expect(AiScoreExplanation.verdictForScore(99), AiScoreExplanation.verdictBuy);
    });

    test('score 60-79 → CÂN NHẮC', () {
      expect(AiScoreExplanation.verdictForScore(60), AiScoreExplanation.verdictConsider);
      expect(AiScoreExplanation.verdictForScore(79), AiScoreExplanation.verdictConsider);
    });

    test('score < 60 → CHƯA NÊN MUA', () {
      expect(AiScoreExplanation.verdictForScore(59), AiScoreExplanation.verdictAvoid);
      expect(AiScoreExplanation.verdictForScore(0), AiScoreExplanation.verdictAvoid);
    });

    test('normalizeVerdict forces score band over conflicting AI text', () {
      expect(
        AiScoreExplanation.normalizeVerdict('ĐÁNG MUA', score: 50),
        AiScoreExplanation.verdictAvoid,
      );
      expect(
        AiScoreExplanation.normalizeVerdict('CHƯA NÊN MUA', score: 90),
        AiScoreExplanation.verdictBuy,
      );
    });

    test('malformed AI response still parses with score-based verdict', () {
      final parsed = AiScoreExplanation.fromJson({
        'summary': '  Tóm tắt  ',
        'verdict': '???',
        'reasons': ['a', 1, null, 'b'],
        'warnings': 'not-a-list',
        'priceInsight': '',
        'reviewInsight': 'Có rating',
        'score': 82,
      });
      expect(parsed.summary, 'Tóm tắt');
      expect(parsed.verdict, AiScoreExplanation.verdictBuy);
      expect(parsed.reasons, ['a', '1', 'b']);
      expect(parsed.warnings, isEmpty);
      expect(parsed.priceInsight, isNull);
      expect(parsed.reviewInsight, 'Có rating');
    });
  });

  group('DeterministicScoreExplainer', () {
    const intent = SearchIntent(
      query: 'Laptop dưới 25 triệu để code',
      category: 'laptop',
      brands: ['ASUS'],
      maxPrice: 25000000,
      minRam: 16,
      useCase: 'code',
    );

    test('missing price history and reviews produce clear warnings', () {
      final product = _product(id: 'bare', price: 21000000, rating: 0, reviewCount: 0);
      final rec = RecommendationScorer.score(intent, [product]).first;
      final explanation = DeterministicScoreExplainer.explain(
        product: product,
        intent: intent,
        recommendation: rec,
      );
      expect(explanation.verdict, AiScoreExplanation.verdictForScore(rec.score));
      expect(explanation.warnings.any((w) => w.contains('lịch sử giá')), isTrue);
      expect(explanation.warnings.any((w) => w.contains('đánh giá')), isTrue);
      expect(explanation.reviewInsight, contains('Chưa có đủ dữ liệu'));
      expect(explanation.priceInsight, contains('thấp hơn ngân sách'));
    });

    test('FallbackAiRecommendationService attaches explanation only on #1', () async {
      final products = [
        _product(id: 'a', price: 21000000),
        _product(id: 'b', price: 24000000, rating: 4.2, reviewCount: 10),
      ];
      const service = FallbackAiRecommendationService();
      final recs = await service.recommend(intent, products);
      expect(recs.first.explanation, isNotNull);
      expect(recs.first.isBestChoice, isTrue);
      if (recs.length > 1) {
        expect(recs[1].explanation, isNull);
      }
    });
  });

  test('Edge Function name remains ai-recommend', () {
    expect(SupabaseAiRecommendationService.functionName, 'ai-recommend');
  });

  test('ProductRecommendation.fromJson accepts explanation payload', () {
    final rec = ProductRecommendation.fromJson({
      'productId': 'p1',
      'rank': 1,
      'score': 82,
      'summary': 'Phù hợp tốt',
      'verdict': 'ĐÁNG MUA',
      'reasons': ['Giá tốt'],
      'warnings': ['Thiếu lịch sử giá'],
      'priceInsight': '21 triệu',
      'reviewInsight': '4.8★',
      'matchInsight': 'Đúng ASUS',
      'isBestChoice': true,
    });
    expect(rec.score, 82);
    expect(rec.reason, 'Phù hợp tốt');
    expect(rec.explanation?.verdict, AiScoreExplanation.verdictBuy);
    expect(rec.explanation?.reasons, ['Giá tốt']);
    expect(rec.explanation?.warnings, ['Thiếu lịch sử giá']);
  });
}
