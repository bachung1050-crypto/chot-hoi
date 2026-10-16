import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/db/review_record.dart';
import '../../models/db/review_summary_record.dart';
import '../../models/review_summary.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'deterministic_review_summarizer.dart';

/// Loads cached [ReviewSummary] or asks Edge Function `ai-review-summary` once.
abstract interface class AiReviewSummaryService {
  Future<ReviewSummary> getOrGenerate({
    required String productId,
    required String productName,
    required String brand,
  });
}

class FallbackAiReviewSummaryService implements AiReviewSummaryService {
  const FallbackAiReviewSummaryService();

  @override
  Future<ReviewSummary> getOrGenerate({
    required String productId,
    required String productName,
    required String brand,
  }) async => ReviewSummary.empty();
}

class SupabaseAiReviewSummaryService implements AiReviewSummaryService {
  const SupabaseAiReviewSummaryService(this._db);

  final SupabaseService _db;

  static const String functionName = 'ai-review-summary';
  static const int maxReviewsForAi = 40;
  static const Duration cacheMaxAge = Duration(days: 7);
  static const double reviewCountChangeRatio = 0.15;
  static const int reviewCountChangeAbsolute = 5;

  @override
  Future<ReviewSummary> getOrGenerate({
    required String productId,
    required String productName,
    required String brand,
  }) async {
    final reviews = await _loadReviews(productId);
    final cached = await _loadCachedSummary(productId);

    if (cached != null && _isCacheValid(cached, reviews.length)) {
      if (kDebugMode) {
        debugPrint(
          '[ai-review-summary] cache hit product=$productId '
          'total=${cached.totalReviews} generated=${cached.generatedAt}',
        );
      }
      return cached.toReviewSummary(fromCache: true);
    }

    if (reviews.isEmpty) {
      return ReviewSummary.empty();
    }

    try {
      final response = await _db.client.functions.invoke(
        functionName,
        body: {
          'product': {'id': productId, 'name': productName, 'brand': brand},
          'reviews': [
            for (final review in reviews.take(maxReviewsForAi))
              {
                'rating': review.rating.round().clamp(1, 5),
                'title': review.title,
                'content': review.content,
                'verifiedPurchase': review.verifiedPurchase,
                'sentiment': review.sentiment,
                'authorName': review.authorName,
                'reviewDate': review.reviewDate?.toUtc().toIso8601String(),
              },
          ],
          'totalReviewCount': reviews.length,
        },
      );

      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['success'] == true && map['data'] is Map) {
          final summary = ReviewSummary.fromJson({
            ...Map<String, dynamic>.from(map['data'] as Map),
            'totalReviews': reviews.length,
            'fromCache': false,
          });
          if (kDebugMode) {
            debugPrint('[ai-review-summary] source=${map['source']} product=$productId');
          }
          if (summary.summary.isNotEmpty) return summary;
        }
      }
    } on FunctionException catch (error) {
      if (kDebugMode) {
        debugPrint('[ai-review-summary] FunctionException status=${error.status}');
      }
    } on Exception catch (error) {
      if (kDebugMode) {
        debugPrint('[ai-review-summary] ${error.runtimeType}');
      }
    }

    return DeterministicReviewSummarizer.summarize(productName: productName, reviews: reviews);
  }

  bool _isCacheValid(ReviewSummaryRecord cached, int currentReviewCount) {
    final generatedAt = cached.generatedAt;
    if (generatedAt == null) return false;
    if (DateTime.now().toUtc().difference(generatedAt.toUtc()) > cacheMaxAge) return false;

    final previous = cached.totalReviews;
    final delta = (currentReviewCount - previous).abs();
    if (delta <= reviewCountChangeAbsolute) return true;
    if (previous <= 0) return currentReviewCount == 0;
    return delta / previous < reviewCountChangeRatio;
  }

  Future<ReviewSummaryRecord?> _loadCachedSummary(String productId) {
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.reviewSummaries)
          .select(
            'id,product_id,total_reviews,positive_summary,negative_summary,pros,cons,ai_score,model,generated_at',
          )
          .eq('product_id', productId)
          .order('generated_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return ReviewSummaryRecord.fromJson(Map<String, dynamic>.from(rows.first as Map));
    });
  }

  /// Reviews for [productId] across all marketplace listings (newest first, capped).
  Future<List<ReviewRecord>> _loadReviews(String productId) {
    return _db.run((client) async {
      final listings = await client
          .from(DbTables.marketplaceProducts)
          .select('id')
          .eq('product_id', productId)
          .eq('is_active', true);
      final ids = [
        for (final row in listings)
          if (row['id'] is String) row['id'] as String,
      ];
      if (ids.isEmpty) return const [];

      final rows = await client
          .from(DbTables.reviews)
          .select(
            'id,marketplace_product_id,rating,title,content,sentiment,author_name,'
            'verified_purchase,review_date,created_at,updated_at',
          )
          .inFilter('marketplace_product_id', ids)
          .order('review_date', ascending: false)
          .limit(maxReviewsForAi);

      return rows.map((row) => ReviewRecord.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    });
  }
}

final aiReviewSummaryServiceProvider = Provider<AiReviewSummaryService>((ref) {
  if (AppConfig.useMockData) return const FallbackAiReviewSummaryService();
  return SupabaseAiReviewSummaryService(ref.watch(supabaseServiceProvider));
});
