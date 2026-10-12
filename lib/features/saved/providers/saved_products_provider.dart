import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/saved_products_repository.dart';

class SavedProductsNotifier extends AsyncNotifier<List<Product>> {
  SavedProductsRepository get _repository => ref.read(savedProductsRepositoryProvider);

  List<Product> get _current => state.value ?? const [];

  @override
  Future<List<Product>> build() => _repository.getSavedProducts();

  bool isSaved(String productId) => _current.any((p) => p.id == productId);

  Future<void> addSavedProduct(Product product) async {
    if (isSaved(product.id)) return;
    state = AsyncData([product, ..._current]);
    await _repository.saveProduct(product.id);
  }

  Future<void> removeSavedProduct(String productId) async {
    state = AsyncData(_current.where((p) => p.id != productId).toList());
    await _repository.removeProduct(productId);
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
    state = await AsyncValue.guard(_repository.getSavedProducts);
  }
}

final savedProductsProvider = AsyncNotifierProvider<SavedProductsNotifier, List<Product>>(SavedProductsNotifier.new);

final isProductSavedProvider = Provider.family<bool, String>(
  (ref, productId) => ref.watch(savedProductsProvider).value?.any((p) => p.id == productId) ?? false,
);

final savedCountProvider = Provider<int>((ref) => ref.watch(savedProductsProvider).value?.length ?? 0);
