import '../../models/db/review_record.dart';
import '../../models/review_summary.dart';

/// Local stats-only summary when OpenAI / Edge Function is unavailable.
/// Never invents review prose — only aggregates fields already present.
abstract final class DeterministicReviewSummarizer {
  static ReviewSummary summarize({
    required String productName,
    required List<ReviewRecord> reviews,
  }) {
    if (reviews.isEmpty) return ReviewSummary.empty();

    final total = reviews.length;
    final avg = reviews.fold<double>(0, (sum, r) => sum + r.rating) / total;
    var positive = 0;
    var neutral = 0;
    var negative = 0;
    for (final review in reviews) {
      final sentiment = (review.sentiment ?? '').toLowerCase();
      if (sentiment == 'positive' || review.rating >= 4) {
        positive++;
      } else if (sentiment == 'negative' || review.rating <= 2) {
        negative++;
      } else {
        neutral++;
      }
    }

    final sentiment = positive >= negative && positive >= neutral
        ? ReviewSummary.sentimentPositive
        : negative > positive
        ? ReviewSummary.sentimentNegative
        : ReviewSummary.sentimentNeutral;

    final distribution =
        'Phân bố: ${reviews.where((r) => r.rating == 5).length}×5★, '
        '${reviews.where((r) => r.rating == 4).length}×4★, '
        '${reviews.where((r) => r.rating == 3).length}×3★, '
        '${reviews.where((r) => r.rating <= 2).length}×≤2★.';

    return ReviewSummary(
      summary:
          'Dựa trên $total đánh giá thực tế, điểm trung bình ${avg.toStringAsFixed(1)}/5. '
          '$distribution AI tạm thời không khả dụng nên chưa có tóm tắt nội dung chi tiết.',
      pros: const [],
      cons: const [],
      highlights: [
        if (positive > 0) '$positive đánh giá mang sắc thái tích cực.',
        if (neutral > 0) '$neutral đánh giá mang sắc thái trung lập.',
      ],
      warnings: [
        if (negative > 0) '$negative đánh giá mang sắc thái tiêu cực.',
        'Chưa tạo được tóm tắt AI từ nội dung review — chỉ thống kê từ database.',
      ],
      sentiment: sentiment,
      confidence: (total >= 10 ? 0.55 : 0.35).clamp(0, 1),
      totalReviews: total,
      generatedAt: DateTime.now().toUtc(),
      model: 'fallback-stats',
      aiScore: (avg / 5 * 100).round().clamp(0, 100),
    );
  }
}
