/// AI (or deterministic fallback) explanation for an already-computed Chốt Hời score.
///
/// Never carries its own score — [ProductRecommendation.score] remains authoritative.
class AiScoreExplanation {
  const AiScoreExplanation({
    required this.summary,
    required this.verdict,
    this.reasons = const [],
    this.warnings = const [],
    this.priceInsight,
    this.reviewInsight,
    this.matchInsight,
  });

  factory AiScoreExplanation.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) =>
        value is List ? value.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList() : const [];

    final summary = (json['summary'] as String?)?.trim() ?? (json['reason'] as String?)?.trim() ?? '';
    final verdictRaw = (json['verdict'] as String?)?.trim();
    final score = (json['score'] as num?)?.round();

    return AiScoreExplanation(
      summary: summary,
      verdict: normalizeVerdict(verdictRaw, score: score),
      reasons: strings(json['reasons'] ?? json['pros']),
      warnings: strings(json['warnings'] ?? json['cons']),
      priceInsight: _optionalString(json['priceInsight'] ?? json['price_insight']),
      reviewInsight: _optionalString(json['reviewInsight'] ?? json['review_insight']),
      matchInsight: _optionalString(json['matchInsight'] ?? json['match_insight']),
    );
  }

  final String summary;

  /// One of [verdictBuy], [verdictConsider], [verdictAvoid].
  final String verdict;
  final List<String> reasons;
  final List<String> warnings;
  final String? priceInsight;
  final String? reviewInsight;
  final String? matchInsight;

  static const String verdictBuy = 'ĐÁNG MUA';
  static const String verdictConsider = 'CÂN NHẮC';
  static const String verdictAvoid = 'CHƯA NÊN MUA';

  /// Deterministic verdict from score (AI must not invent a conflicting label).
  static String verdictForScore(int score) {
    if (score >= 80) return verdictBuy;
    if (score >= 60) return verdictConsider;
    return verdictAvoid;
  }

  /// Prefer AI verdict when it matches score bands; otherwise force score-based label.
  static String normalizeVerdict(String? raw, {int? score}) {
    final expected = score == null ? null : verdictForScore(score);
    final normalized = (raw ?? '').trim().toUpperCase();
    const allowed = {verdictBuy, verdictConsider, verdictAvoid};
    if (allowed.contains(normalized) && (expected == null || normalized == expected)) {
      return normalized;
    }
    // Soft match common variants.
    if (normalized.contains('ĐÁNG MUA') || normalized.contains('DANG MUA')) {
      return expected ?? verdictBuy;
    }
    if (normalized.contains('CÂN NHẮC') || normalized.contains('CAN NHAC')) {
      return expected ?? verdictConsider;
    }
    if (normalized.contains('CHƯA') || normalized.contains('CHUA') || normalized.contains('KHÔNG NÊN')) {
      return expected ?? verdictAvoid;
    }
    return expected ?? verdictConsider;
  }

  static String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'verdict': verdict,
    'reasons': reasons,
    'warnings': warnings,
    if (priceInsight != null) 'priceInsight': priceInsight,
    if (reviewInsight != null) 'reviewInsight': reviewInsight,
    if (matchInsight != null) 'matchInsight': matchInsight,
  };

  bool get hasRichContent =>
      summary.isNotEmpty ||
      reasons.isNotEmpty ||
      warnings.isNotEmpty ||
      (priceInsight?.isNotEmpty ?? false) ||
      (reviewInsight?.isNotEmpty ?? false) ||
      (matchInsight?.isNotEmpty ?? false);
}
