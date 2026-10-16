/// Typed AI / deterministic review analysis for one product.
class ReviewSummary {
  const ReviewSummary({
    required this.summary,
    this.pros = const [],
    this.cons = const [],
    this.highlights = const [],
    this.warnings = const [],
    this.sentiment = sentimentNeutral,
    this.confidence = 0,
    this.totalReviews = 0,
    this.generatedAt,
    this.model,
    this.aiScore,
    this.fromCache = false,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) {
      if (value is! List) return const [];
      return [
        for (final item in value)
          if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
      ];
    }

    final sentimentRaw = (json['sentiment'] as String?)?.trim().toLowerCase() ?? sentimentNeutral;
    final confidenceRaw = json['confidence'];
    final confidence = switch (confidenceRaw) {
      final num n => n.toDouble().clamp(0.0, 1.0).toDouble(),
      final String s => (double.tryParse(s) ?? 0).clamp(0.0, 1.0).toDouble(),
      _ => 0.0,
    };

    DateTime? generatedAt;
    final generatedRaw = json['generatedAt'] ?? json['generated_at'];
    if (generatedRaw is String) generatedAt = DateTime.tryParse(generatedRaw);

    return ReviewSummary(
      summary: (json['summary'] as String?)?.trim() ?? '',
      pros: strings(json['pros']),
      cons: strings(json['cons']),
      highlights: strings(json['highlights']),
      warnings: strings(json['warnings']),
      sentiment: normalizeSentiment(sentimentRaw),
      confidence: confidence,
      totalReviews: (json['totalReviews'] as num?)?.round() ?? (json['total_reviews'] as num?)?.round() ?? 0,
      generatedAt: generatedAt,
      model: json['model'] as String?,
      aiScore: (json['aiScore'] as num?)?.round() ?? (json['ai_score'] as num?)?.round(),
      fromCache: json['fromCache'] as bool? ?? json['from_cache'] as bool? ?? false,
    );
  }

  final String summary;
  final List<String> pros;
  final List<String> cons;
  final List<String> highlights;
  final List<String> warnings;
  final String sentiment;
  final double confidence;
  final int totalReviews;
  final DateTime? generatedAt;
  final String? model;
  final int? aiScore;
  final bool fromCache;

  static const String sentimentPositive = 'positive';
  static const String sentimentNeutral = 'neutral';
  static const String sentimentNegative = 'negative';

  static const String emptySummary = 'Chưa đủ dữ liệu để phân tích đánh giá.';

  static String normalizeSentiment(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == sentimentPositive || value == sentimentNegative || value == sentimentNeutral) {
      return value;
    }
    if (value.contains('pos')) return sentimentPositive;
    if (value.contains('neg')) return sentimentNegative;
    return sentimentNeutral;
  }

  static ReviewSummary empty({int totalReviews = 0}) => ReviewSummary(
    summary: emptySummary,
    sentiment: sentimentNeutral,
    confidence: 0,
    totalReviews: totalReviews,
    generatedAt: DateTime.now().toUtc(),
    model: 'fallback',
  );

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'pros': pros,
    'cons': cons,
    'highlights': highlights,
    'warnings': warnings,
    'sentiment': sentiment,
    'confidence': confidence,
    'totalReviews': totalReviews,
    if (generatedAt != null) 'generatedAt': generatedAt!.toUtc().toIso8601String(),
    if (model != null) 'model': model,
    if (aiScore != null) 'aiScore': aiScore,
    'fromCache': fromCache,
  };

  ReviewSummary copyWith({bool? fromCache}) => ReviewSummary(
    summary: summary,
    pros: pros,
    cons: cons,
    highlights: highlights,
    warnings: warnings,
    sentiment: sentiment,
    confidence: confidence,
    totalReviews: totalReviews,
    generatedAt: generatedAt,
    model: model,
    aiScore: aiScore,
    fromCache: fromCache ?? this.fromCache,
  );

  bool get hasContent =>
      (summary.isNotEmpty && summary != emptySummary) ||
      pros.isNotEmpty ||
      cons.isNotEmpty ||
      highlights.isNotEmpty;
}
