import 'package:chot_hoi/core/ai/ai_review_summary_service.dart';
import 'package:chot_hoi/core/ai/deterministic_review_summarizer.dart';
import 'package:chot_hoi/models/db/review_record.dart';
import 'package:chot_hoi/models/db/review_summary_record.dart';
import 'package:chot_hoi/models/review_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewSummary.fromJson', () {
    test('parses AI success payload', () {
      final summary = ReviewSummary.fromJson({
        'summary': 'Tổng thể tích cực',
        'pros': ['Âm thanh tốt', 'Pin lâu'],
        'cons': ['Giá cao'],
        'highlights': ['Chống ồn được nhắc nhiều'],
        'warnings': ['Kết nối đôi lúc lỗi'],
        'sentiment': 'positive',
        'confidence': 0.91,
        'totalReviews': 28,
        'aiScore': 88,
        'model': 'gpt-4o-mini',
        'generatedAt': '2026-10-16T12:00:00Z',
      });
      expect(summary.summary, 'Tổng thể tích cực');
      expect(summary.pros, ['Âm thanh tốt', 'Pin lâu']);
      expect(summary.cons, ['Giá cao']);
      expect(summary.highlights, ['Chống ồn được nhắc nhiều']);
      expect(summary.warnings, ['Kết nối đôi lúc lỗi']);
      expect(summary.sentiment, ReviewSummary.sentimentPositive);
      expect(summary.confidence, closeTo(0.91, 0.001));
      expect(summary.totalReviews, 28);
      expect(summary.aiScore, 88);
    });

    test('malformed sentiment falls back to neutral', () {
      final summary = ReviewSummary.fromJson({'summary': 'x', 'sentiment': '???', 'confidence': 'nope'});
      expect(summary.sentiment, ReviewSummary.sentimentNeutral);
      expect(summary.confidence, 0);
    });
  });

  group('empty reviews / fallback', () {
    test('empty reviews → empty summary', () {
      final summary = DeterministicReviewSummarizer.summarize(productName: 'X', reviews: const []);
      expect(summary.summary, ReviewSummary.emptySummary);
      expect(summary.pros, isEmpty);
      expect(summary.cons, isEmpty);
      expect(summary.sentiment, ReviewSummary.sentimentNeutral);
    });

    test('stats fallback from DB reviews without inventing prose', () {
      final reviews = [
        const ReviewRecord(
          id: '1',
          marketplaceProductId: 'mp',
          rating: 5,
          content: 'Tôi rất thích chất lượng âm thanh, chống ồn tốt.',
          sentiment: 'positive',
        ),
        const ReviewRecord(
          id: '2',
          marketplaceProductId: 'mp',
          rating: 4,
          content: 'Pin dùng lâu nhưng giá hơi cao.',
          sentiment: 'positive',
        ),
        const ReviewRecord(
          id: '3',
          marketplaceProductId: 'mp',
          rating: 2,
          content: 'Kết nối kém',
          sentiment: 'negative',
        ),
      ];
      final summary = DeterministicReviewSummarizer.summarize(productName: 'Sony', reviews: reviews);
      expect(summary.totalReviews, 3);
      expect(summary.pros, isEmpty); // stats-only — no invented bullets
      expect(summary.summary, contains('3 đánh giá'));
      expect(summary.sentiment, ReviewSummary.sentimentPositive);
      expect(summary.model, 'fallback-stats');
    });

    test('FallbackAiReviewSummaryService does not crash', () async {
      const service = FallbackAiReviewSummaryService();
      final summary = await service.getOrGenerate(
        productId: 'p',
        productName: 'Demo',
        brand: 'ASUS',
      );
      expect(summary.summary, ReviewSummary.emptySummary);
    });
  });

  group('review_summaries cache mapping', () {
    test('DB row maps positive_summary + meta JSON without duplicate invention', () {
      final record = ReviewSummaryRecord.fromJson({
        'id': 'rs-1',
        'product_id': 'p-1',
        'total_reviews': 28,
        'positive_summary': 'Người dùng đánh giá tích cực về âm thanh.',
        'negative_summary':
            '{"highlights":["Chống ồn tốt"],"warnings":["Giá cao"],"sentiment":"positive","confidence":0.9}',
        'pros': ['Âm thanh tốt', 'Chống ồn'],
        'cons': ['Giá khá cao'],
        'ai_score': 86,
        'model': 'gpt-4o-mini',
        'generated_at': '2026-10-16T10:00:00Z',
      });
      final summary = record.toReviewSummary();
      expect(summary.fromCache, isTrue);
      expect(summary.summary, contains('âm thanh'));
      expect(summary.pros, ['Âm thanh tốt', 'Chống ồn']);
      expect(summary.cons, ['Giá khá cao']);
      expect(summary.highlights, ['Chống ồn tốt']);
      expect(summary.warnings, ['Giá cao']);
      expect(summary.sentiment, ReviewSummary.sentimentPositive);
      expect(summary.confidence, closeTo(0.9, 0.001));
    });

    test('encodeMeta round-trip', () {
      final encoded = ReviewSummaryRecord.encodeMeta(
        highlights: ['A'],
        warnings: ['B'],
        sentiment: 'negative',
        confidence: 0.4,
      );
      final record = ReviewSummaryRecord(
        id: 'x',
        productId: 'p',
        positiveSummary: 'S',
        negativeSummary: encoded,
        totalReviews: 1,
      );
      final summary = record.toReviewSummary();
      expect(summary.highlights, ['A']);
      expect(summary.warnings, ['B']);
      expect(summary.sentiment, ReviewSummary.sentimentNegative);
    });
  });

  test('Edge Function name is ai-review-summary', () {
    expect(SupabaseAiReviewSummaryService.functionName, 'ai-review-summary');
  });
}
