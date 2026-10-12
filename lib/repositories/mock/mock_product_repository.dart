import '../../core/config/app_config.dart';
import '../../core/utils/search_query_parser.dart';
import '../../core/utils/text_normalizer.dart';
import '../../mock/mock_data.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/search_result.dart';
import '../product_repository.dart';

class MockProductRepository implements ProductRepository {
  MockProductRepository({this.latency = AppConfig.mockLatency});

  final Duration latency;

  List<Product> get _products => MockProducts.all;

  Future<T> _delay<T>(T value) => Future<T>.delayed(latency, () => value);

  @override
  Future<List<Product>> getProducts() => _delay(_products);

  @override
  Future<List<ProductCategory>> getCategories() => _delay(MockCategories.all);

  @override
  Future<List<Product>> getTodayDeals() {
    const featured = ['iphone-16-256', 'airpods-pro-2', 'macbook-air-m3'];
    final deals = [
      for (final id in featured) _products.firstWhere((p) => p.id == id),
      ..._products.where((p) => p.isGoodDeal && !featured.contains(p.id)).take(5),
    ];
    return _delay(deals);
  }

  @override
  Future<List<Product>> getRecommendations() {
    final sorted = [..._products]..sort((a, b) => b.chotHoiScore.compareTo(a.chotHoiScore));
    return _delay(sorted.take(6).toList());
  }

  @override
  Future<Product?> getProductById(String id) {
    final matches = _products.where((p) => p.id == id);
    return _delay(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) =>
      _delay(_products.where((p) => p.categoryId == categoryId).toList());

  @override
  Future<List<String>> getAiSuggestions() => _delay(MockData.aiSuggestions);

  @override
  Future<SearchResult> searchProducts(String query) async {
    await Future<void>.delayed(latency);

    final normalized = TextNormalizer.normalize(query);
    if (RegExp(r'\b(loi|error)\b').hasMatch(normalized)) {
      throw const SearchFailure('Không thể kết nối tới máy chủ tìm kiếm. Vui lòng thử lại.');
    }

    final intent = SearchQueryParser.parse(
      query,
      categories: MockCategories.all,
      brands: _products.map((p) => p.brand).toSet(),
    );

    final products = _match(intent, normalized)..sort((a, b) => _rank(a, b, intent));
    return SearchResult(intent: intent, products: products);
  }

  List<Product> _match(SearchIntent intent, String normalizedQuery) {
    final categoryId = intent.categoryId;
    if (categoryId != null) {
      return _products.where((p) => p.categoryId == categoryId).toList();
    }
    if (intent.brands.isNotEmpty) {
      return _products.where((p) => intent.brands.contains(p.brand)).toList();
    }
    if (intent.dealsOnly) {
      return _products.where((p) => p.isGoodDeal).toList();
    }

    final tokens = normalizedQuery.split(RegExp(r'\s+')).where((t) => t.length > 1).toList();
    if (tokens.isEmpty) return [..._products];
    return _products.where((p) {
      final haystack = TextNormalizer.normalize('${p.name} ${p.brand} ${MockCategories.byId(p.categoryId).name}');
      return tokens.every(haystack.contains);
    }).toList();
  }

  /// Preferred brands first, then within budget, then by Chốt Hời score.
  int _rank(Product a, Product b, SearchIntent intent) {
    int brandRank(Product p) => intent.brands.isEmpty || intent.brands.contains(p.brand) ? 0 : 1;
    int budgetRank(Product p) {
      final max = intent.maxPrice;
      return max == null || p.currentPrice <= max ? 0 : 1;
    }

    final byBudget = budgetRank(a).compareTo(budgetRank(b));
    if (byBudget != 0) return byBudget;
    final byBrand = brandRank(a).compareTo(brandRank(b));
    if (byBrand != 0) return byBrand;
    return b.chotHoiScore.compareTo(a.chotHoiScore);
  }
}
