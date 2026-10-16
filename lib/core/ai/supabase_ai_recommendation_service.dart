import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ai_score_explanation.dart';
import '../../models/product.dart';
import '../../models/product_recommendation.dart';
import '../../models/search_intent.dart';
import '../services/supabase_service.dart';
import '../utils/product_specs.dart';
import 'ai_recommendation_service.dart';
import 'deterministic_score_explainer.dart';
import 'recommendation_scorer.dart';

/// Scores the shortlist locally, then asks Edge Function `ai-recommend` to explain
/// **only the #1** pick. Never one OpenAI call per product.
class SupabaseAiRecommendationService implements AiRecommendationService {
  // Named `fallback:` so the argument binds across libraries (not `this._fallback`).
  // ignore: prefer_initializing_formals
  const SupabaseAiRecommendationService(this._db, {required AiRecommendationService fallback}) : _fallback = fallback;

  final SupabaseService _db;
  final AiRecommendationService _fallback;

  static const String functionName = 'ai-recommend';

  @override
  Future<List<ProductRecommendation>> recommend(SearchIntent intent, List<Product> products) async {
    final scored = RecommendationScorer.score(intent, products);
    if (scored.isEmpty) return scored;

    final byId = {for (final p in products) p.id: p};
    final best = scored.first;
    final bestProduct = byId[best.productId];
    if (bestProduct == null) return scored;

    // Always attach a deterministic explanation locally; AI may enrich it.
    final localExplain = DeterministicScoreExplainer.explain(
      product: bestProduct,
      intent: intent,
      recommendation: best,
    );
    var withLocal = [
      best.copyWith(
        reason: localExplain.summary,
        pros: localExplain.reasons.isNotEmpty ? localExplain.reasons : best.pros,
        cons: localExplain.warnings.isNotEmpty ? localExplain.warnings : best.cons,
        explanation: localExplain,
      ),
      ...scored.skip(1),
    ];

    try {
      final response = await _db.client.functions.invoke(
        functionName,
        body: {
          'intent': intent.toJson(),
          'product': _productPayload(bestProduct, best),
        },
      );

      final data = response.data;
      if (data is! Map) return withLocal;
      final map = Map<String, dynamic>.from(data);
      if (map['success'] == false) return withLocal;

      final payload = map['data'];
      if (payload is! Map) return withLocal;

      final explained = AiScoreExplanation.fromJson({
        ...Map<String, dynamic>.from(payload),
        'score': best.score, // never let AI override the band
      });

      if (!explained.hasRichContent) return withLocal;

      if (kDebugMode) {
        debugPrint(
          '[ai-recommend] source=${map['source']} score=${best.score} '
          'verdict=${explained.verdict} (product=${bestProduct.id})',
        );
      }

      final enriched = best.copyWith(
        reason: explained.summary.isNotEmpty ? explained.summary : best.reason,
        pros: explained.reasons.isNotEmpty ? explained.reasons : best.pros,
        cons: explained.warnings.isNotEmpty ? explained.warnings : best.cons,
        explanation: explained,
      );
      return [enriched, ...scored.skip(1)];
    } on FunctionException catch (error) {
      if (kDebugMode) {
        debugPrint('[ai-recommend] FunctionException status=${error.status}; using deterministic explanation');
      }
      try {
        return await _fallback.recommend(intent, products);
      } catch (_) {
        return withLocal;
      }
    } on Exception catch (error) {
      if (kDebugMode) {
        debugPrint('[ai-recommend] ${error.runtimeType}; using deterministic explanation');
      }
      return withLocal;
    }
  }

  static Map<String, dynamic> _productPayload(Product product, ProductRecommendation rec) => {
    'name': product.name,
    'brand': product.brand,
    'currentPrice': product.currentPrice,
    'originalPrice': product.originalPrice,
    'rating': product.rating,
    'reviewCount': product.reviewCount,
    'chotHoiScore': rec.score,
    'categoryId': product.categoryId,
    'specsSummary': product.specsSummary,
    'specs': ProductSpecs.toPayload(product.specs),
    'ramGb': product.ramGb,
    'useCases': product.useCases,
    'pros': product.pros.isNotEmpty ? product.pros : rec.pros,
    'cons': product.cons.isNotEmpty ? product.cons : rec.cons,
    'priceHistory': [
      for (final point in product.priceHistory.take(12))
        {'date': point.date.toUtc().toIso8601String(), 'price': point.price},
    ],
    'priceScore': rec.priceScore,
    'specScore': rec.specScore,
    'reviewScore': rec.reviewScore,
    'priceHistoryScore': rec.priceHistoryScore,
    'preferenceScore': rec.preferenceScore,
  };
}
