import '../models/product.dart';

abstract interface class SavedProductsRepository {
  Future<List<Product>> getSavedProducts();

  Future<void> saveProduct(String productId);

  Future<void> removeProduct(String productId);
}
