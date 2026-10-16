import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_review_summary_service.dart';
import '../../../models/review_summary.dart';
import 'product_providers.dart';

/// Loads / generates AI review summary for the product detail screen.
/// Uses DB cache when valid; otherwise one Edge Function call.
final productReviewSummaryProvider = FutureProvider.family<ReviewSummary?, String>((ref, productId) async {
  final product = await ref.watch(selectedProductProvider(productId).future);
  if (product == null) return null;

  // Prefer already-embedded summary when mapper filled aiSummary/pros from cache.
  // Still go through service so stale cache regenerates when review count changes.
  return ref.watch(aiReviewSummaryServiceProvider).getOrGenerate(
    productId: product.id,
    productName: product.name,
    brand: product.brand,
  );
});
