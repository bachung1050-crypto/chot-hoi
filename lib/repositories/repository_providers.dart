import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ai/ai_search_service.dart';
import '../core/config/app_config.dart';
import '../core/services/supabase_service.dart';
import 'auth_repository.dart';
import 'deal_cart_repository.dart';
import 'image_search_repository.dart';
import 'mock/mock_auth_repository.dart';
import 'mock/mock_image_search_repository.dart';
import 'mock/mock_product_repository.dart';
import 'mock/mock_user_repositories.dart';
import 'notification_repository.dart';
import 'price_alert_repository.dart';
import 'product_repository.dart';
import 'profile_repository.dart';
import 'saved_products_repository.dart';
import 'search_history_repository.dart';
import 'supabase/supabase_auth_repository.dart';
import 'supabase/supabase_deal_cart_repository.dart';
import 'supabase/supabase_notification_repository.dart';
import 'supabase/supabase_price_alert_repository.dart';
import 'supabase/supabase_product_repository.dart';
import 'supabase/supabase_profile_repository.dart';
import 'supabase/supabase_saved_products_repository.dart';
import 'supabase/supabase_search_history_repository.dart';

/// Single place to swap mock implementations for Supabase ones.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final aiSearch = ref.watch(aiSearchServiceProvider);
  if (AppConfig.useMockData) return MockProductRepository(aiSearch: aiSearch);
  return SupabaseProductRepository(
    ref.watch(supabaseServiceProvider),
    aiSearch: aiSearch,
    legacyFallback: MockProductRepository(aiSearch: aiSearch),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) return MockAuthRepository();
  return SupabaseAuthRepository(ref.watch(supabaseServiceProvider));
});

final savedProductsRepositoryProvider = Provider<SavedProductsRepository>((ref) {
  if (AppConfig.useMockData) return MockSavedProductsRepository();
  return SupabaseSavedProductsRepository(ref.watch(supabaseServiceProvider));
});

final dealCartRepositoryProvider = Provider<DealCartRepository>((ref) {
  if (AppConfig.useMockData) return MockDealCartRepository();
  return SupabaseDealCartRepository(ref.watch(supabaseServiceProvider));
});

final priceAlertRepositoryProvider = Provider<PriceAlertRepository>((ref) {
  if (AppConfig.useMockData) return MockPriceAlertRepository();
  return SupabasePriceAlertRepository(ref.watch(supabaseServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConfig.useMockData) return MockProfileRepository(() => ref.read(authRepositoryProvider).currentUserId);
  return SupabaseProfileRepository(ref.watch(supabaseServiceProvider));
});

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((ref) {
  if (AppConfig.useMockData) return MockSearchHistoryRepository(() => ref.read(authRepositoryProvider).currentUserId);
  return SupabaseSearchHistoryRepository(ref.watch(supabaseServiceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConfig.useMockData) return MockNotificationRepository(() => ref.read(authRepositoryProvider).currentUserId);
  return SupabaseNotificationRepository(ref.watch(supabaseServiceProvider));
});

final imageSearchRepositoryProvider = Provider<ImageSearchRepository>((ref) => MockImageSearchRepository());
