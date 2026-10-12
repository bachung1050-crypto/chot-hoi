import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../models/product.dart';
import '../../../models/product_filter.dart';
import '../../../models/search_result.dart';
import '../../../repositories/repository_providers.dart';

enum AiSearchStatus { idle, loading, success, empty, error }

class AiSearchState {
  const AiSearchState({
    this.query = '',
    this.status = AiSearchStatus.idle,
    this.completedSteps = 0,
    this.result,
    this.filter = const ProductFilter(),
    this.errorMessage,
  });

  final String query;
  final AiSearchStatus status;

  /// Number of finished steps in [AppStrings.searchSteps].
  final int completedSteps;
  final SearchResult? result;
  final ProductFilter filter;
  final String? errorMessage;

  List<Product> get allProducts => result?.products ?? const [];

  List<Product> get visibleProducts => filter.apply(allProducts);

  AiSearchState copyWith({
    AiSearchStatus? status,
    int? completedSteps,
    SearchResult? result,
    ProductFilter? filter,
    String? errorMessage,
  }) {
    return AiSearchState(
      query: query,
      status: status ?? this.status,
      completedSteps: completedSteps ?? this.completedSteps,
      result: result ?? this.result,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
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
    state = AiSearchState(query: trimmed, status: AiSearchStatus.loading);

    final pending = AsyncValue.guard(() => ref.read(productRepositoryProvider).searchProducts(trimmed));

    for (var step = 1; step < AppStrings.searchSteps.length; step++) {
      await Future<void>.delayed(stepDuration);
      if (requestId != _requestId) return;
      state = state.copyWith(completedSteps: step);
    }

    final outcome = await pending;
    if (requestId != _requestId) return;

    final result = outcome.value;
    if (outcome.hasError || result == null) {
      state = state.copyWith(
        status: AiSearchStatus.error,
        errorMessage: outcome.error?.toString() ?? 'Đã có lỗi xảy ra.',
      );
      return;
    }

    state = state.copyWith(
      status: result.products.isEmpty ? AiSearchStatus.empty : AiSearchStatus.success,
      completedSteps: AppStrings.searchSteps.length,
      result: result,
      filter: ProductFilter(maxPrice: result.intent.maxPrice),
    );
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
