import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/repository_providers.dart';

typedef ResultsQuery = ({String query, String? categoryId});

/// Products for the grid results screen (keyword search or category browse).
final searchResultsProvider = FutureProvider.family<List<Product>, ResultsQuery>((ref, args) async {
  final repository = ref.watch(productRepositoryProvider);
  final categoryId = args.categoryId;
  if (categoryId != null) {
    return repository.getProductsByCategory(categoryId);
  }
  final result = await repository.searchProducts(args.query);
  return result.products;
});
