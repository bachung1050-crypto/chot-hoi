import 'product.dart';
import 'product_recommendation.dart';
import 'search_intent.dart';

export 'search_intent.dart';

class SearchResult {
  const SearchResult({required this.intent, required this.products, this.recommendations = const []});

  final SearchIntent intent;
  final List<Product> products;

  /// Fit ranking for [products] (same order when recommended sort is active).
  final List<ProductRecommendation> recommendations;

  ProductRecommendation? get bestRecommendation =>
      recommendations.where((r) => r.isBestChoice).firstOrNull ?? recommendations.firstOrNull;

  ProductRecommendation? recommendationFor(String productId) =>
      recommendations.where((r) => r.productId == productId).firstOrNull;
}
