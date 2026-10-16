import 'dart:math' as math;

import '../../models/price_history.dart';
import '../../models/product.dart';
import '../../models/product_recommendation.dart';
import '../../models/search_intent.dart';
import '../utils/text_normalizer.dart';

/// Deterministic fit scores. Weights match Phase 5.2 (total 100%).
///
/// The LLM must never invent these numbers — it may only rewrite [reason]/pros/cons.
abstract final class RecommendationScorer {
  static const double priceWeight = 0.30;
  static const double specWeight = 0.25;
  static const double reviewWeight = 0.20;
  static const double historyWeight = 0.15;
  static const double preferenceWeight = 0.10;

  static const int candidateLimit = 20;

  /// Recent window preferred when scoring price history (days).
  static const int historyRecentDays = 45;

  /// Scores [products] against [intent], highest first. Does not call AI.
  static List<ProductRecommendation> score(SearchIntent intent, List<Product> products) {
    if (products.isEmpty) return const [];

    final candidates = products.take(candidateLimit).toList();
    final prices = candidates.map((p) => p.currentPrice).toList();
    final minInSet = prices.reduce((a, b) => a < b ? a : b);
    final maxInSet = prices.reduce((a, b) => a > b ? a : b);

    final scored = [
      for (final product in candidates) _scoreOne(intent, product, minInSet: minInSet, maxInSet: maxInSet),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return [for (var i = 0; i < scored.length; i++) scored[i].copyWith(rank: i + 1, isBestChoice: i == 0)];
  }

  static ProductRecommendation _scoreOne(
    SearchIntent intent,
    Product product, {
    required int minInSet,
    required int maxInSet,
  }) {
    final price = _priceScore(intent, product, minInSet: minInSet, maxInSet: maxInSet);
    final spec = _specScore(intent, product);
    final review = _reviewScore(product);
    final history = _priceHistoryScore(product);
    final preference = _preferenceScore(intent, product);

    final total =
        (price * priceWeight +
                spec * specWeight +
                review * reviewWeight +
                history * historyWeight +
                preference * preferenceWeight)
            .round()
            .clamp(0, 100);

    final explained = _templateExplain(intent, product, total, price: price, spec: spec, review: review);

    return ProductRecommendation(
      productId: product.id,
      rank: 0,
      score: total,
      reason: explained.reason,
      pros: explained.pros,
      cons: explained.cons,
      priceScore: price,
      specScore: spec,
      reviewScore: review,
      priceHistoryScore: history,
      preferenceScore: preference,
    );
  }

  /// Under budget → high; over budget → penalized; no budget → relative cheapness in set.
  static int _priceScore(SearchIntent intent, Product product, {required int minInSet, required int maxInSet}) {
    final max = intent.maxPrice;
    final min = intent.minPrice;
    final price = product.currentPrice;

    if (max != null) {
      if (price <= max) {
        // Closer to 70–90% of budget scores highest (not "cheapest always wins").
        final ratio = max == 0 ? 1.0 : price / max;
        if (ratio >= 0.55 && ratio <= 0.95) return 100;
        if (ratio < 0.55) return (70 + ratio * 40).round().clamp(50, 90);
        return (100 - (ratio - 0.95) * 200).round().clamp(70, 100);
      }
      final over = (price - max) / max;
      return (60 - over * 120).round().clamp(0, 55);
    }
    if (min != null && price < min) return 40;
    if (maxInSet <= minInSet) return 80;
    final relative = 1 - (price - minInSet) / (maxInSet - minInSet);
    return (50 + relative * 50).round().clamp(40, 100);
  }

  static int _specScore(SearchIntent intent, Product product) {
    final text = TextNormalizer.normalize(
      '${product.name} ${product.specsSummary} ${product.description} ${product.tagline}',
    );
    var points = 40.0;
    var checks = 0;

    if (intent.categoryId != null) {
      checks++;
      if (product.categoryId == intent.categoryId) points += 20;
    }

    final minRam = intent.minRam;
    if (minRam != null) {
      checks++;
      // Prefer structured `specs.ram` — never treat storage/screen "GB" as RAM.
      final ramGb = product.ramGb;
      if (ramGb == null) {
        // Missing data: do not assume pass; slight drag so incomplete specs don't look perfect.
        points -= 5;
      } else if (ramGb >= minRam) {
        points += 25;
      } else if (ramGb >= (minRam * 0.75).ceil()) {
        points += 5;
      } else {
        // Has RAM data but below requirement → reduce spec score.
        points -= 15;
      }
    }

    final useCase = intent.useCase;
    if (useCase != null) {
      checks++;
      final normalizedUse = TextNormalizer.normalize(useCase);
      final productUses = product.useCases.map(TextNormalizer.normalize).toSet();
      final aliases = {
        'code': {'code', 'coding', 'lap trinh'},
        'coding': {'code', 'coding', 'lap trinh'},
      };
      final matchSet = aliases[normalizedUse] ?? {normalizedUse};
      if (productUses.any(matchSet.contains) || matchSet.any(text.contains)) {
        points += 20;
      } else if ((useCase == 'code' || useCase == 'coding') &&
          (text.contains('ryzen') || text.contains('intel') || text.contains('office'))) {
        points += 8;
      }
    }

    for (final feature in intent.features) {
      checks++;
      if (text.contains(TextNormalizer.normalize(feature.replaceAll('_', ' ')))) points += 5;
    }

    if (checks == 0) return product.chotHoiScore.clamp(40, 90);
    return points.round().clamp(0, 100);
  }

  /// Uses real rating / review_count, optional `review_summaries.ai_score`.
  /// Missing data → neutral 50 (never invents reviews).
  static int _reviewScore(Product product) {
    final hasRatingSignal = product.reviewCount > 0 || product.rating > 0;
    final aiNorm = _normalizeAiScore(product.reviewAiScore);

    if (!hasRatingSignal && aiNorm == null) return 50;

    var fromRating = 50;
    if (hasRatingSignal) {
      final ratingPart = (product.rating / 5 * 100).clamp(0, 100);
      final volumeBoost = product.reviewCount >= 500
          ? 10
          : product.reviewCount >= 100
          ? 6
          : product.reviewCount >= 20
          ? 3
          : 0;
      fromRating = (ratingPart * 0.85 + volumeBoost + 5).round().clamp(0, 100);
    }

    if (aiNorm == null) return fromRating;
    if (!hasRatingSignal) return aiNorm;
    return ((fromRating * 0.7) + (aiNorm * 0.3)).round().clamp(0, 100);
  }

  /// Accepts 0–100 or 0–10 style scores from `review_summaries.ai_score`.
  static int? _normalizeAiScore(int? raw) {
    if (raw == null) return null;
    if (raw < 0) return null;
    if (raw <= 10) return (raw * 10).clamp(0, 100);
    return raw.clamp(0, 100);
  }

  /// Trend + current vs recent history. Empty history → neutral 50 (no fake points).
  static int _priceHistoryScore(Product product) {
    final recent = _recentHistory(product.priceHistory);
    final stats = PriceHistoryStats.fromPoints(recent);
    if (stats == null) return 50;

    final trendScore = switch (stats.trend) {
      PriceTrend.down => (75 + (-stats.changePercent).clamp(0, 20)).round().clamp(70, 100),
      PriceTrend.flat => 60,
      PriceTrend.up => (45 - stats.changePercent.clamp(0, 25)).round().clamp(20, 55),
    };

    final current = product.currentPrice;
    var valueScore = 50;
    if (stats.average > 0) {
      final cheaperThanAvg = (stats.average - current) / stats.average;
      valueScore = (50 + cheaperThanAvg * 100).round().clamp(20, 100);
    }
    if (stats.lowest > 0 && current <= (stats.lowest * 1.02).round()) {
      valueScore = math.max(valueScore, 92);
    } else if (stats.highest > 0 && current >= (stats.highest * 0.98).round()) {
      valueScore = math.min(valueScore, 35);
    }

    return ((trendScore * 0.55) + (valueScore * 0.45)).round().clamp(0, 100);
  }

  /// Prefer last [historyRecentDays]; if too sparse, fall back to last 8 points.
  static List<PriceHistoryPoint> _recentHistory(List<PriceHistoryPoint> all) {
    if (all.isEmpty) return const [];
    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: historyRecentDays));
    final window = all.where((p) => !p.date.toUtc().isBefore(cutoff)).toList();
    if (window.length >= 2) return window;
    if (all.length <= 8) return all;
    return all.sublist(all.length - 8);
  }

  static int _preferenceScore(SearchIntent intent, Product product) {
    if (intent.brands.isEmpty) return 70;
    if (intent.brands.contains(product.brand)) return 100;
    return 25;
  }

  static ({String reason, List<String> pros, List<String> cons}) _templateExplain(
    SearchIntent intent,
    Product product,
    int total, {
    required int price,
    required int spec,
    required int review,
  }) {
    final pros = <String>[];
    final cons = <String>[];

    // Prefer stored review_summaries bullets when present (real data, not invented).
    for (final p in product.pros.take(2)) {
      if (p.isNotEmpty) pros.add(p);
    }
    for (final c in product.cons.take(2)) {
      if (c.isNotEmpty) cons.add(c);
    }

    final max = intent.maxPrice;
    if (max != null && product.currentPrice <= max) {
      pros.add('Giá dưới ngân sách');
    } else if (max != null) {
      cons.add('Giá vượt ngân sách đã nêu');
    }

    if (intent.brands.isNotEmpty && intent.brands.contains(product.brand)) {
      pros.add('Đúng thương hiệu bạn ưu tiên (${product.brand})');
    }

    final minRam = intent.minRam;
    if (minRam != null) {
      final ramGb = product.ramGb;
      if (ramGb == null) {
        cons.add('Chưa có dữ liệu RAM để xác minh.');
      } else if (ramGb >= minRam) {
        pros.add('RAM ${ramGb}GB đáp ứng yêu cầu tối thiểu ${minRam}GB.');
      } else {
        cons.add('RAM ${ramGb}GB thấp hơn yêu cầu tối thiểu ${minRam}GB.');
      }
    }

    if (product.rating >= 4.5 && product.reviewCount > 0) {
      pros.add('Đánh giá tốt (${product.rating.toStringAsFixed(1)}★)');
    } else if (product.reviewCount == 0 && product.reviewAiScore == null) {
      cons.add('Chưa có nhiều đánh giá');
    }

    if (product.priceHistory.isEmpty) {
      cons.add('Thiếu lịch sử giá');
    } else {
      final stats = PriceHistoryStats.fromPoints(_recentHistory(product.priceHistory));
      if (stats?.trend == PriceTrend.down) pros.add('Giá đang có xu hướng giảm');
      if (stats?.trend == PriceTrend.up) cons.add('Giá gần đây đang tăng');
      if (stats != null && product.currentPrice <= (stats.lowest * 1.02).round()) {
        pros.add('Gần mức thấp trong lịch sử gần đây');
      }
    }

    if (intent.useCase == 'code' || intent.useCase == 'coding') {
      if (product.useCases.contains('code')) {
        pros.add('Phù hợp nhu cầu lập trình');
      } else {
        cons.add('Chưa tối ưu rõ ràng cho lập trình');
      }
    }

    if (pros.isEmpty) pros.add(product.specsSummary.isEmpty ? 'Đáng xem xét trong ngân sách' : product.specsSummary);

    final useLabel = switch (intent.useCase) {
      'code' || 'coding' => 'lập trình',
      'gaming' => 'chơi game',
      'office' => 'làm việc văn phòng',
      'design' => 'thiết kế',
      _ => 'nhu cầu của bạn',
    };

    final reason = total >= 80
        ? 'Phù hợp tốt với nhu cầu $useLabel — điểm khớp $total/100.'
        : total >= 60
        ? 'Khá phù hợp với nhu cầu $useLabel (điểm $total/100).'
        : 'Có thể cân nhắc cho nhu cầu $useLabel (điểm $total/100).';

    return (reason: reason, pros: pros.take(4).toList(), cons: cons.take(3).toList());
  }
}
