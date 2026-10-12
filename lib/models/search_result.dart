import 'product.dart';

/// What Chốt Hời AI understood from a natural-language query.
class SearchIntent {
  const SearchIntent({
    required this.query,
    this.categoryId,
    this.maxPrice,
    this.brands = const [],
    this.purpose,
    this.dealsOnly = false,
  });

  final String query;
  final String? categoryId;
  final int? maxPrice;
  final List<String> brands;
  final String? purpose;
  final bool dealsOnly;
}

class SearchResult {
  const SearchResult({required this.intent, required this.products});

  final SearchIntent intent;
  final List<Product> products;
}
