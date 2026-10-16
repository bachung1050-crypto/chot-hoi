import '../../models/ai_score_explanation.dart';
import '../../models/price_history.dart';
import '../../models/product.dart';
import '../../models/product_recommendation.dart';
import '../../models/search_intent.dart';
import '../utils/formatters.dart';

/// Local explanation when Edge Function / OpenAI is unavailable.
/// Uses only fields already on [Product] + deterministic scores — never invents data.
abstract final class DeterministicScoreExplainer {
  static AiScoreExplanation explain({
    required Product product,
    required SearchIntent intent,
    required ProductRecommendation recommendation,
  }) {
    final score = recommendation.score;
    final verdict = AiScoreExplanation.verdictForScore(score);
    final reasons = <String>[
      ...recommendation.pros,
      ...product.pros.take(2),
    ];
    final warnings = <String>[
      ...recommendation.cons,
      ...product.cons.take(2),
    ];

    if (product.priceHistory.isEmpty) {
      warnings.add('Chưa có đủ dữ liệu lịch sử giá để đánh giá xu hướng.');
    }
    if (product.reviewCount <= 0 && product.rating <= 0 && product.reviewAiScore == null) {
      warnings.add('Chưa có đủ dữ liệu đánh giá để khẳng định chất lượng.');
    }

    return AiScoreExplanation(
      summary: recommendation.reason.isNotEmpty
          ? recommendation.reason
          : 'Điểm khớp $score/100 với nhu cầu của bạn.',
      verdict: verdict,
      reasons: _unique(reasons).take(4).toList(),
      warnings: _unique(warnings).take(3).toList(),
      priceInsight: _priceInsight(product, intent),
      reviewInsight: _reviewInsight(product),
      matchInsight: _matchInsight(product, intent, recommendation),
    );
  }

  static String _priceInsight(Product product, SearchIntent intent) {
    final priceLabel = Formatters.millions(product.currentPrice);
    final max = intent.maxPrice;
    if (max != null) {
      if (product.currentPrice <= max) {
        return '$priceLabel, thấp hơn ngân sách ${Formatters.millions(max)}.';
      }
      return '$priceLabel, vượt ngân sách ${Formatters.millions(max)}.';
    }
    if (product.originalPrice > product.currentPrice) {
      return '$priceLabel (đã giảm so với giá gốc ${Formatters.millions(product.originalPrice)}).';
    }
    return 'Giá hiện tại $priceLabel.';
  }

  static String _reviewInsight(Product product) {
    if (product.reviewCount > 0 && product.rating > 0) {
      return '${product.rating.toStringAsFixed(1)}★ từ ${Formatters.compact(product.reviewCount)} lượt đánh giá.';
    }
    if (product.reviewAiScore != null) {
      return 'Có điểm tóm tắt đánh giá AI ${product.reviewAiScore}/100; chưa có đủ rating/review_count.';
    }
    return 'Chưa có đủ dữ liệu đánh giá.';
  }

  static String _matchInsight(Product product, SearchIntent intent, ProductRecommendation rec) {
    final parts = <String>[];
    if (intent.brands.isNotEmpty) {
      parts.add(
        intent.brands.contains(product.brand)
            ? 'Đúng thương hiệu ưu tiên (${product.brand}).'
            : 'Thương hiệu ${product.brand} không nằm trong ưu tiên đã nêu.',
      );
    }
    final minRam = intent.minRam;
    if (minRam != null) {
      final ramGb = product.ramGb;
      if (ramGb == null) {
        parts.add('Chưa có dữ liệu RAM để xác minh.');
      } else if (ramGb >= minRam) {
        parts.add('RAM ${ramGb}GB đáp ứng yêu cầu tối thiểu.');
      } else {
        parts.add('RAM ${ramGb}GB thấp hơn yêu cầu tối thiểu ${minRam}GB.');
      }
    }
    if (intent.useCase != null) {
      parts.add('Độ khớp cấu hình/nhu cầu (specScore ${rec.specScore}/100).');
    }
    if (product.priceHistory.isNotEmpty) {
      final stats = PriceHistoryStats.fromPoints(product.priceHistory);
      if (stats != null) {
        parts.add(
          switch (stats.trend) {
            PriceTrend.down => 'Lịch sử giá gần đây có xu hướng giảm.',
            PriceTrend.up => 'Lịch sử giá gần đây đang tăng.',
            PriceTrend.flat => 'Lịch sử giá gần đây khá ổn định.',
          },
        );
      }
    }
    if (parts.isEmpty) {
      return 'Khớp nhu cầu tổng thể ${rec.score}/100 theo điểm Chốt Hời deterministic.';
    }
    return parts.join(' ');
  }

  static List<String> _unique(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      out.add(trimmed);
    }
    return out;
  }
}
