import '../models/category.dart';
import '../models/product.dart';
import '../models/search_result.dart';

/// Product catalog contract. Phase 1 uses [MockProductRepository];
/// Phase 2 can provide a Supabase/REST implementation without touching the UI.
abstract interface class ProductRepository {
  Future<List<Product>> getProducts();

  Future<List<ProductCategory>> getCategories();

  Future<List<Product>> getTodayDeals();

  Future<List<Product>> getRecommendations();

  Future<Product?> getProductById(String id);

  Future<List<Product>> getProductsByCategory(String categoryId);

  /// Natural-language search, e.g. "laptop dưới 25 triệu để code, ưu tiên Lenovo".
  Future<SearchResult> searchProducts(String query);

  Future<List<String>> getAiSuggestions();
}

class SearchFailure implements Exception {
  const SearchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
