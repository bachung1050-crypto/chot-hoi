import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deal_cart_item.dart';
import '../../../models/marketplace.dart';
import '../../../models/product.dart';
import '../../../repositories/deal_cart_repository.dart';
import '../../../repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';

class DealCartNotifier extends AsyncNotifier<List<DealCartItem>> {
  DealCartRepository get _repository => ref.read(dealCartRepositoryProvider);

  List<DealCartItem> get _current => state.value ?? const [];

  /// Rebuilds on login/logout; signed-out users have an empty cart.
  @override
  Future<List<DealCartItem>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.watch(dealCartRepositoryProvider).getItems();
  }

  /// Adds [product] bought on [offer] (defaults to the cheapest marketplace).
  /// The same product may be added once per marketplace. Returns false when already in the cart.
  Future<bool> addToCart(Product product, {MarketplaceOffer? offer, int quantity = 1}) async {
    final chosen = offer ?? product.cheapestOffer;
    final exists = _current.any((i) => i.product.id == product.id && i.offer.marketplace.id == chosen.marketplace.id);
    if (exists) return false;
    final item = await _repository.addItem(product, chosen, quantity: quantity);
    state = AsyncData([..._current.where((i) => i.id != item.id), item]);
    return true;
  }

  Future<void> removeFromCart(String itemId) =>
      _optimistic(_current.where((i) => i.id != itemId).toList(), () => _repository.removeItem(itemId));

  Future<void> updateQuantity(String itemId, int quantity) {
    if (quantity < 1) return removeFromCart(itemId);
    return _optimistic([
      for (final item in _current) item.id == itemId ? item.copyWith(quantity: quantity) : item,
    ], () => _repository.updateQuantity(itemId, quantity));
  }

  Future<void> clear() => _optimistic(const [], _repository.clear);

  Future<void> refresh() async {
    state = await AsyncValue.guard(build);
  }

  Future<void> _optimistic(List<DealCartItem> next, Future<void> Function() request) async {
    final previous = _current;
    state = AsyncData(next);
    try {
      await request();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final dealCartProvider = AsyncNotifierProvider<DealCartNotifier, List<DealCartItem>>(DealCartNotifier.new);

final dealCartSummaryProvider = Provider<DealCartSummary>(
  (ref) => DealCartSummary.fromItems(ref.watch(dealCartProvider).value ?? const []),
);

final dealCartCountProvider = Provider<int>((ref) => ref.watch(dealCartProvider).value?.length ?? 0);
