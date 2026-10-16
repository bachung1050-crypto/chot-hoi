import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_agent_service.dart';
import '../../../core/ai/ai_recommendation_service.dart';
import '../../../core/ai/fallback_search_intent_parser.dart';
import '../../../core/ai/recommendation_scorer.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/ai_agent_response.dart';
import '../../../models/ai_score_explanation.dart';
import '../../../models/product.dart';
import '../../../models/product_filter.dart';
import '../../../models/product_recommendation.dart';
import '../../../models/search_result.dart';
import '../../../repositories/repository_providers.dart';
import 'search_history_provider.dart';

enum AiSearchStatus { idle, loading, success, empty, error }

class AiSearchState {
  const AiSearchState({
    this.query = '',
    this.status = AiSearchStatus.idle,
    this.completedSteps = 0,
    this.stepLabels,
    this.result,
    this.filter = const ProductFilter(),
    this.errorMessage,
    this.agentMessage,
    this.agentActions = const [],
    this.actionRequired,
  });

  final String query;
  final AiSearchStatus status;

  /// Number of finished steps in [stepLabels] / [AppStrings.searchSteps].
  final int completedSteps;

  /// When set (agent path), used instead of [AppStrings.searchSteps].
  final List<String>? stepLabels;
  final SearchResult? result;
  final ProductFilter filter;
  final String? errorMessage;

  /// Natural-language reply from `ai-agent` (not inventing prices).
  final String? agentMessage;
  final List<String> agentActions;
  final String? actionRequired;

  List<Product> get allProducts => result?.products ?? const [];

  List<Product> get visibleProducts => filter.apply(allProducts);

  ProductRecommendation? get bestRecommendation => result?.bestRecommendation;

  AiSearchState copyWith({
    AiSearchStatus? status,
    int? completedSteps,
    List<String>? stepLabels,
    SearchResult? result,
    ProductFilter? filter,
    String? errorMessage,
    String? agentMessage,
    List<String>? agentActions,
    String? actionRequired,
    bool clearAgent = false,
  }) {
    return AiSearchState(
      query: query,
      status: status ?? this.status,
      completedSteps: completedSteps ?? this.completedSteps,
      stepLabels: stepLabels ?? this.stepLabels,
      result: result ?? this.result,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
      agentMessage: clearAgent ? null : (agentMessage ?? this.agentMessage),
      agentActions: clearAgent ? const [] : (agentActions ?? this.agentActions),
      actionRequired: clearAgent ? null : (actionRequired ?? this.actionRequired),
    );
  }
}

class AiSearchController extends Notifier<AiSearchState> {
  static const Duration stepDuration = Duration(milliseconds: 380);

  int _requestId = 0;

  @override
  AiSearchState build() => const AiSearchState();

  Future<void> searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return reset();

    final requestId = ++_requestId;
    final agentService = ref.read(aiAgentServiceProvider);
    final useAgent = !AppConfig.useMockData && agentService is! FallbackAiAgentService;
    state = AiSearchState(
      query: trimmed,
      status: AiSearchStatus.loading,
      stepLabels: useAgent ? AppStrings.agentLoadingSteps : null,
    );

    if (useAgent) {
      final handled = await _runAgentPath(trimmed, requestId);
      if (handled || requestId != _requestId) return;
      // Agent soft-failed → classic search without a second loading animation.
      await _runClassicSearch(trimmed, requestId, animate: false);
      return;
    }

