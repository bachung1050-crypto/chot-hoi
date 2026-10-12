import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deal_cart_repository.dart';
import 'image_search_repository.dart';
import 'mock/mock_image_search_repository.dart';
import 'mock/mock_product_repository.dart';
import 'mock/mock_user_repositories.dart';
import 'product_repository.dart';
import 'saved_products_repository.dart';
import 'user_repository.dart';

/// Single place to swap mock implementations for API/Supabase ones in Phase 2.
final productRepositoryProvider = Provider<ProductRepository>((ref) => MockProductRepository());

final savedProductsRepositoryProvider = Provider<SavedProductsRepository>((ref) => MockSavedProductsRepository());

final dealCartRepositoryProvider = Provider<DealCartRepository>((ref) => MockDealCartRepository());

final userRepositoryProvider = Provider<UserRepository>((ref) => MockUserRepository());

final imageSearchRepositoryProvider = Provider<ImageSearchRepository>((ref) => MockImageSearchRepository());
