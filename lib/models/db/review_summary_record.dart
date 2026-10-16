import 'dart:convert';

import '../../models/review_summary.dart';
import 'json_read.dart';

/// Row of `public.review_summaries` (FK: `product_id` → `products`).
///
/// Schema has no dedicated highlights/warnings/sentiment columns.
/// We store the main summary in [positiveSummary] and a small JSON meta blob
/// in [negativeSummary]: `{highlights,warnings,sentiment,confidence}`.
class ReviewSummaryRecord {
  const ReviewSummaryRecord({
    required this.id,
    required this.productId,
    this.pros = const [],
    this.cons = const [],
    this.aiScore,
    this.model,
    this.totalReviews = 0,
    this.generatedAt,
    this.positiveSummary,
    this.negativeSummary,
  });

  factory ReviewSummaryRecord.fromJson(Map<String, dynamic> json) => ReviewSummaryRecord(
    id: json['id'] as String,
    productId: json['product_id'] as String? ?? '',
    pros: JsonRead.stringList(json['pros']),
    cons: JsonRead.stringList(json['cons']),
    aiScore: JsonRead.toIntOrNull(json['ai_score']),
    model: json['model'] as String?,
    totalReviews: JsonRead.toInt(json['total_reviews']),
    generatedAt: JsonRead.toDate(json['generated_at']),
    positiveSummary: json['positive_summary'] as String?,
    negativeSummary: json['negative_summary'] as String?,
  );

  final String id;
  final String productId;
  final List<String> pros;
  final List<String> cons;
  final int? aiScore;
  final String? model;
  final int totalReviews;
  final DateTime? generatedAt;
  final String? positiveSummary;
  final String? negativeSummary;

  /// Convert DB row → UI [ReviewSummary].
  ReviewSummary toReviewSummary({bool fromCache = true}) {
    final meta = _parseMeta(negativeSummary);
    return ReviewSummary(
      summary: (positiveSummary ?? '').trim().isNotEmpty
          ? positiveSummary!.trim()
          : ReviewSummary.emptySummary,
      pros: pros,
      cons: cons,
      highlights: meta.highlights,
      warnings: meta.warnings.isNotEmpty
          ? meta.warnings
          : (meta.isJson ? const <String>[] : _plainWarnings(negativeSummary)),
      sentiment: ReviewSummary.normalizeSentiment(meta.sentiment),
      confidence: meta.confidence,
      totalReviews: totalReviews,
      generatedAt: generatedAt,
      model: model,
      aiScore: aiScore,
      fromCache: fromCache,
    );
  }

  static List<String> _plainWarnings(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim().startsWith('{')) return const [];
    return raw
        .split(RegExp(r'[\n|•]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static ({List<String> highlights, List<String> warnings, String sentiment, double confidence, bool isJson})
  _parseMeta(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (
        highlights: const <String>[],
        warnings: const <String>[],
        sentiment: ReviewSummary.sentimentNeutral,
        confidence: 0,
        isJson: false,
      );
    }
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{')) {
      return (
        highlights: const <String>[],
        warnings: const <String>[],
        sentiment: ReviewSummary.sentimentNeutral,
        confidence: 0,
        isJson: false,
      );
    }
    try {
      final map = jsonDecode(trimmed);
      if (map is! Map) {
        return (
          highlights: const <String>[],
          warnings: const <String>[],
          sentiment: ReviewSummary.sentimentNeutral,
          confidence: 0,
          isJson: true,
        );
      }
      List<String> list(Object? value) => value is List
          ? [
              for (final item in value)
                if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
            ]
          : const [];
      final confidenceRaw = map['confidence'];
      final confidence = switch (confidenceRaw) {
        final num n => n.toDouble().clamp(0.0, 1.0).toDouble(),
        final String s => (double.tryParse(s) ?? 0).clamp(0.0, 1.0).toDouble(),
        _ => 0.0,
      };
      return (
        highlights: list(map['highlights']),
        warnings: list(map['warnings']),
        sentiment: (map['sentiment'] as String?) ?? ReviewSummary.sentimentNeutral,
        confidence: confidence,
        isJson: true,
      );
    } catch (_) {
      return (
        highlights: const <String>[],
        warnings: const <String>[],
        sentiment: ReviewSummary.sentimentNeutral,
        confidence: 0,
        isJson: false,
      );
    }
  }

  /// Encode highlights/warnings/sentiment/confidence into [negative_summary].
  static String encodeMeta({
    required List<String> highlights,
    required List<String> warnings,
    required String sentiment,
    required double confidence,
  }) => jsonEncode({
    'highlights': highlights,
    'warnings': warnings,
    'sentiment': ReviewSummary.normalizeSentiment(sentiment),
    'confidence': confidence.clamp(0, 1),
  });
}
