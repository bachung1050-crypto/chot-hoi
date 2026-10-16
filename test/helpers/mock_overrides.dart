import 'package:chot_hoi/core/ai/ai_agent_service.dart';
import 'package:chot_hoi/core/ai/ai_recommendation_service.dart';
import 'package:chot_hoi/core/ai/ai_review_summary_service.dart';
import 'package:chot_hoi/core/ai/ai_search_service.dart';
import 'package:chot_hoi/repositories/mock/mock_auth_repository.dart';
import 'package:chot_hoi/repositories/mock/mock_product_repository.dart';
import 'package:chot_hoi/repositories/mock/mock_user_repositories.dart';
import 'package:chot_hoi/repositories/product_repository.dart';
import 'package:chot_hoi/repositories/repository_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Replaces every Supabase-backed repository with its in-memory mock.
List<Override> mockRepositoryOverrides({ProductRepository? products, bool signedIn = true}) {
  final auth = MockAuthRepository(signedIn: signedIn);
  String? userId() => auth.currentUserId;
  const aiSearch = FallbackAiSearchService();
  return [
    aiSearchServiceProvider.overrideWithValue(aiSearch),
    aiRecommendationServiceProvider.overrideWithValue(const FallbackAiRecommendationService()),
    aiReviewSummaryServiceProvider.overrideWithValue(const FallbackAiReviewSummaryService()),
    aiAgentServiceProvider.overrideWithValue(const FallbackAiAgentService()),
    productRepositoryProvider.overrideWithValue(products ?? MockProductRepository(aiSearch: aiSearch)),
    authRepositoryProvider.overrideWithValue(auth),
    savedProductsRepositoryProvider.overrideWithValue(MockSavedProductsRepository()),
    dealCartRepositoryProvider.overrideWithValue(MockDealCartRepository()),
    priceAlertRepositoryProvider.overrideWithValue(MockPriceAlertRepository()),
    profileRepositoryProvider.overrideWithValue(MockProfileRepository(userId)),
    searchHistoryRepositoryProvider.overrideWithValue(MockSearchHistoryRepository(userId)),
    notificationRepositoryProvider.overrideWithValue(MockNotificationRepository(userId)),
  ];
}
