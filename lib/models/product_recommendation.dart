import 'ai_score_explanation.dart';

/// Ranked fit of one product against a [SearchIntent].
///
/// Scores are produced by deterministic rules; [reason]/[pros]/[cons] and
/// optional [explanation] may come from a template fallback or one Edge Function call.
class ProductRecommendation {
  const ProductRecommendation({
    required this.productId,
    required this.rank,
    required this.score,
    required this.reason,
    this.pros = const [],
    this.cons = const [],
    this.isBestChoice = false,
    this.priceScore = 0,
    this.specScore = 0,
    this.reviewScore = 0,
    this.priceHistoryScore = 0,
    this.preferenceScore = 0,
    this.explanation,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List ? value.whereType<String>().toList() : const [];
    final explanationJson = json['explanation'];
    return ProductRecommendation(
      productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
      rank: (json['rank'] as num?)?.round() ?? 0,
      score: (json['score'] as num?)?.round() ?? 0,
      reason: json['reason'] as String? ?? json['summary'] as String? ?? '',
      pros: strings(json['pros'] ?? json['reasons']),
      cons: strings(json['cons'] ?? json['warnings']),
      isBestChoice: json['isBestChoice'] as bool? ?? json['is_best_choice'] as bool? ?? false,
      explanation: explanationJson is Map
          ? AiScoreExplanation.fromJson(Map<String, dynamic>.from(explanationJson))
          : (json.containsKey('summary') || json.containsKey('verdict')
                ? AiScoreExplanation.fromJson(Map<String, dynamic>.from(json))
                : null),
    );
  }

  final String productId;
  final int rank;

  /// 0–100 composite fit score.
  final int score;
  final String reason;
  final List<String> pros;
  final List<String> cons;
  final bool isBestChoice;

  /// Breakdown used for explainability (not always sent by the Edge Function).
  final int priceScore;
  final int specScore;
  final int reviewScore;
  final int priceHistoryScore;
  final int preferenceScore;

  /// Rich AI / fallback explanation (typically only on the #1 pick).
  final AiScoreExplanation? explanation;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'rank': rank,
    'score': score,
    'reason': reason,
    'pros': pros,
    'cons': cons,
    'isBestChoice': isBestChoice,
    if (explanation != null) 'explanation': explanation!.toJson(),
  };

  ProductRecommendation copyWith({
    int? rank,
    int? score,
    String? reason,
    List<String>? pros,
    List<String>? cons,
    bool? isBestChoice,
    AiScoreExplanation? explanation,
    bool clearExplanation = false,
  }) => ProductRecommendation(
    productId: productId,
    rank: rank ?? this.rank,
    score: score ?? this.score,
    reason: reason ?? this.reason,
    pros: pros ?? this.pros,
    cons: cons ?? this.cons,
    isBestChoice: isBestChoice ?? this.isBestChoice,
    priceScore: priceScore,
    specScore: specScore,
    reviewScore: reviewScore,
    priceHistoryScore: priceHistoryScore,
    preferenceScore: preferenceScore,
    explanation: clearExplanation ? null : (explanation ?? this.explanation),
  );
}
