import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/saved_products_repository.dart';
import '../../auth/providers/auth_providers.dart';

class SavedProductsNotifier extends AsyncNotifier<List<Product>> {
  SavedProductsRepository get _repository => ref.read(savedProductsRepositoryProvider);

  List<Product> get _current => state.value ?? const [];

  /// Rebuilds on login/logout; signed-out users have no saved products.
  @override
  Future<List<Product>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.watch(savedProductsRepositoryProvider).getSavedProducts();
  }

  bool isSaved(String productId) => _current.any((p) => p.id == productId);

  /// Optimistic: the UI updates at once and rolls back if the request fails.
  Future<void> addSavedProduct(Product product) async {
    if (isSaved(product.id)) return;
    final previous = _current;
    state = AsyncData([product, ...previous]);
    try {
      await _repository.saveProduct(product.id);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> removeSavedProduct(String productId) async {
    final previous = _current;
    state = AsyncData(previous.where((p) => p.id != productId).toList());
    try {
      await _repository.removeProduct(productId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Returns the new saved state.
  Future<bool> toggle(Product product) async {
    if (isSaved(product.id)) {
      await removeSavedProduct(product.id);
      return false;
    }
    await addSavedProduct(product);
    return true;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }
}

final savedProductsProvider = AsyncNotifierProvider<SavedProductsNotifier, List<Product>>(SavedProductsNotifier.new);

final isProductSavedProvider = Provider.family<bool, String>(
  (ref, productId) => ref.watch(savedProductsProvider).value?.any((p) => p.id == productId) ?? false,
);

final savedCountProvider = Provider<int>((ref) => ref.watch(savedProductsProvider).value?.length ?? 0);
