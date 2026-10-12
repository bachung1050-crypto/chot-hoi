import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../repositories/repository_providers.dart';

final productsProvider = FutureProvider<List<Product>>((ref) => ref.watch(productRepositoryProvider).getProducts());

final categoriesProvider = FutureProvider<List<ProductCategory>>(
  (ref) => ref.watch(productRepositoryProvider).getCategories(),
);

final todayDealsProvider = FutureProvider<List<Product>>((ref) => ref.watch(productRepositoryProvider).getTodayDeals());

final recommendedProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).getRecommendations(),
);

/// Categories that currently have at least one good deal ("Đang đáng mua").
final worthBuyingCategoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  final dealCounts = <String, int>{};
  for (final p in products.where((p) => p.isGoodDeal)) {
    dealCounts[p.categoryId] = (dealCounts[p.categoryId] ?? 0) + 1;
  }
  return categories.where((c) => dealCounts.containsKey(c.id)).toList()
    ..sort((a, b) => dealCounts[b.id]!.compareTo(dealCounts[a.id]!));
});

/// Product shown on the detail screen, looked up by id.
final selectedProductProvider = FutureProvider.family<Product?, String>(
  (ref, id) => ref.watch(productRepositoryProvider).getProductById(id),
);
