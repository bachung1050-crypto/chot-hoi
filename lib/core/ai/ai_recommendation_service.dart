import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../models/product_recommendation.dart';
import '../../models/search_intent.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'deterministic_score_explainer.dart';
import 'recommendation_scorer.dart';
import 'supabase_ai_recommendation_service.dart';

/// Ranks a small candidate set against [SearchIntent] in **one** request.
///
/// Scores are always deterministic ([RecommendationScorer]). AI (if configured)
/// only explains the #1 pick — never invents products, prices, ratings, or scores.
abstract interface class AiRecommendationService {
  Future<List<ProductRecommendation>> recommend(SearchIntent intent, List<Product> products);
}

/// Local scoring + deterministic explanation for #1 (used when OpenAI / Edge Function is unavailable).
class FallbackAiRecommendationService implements AiRecommendationService {
  const FallbackAiRecommendationService();

  @override
  Future<List<ProductRecommendation>> recommend(SearchIntent intent, List<Product> products) async {
    final scored = RecommendationScorer.score(intent, products);
    if (scored.isEmpty) return scored;
    final byId = {for (final p in products) p.id: p};
    final best = scored.first;
    final product = byId[best.productId];
    if (product == null) return scored;
    final explanation = DeterministicScoreExplainer.explain(
      product: product,
      intent: intent,
      recommendation: best,
    );
    return [
      best.copyWith(
        reason: explanation.summary,
        pros: explanation.reasons.isNotEmpty ? explanation.reasons : best.pros,
        cons: explanation.warnings.isNotEmpty ? explanation.warnings : best.cons,
        explanation: explanation,
      ),
      ...scored.skip(1),
    ];
  }
}

final aiRecommendationServiceProvider = Provider<AiRecommendationService>((ref) {
  if (AppConfig.useMockData) return const FallbackAiRecommendationService();
  return SupabaseAiRecommendationService(
    ref.watch(supabaseServiceProvider),
    fallback: const FallbackAiRecommendationService(),
  );
});