    await _runClassicSearch(trimmed, requestId);
  }

  /// Returns true when the agent path fully handled the request (success/empty/error UI).
  Future<bool> _runAgentPath(String trimmed, int requestId) async {
    final steps = AppStrings.agentLoadingSteps;
    final pending = AsyncValue.guard(() => ref.read(aiAgentServiceProvider).ask(trimmed));

    for (var step = 1; step < steps.length; step++) {
      await Future<void>.delayed(stepDuration);
      if (requestId != _requestId) return true;
      state = state.copyWith(completedSteps: step);
    }

    final outcome = await pending;
    if (requestId != _requestId) return true;

    if (outcome.hasError || outcome.value == null) {
      return false;
    }

    final agent = outcome.value!;
    if (agent.errorCode == 'EMPTY_MESSAGE') {
      state = state.copyWith(
        status: AiSearchStatus.error,
        completedSteps: steps.length,
        errorMessage: agent.message,
        agentMessage: agent.message,
        agentActions: agent.actions,
        actionRequired: agent.actionRequired,
      );
      return true;
    }

    // Soft OpenAI / tool / offline failures → classic catalog search (5.1–5.3B).
    final softFail = agent.errorCode == 'AI_UNAVAILABLE' ||
        agent.errorCode == 'TOOL_ERROR' ||
        agent.errorCode == 'AI_OFFLINE' ||
        agent.errorCode == 'AI_NOT_CONFIGURED';
    if (!agent.success && softFail) return false;

    final products = await _hydrateProducts(agent);
    if (requestId != _requestId) return true;

    final intent = FallbackSearchIntentParser.parse(trimmed);
    final doneLabels = agent.actions.isNotEmpty
        ? [for (final a in agent.actions) a.startsWith('✓') ? a : '✓ $a']
        : steps;

    final isAuthAction = agent.actionRequired != null ||
        agent.actions.any((a) {
          final lower = a.toLowerCase();
          return lower.contains('lưu') || lower.contains('cảnh báo');
        });

    // Search-like replies without catalog hits → classic product list (5.1).
    if (products.isEmpty && !isAuthAction) {
      return false;
    }

    if (products.isEmpty) {
      state = state.copyWith(
        status: agent.actionRequired != null || agent.message.isNotEmpty
            ? AiSearchStatus.success
            : AiSearchStatus.empty,
        completedSteps: doneLabels.length,
        stepLabels: doneLabels,
        result: SearchResult(intent: intent, products: const [], recommendations: const []),
        filter: ProductFilter(maxPrice: intent.maxPrice),
        agentMessage: agent.message.isNotEmpty ? agent.message : null,
        agentActions: agent.actions,
        actionRequired: agent.actionRequired,
      );
      unawaited(ref.read(searchHistoryProvider.notifier).record(
            SearchResult(intent: intent, products: const [], recommendations: const []),
          ));
      return true;
    }

    final recommendations = await _recommendWithAgentOverlay(intent, products, agent);
    if (requestId != _requestId) return true;

    final orderedIds = [for (final r in recommendations) r.productId];
    final byId = {for (final p in products) p.id: p};
    final ordered = [
      for (final id in orderedIds) ?byId[id],
      ...products.where((p) => !orderedIds.contains(p.id)),
    ];

    final result = SearchResult(intent: intent, products: ordered, recommendations: recommendations);
    state = state.copyWith(
      status: AiSearchStatus.success,
      completedSteps: doneLabels.length,
      stepLabels: doneLabels,
      result: result,
      filter: ProductFilter(maxPrice: intent.maxPrice),
      agentMessage: agent.message.isNotEmpty ? agent.message : null,
      agentActions: agent.actions,
      actionRequired: agent.actionRequired,
    );
    unawaited(ref.read(searchHistoryProvider.notifier).record(result));
    return true;
  }

  Future<void> _runClassicSearch(String trimmed, int requestId, {bool animate = true}) async {
    state = AiSearchState(
      query: trimmed,
      status: AiSearchStatus.loading,
      completedSteps: animate ? 0 : AppStrings.searchSteps.length,
    );

    final pending = AsyncValue.guard(() => ref.read(productRepositoryProvider).searchProducts(trimmed));

    if (animate) {
      for (var step = 1; step < AppStrings.searchSteps.length; step++) {
        await Future<void>.delayed(stepDuration);
        if (requestId != _requestId) return;
        state = state.copyWith(completedSteps: step);
      }
    }

    final outcome = await pending;
    if (requestId != _requestId) return;

    final raw = outcome.value;
    if (outcome.hasError || raw == null) {
      state = state.copyWith(
        status: AiSearchStatus.error,
        errorMessage: outcome.error?.toString() ?? 'Đã có lỗi xảy ra.',
      );
      return;
    }

    if (raw.products.isEmpty) {
      state = state.copyWith(
        status: AiSearchStatus.empty,
        completedSteps: AppStrings.searchSteps.length,
        result: raw,
        filter: ProductFilter(maxPrice: raw.intent.maxPrice),
      );
      unawaited(ref.read(searchHistoryProvider.notifier).record(raw));
      return;
    }

    final candidates = raw.products.take(RecommendationScorer.candidateLimit).toList();
    List<ProductRecommendation> recommendations;
    try {
      recommendations = await ref.read(aiRecommendationServiceProvider).recommend(raw.intent, candidates);
    } catch (_) {
      recommendations = RecommendationScorer.score(raw.intent, candidates);
    }

    final orderedIds = [for (final r in recommendations) r.productId];
    final byId = {for (final p in raw.products) p.id: p};
    final ordered = [
      for (final id in orderedIds) ?byId[id],
      ...raw.products.where((p) => !orderedIds.contains(p.id)),
    ];

    final result = SearchResult(intent: raw.intent, products: ordered, recommendations: recommendations);
    state = state.copyWith(
      status: AiSearchStatus.success,
      completedSteps: AppStrings.searchSteps.length,
      result: result,
      filter: ProductFilter(maxPrice: result.intent.maxPrice),
    );
    unawaited(ref.read(searchHistoryProvider.notifier).record(result));
  }

  Future<List<Product>> _hydrateProducts(AiAgentResponse agent) async {
    final repo = ref.read(productRepositoryProvider);
    final ids = agent.productIds;
    if (ids.isEmpty) return const [];

    final out = <Product>[];
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) continue;
      final product = await repo.getProductById(id);
      if (product != null) out.add(product);
    }
    return out;
  }

  Future<List<ProductRecommendation>> _recommendWithAgentOverlay(
    SearchIntent intent,
    List<Product> products,
    AiAgentResponse agent,
  ) async {
    List<ProductRecommendation> scored;
    try {
      scored = await ref.read(aiRecommendationServiceProvider).recommend(intent, products);
    } catch (_) {
      scored = RecommendationScorer.score(intent, products);
    }
    if (scored.isEmpty) return scored;

    final score = agent.score;
    final verdict = agent.verdict;
    final message = agent.message.trim();
    if (score == null && (verdict == null || verdict.isEmpty) && message.isEmpty) {
      return scored;
    }

    final best = scored.first;
    final explanation = AiScoreExplanation(
      summary: message.isNotEmpty ? message : best.reason,
      verdict: AiScoreExplanation.normalizeVerdict(verdict, score: score ?? best.score),
      reasons: best.pros,
      warnings: best.cons,
    );

    return [
      best.copyWith(
        score: score ?? best.score,
        reason: message.isNotEmpty ? message : best.reason,
        explanation: explanation,
      ),
      ...scored.skip(1),
    ];
  }

  Future<void> retry() => searchProducts(state.query);

  void reset() {
    _requestId++;
    state = const AiSearchState();
  }

  void toggleBudget() {
    final budget = state.result?.intent.maxPrice;
    if (budget == null) return;
    final active = state.filter.maxPrice != null;
    state = state.copyWith(filter: state.filter.copyWith(maxPrice: () => active ? null : budget));
  }

  void toggleBrand(String brand) {
    final brands = {...state.filter.brands};
    if (!brands.remove(brand)) brands.add(brand);
    state = state.copyWith(filter: state.filter.copyWith(brands: brands));
  }

  void togglePurpose(String purpose) {
    final active = state.filter.purpose == purpose;
    state = state.copyWith(filter: state.filter.copyWith(purpose: () => active ? null : purpose));
  }

  void setSort(ProductSort sort) {
    state = state.copyWith(filter: state.filter.copyWith(sort: sort));
  }

  void applyFilter(ProductFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

final aiSearchProvider = NotifierProvider<AiSearchController, AiSearchState>(AiSearchController.new);

final aiSuggestionsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(productRepositoryProvider).getAiSuggestions(),
);
