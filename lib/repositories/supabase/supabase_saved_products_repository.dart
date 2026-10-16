import '../../core/services/supabase_service.dart';
import '../../models/db/saved_product.dart';
import '../../models/product.dart';
import '../saved_products_repository.dart';
import 'product_mapper.dart';

/// `saved_products` of the signed-in user, joined with `products`.
class SupabaseSavedProductsRepository implements SavedProductsRepository {
  const SupabaseSavedProductsRepository(this._db);

  final SupabaseService _db;

  @override
  Future<List<Product>> getSavedProducts() {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.savedProducts)
          .select('id,user_id,product_id,created_at,${ProductMapper.productEmbed}')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(SavedProduct.fromJson)
          .map((saved) => saved.product)
          .nonNulls
          .map(ProductMapper.toProduct)
          .nonNulls
          .toList();
    });
  }

  @override
  Future<void> saveProduct(String productId) {
    final userId = _db.requireUserId();
    ProductMapper.requireDbProductId(productId);
    return _db.run((client) async {
      final existing = await client
          .from(DbTables.savedProducts)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      if (existing != null) return;
      await client.from(DbTables.savedProducts).insert({'user_id': userId, 'product_id': productId});
    });
  }

  @override
  Future<void> removeProduct(String productId) {
    final userId = _db.requireUserId();
    return _db.run(
      (client) => client.from(DbTables.savedProducts).delete().eq('user_id', userId).eq('product_id', productId),
    );
  }
}
