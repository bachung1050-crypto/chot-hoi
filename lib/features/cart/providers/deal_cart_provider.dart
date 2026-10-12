import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deal_cart_item.dart';
import '../../../models/marketplace.dart';
import '../../../models/product.dart';
import '../../../repositories/deal_cart_repository.dart';
import '../../../repositories/repository_providers.dart';

class DealCartNotifier extends AsyncNotifier<List<DealCartItem>> {
  DealCartRepository get _repository => ref.read(dealCartRepositoryProvider);

  List<DealCartItem> get _current => state.value ?? const [];

  @override
  Future<List<DealCartItem>> build() => _repository.getItems();

  /// Adds [product] using [offer] (defaults to the cheapest marketplace).
  /// Returns false when the product is already in the cart.
  Future<bool> addToCart(Product product, {MarketplaceOffer? offer}) async {
    if (_current.any((i) => i.product.id == product.id)) return false;
    final item = DealCartItem(id: 'cart-${product.id}', product: product, offer: offer ?? product.cheapestOffer);
    state = AsyncData([..._current, item]);
    await _repository.upsertItem(item);
    return true;
  }

  Future<void> removeFromCart(String itemId) async {
    state = AsyncData(_current.where((i) => i.id != itemId).toList());
    await _repository.removeItem(itemId);
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) return removeFromCart(itemId);
    final updated = [for (final item in _current) item.id == itemId ? item.copyWith(quantity: quantity) : item];
    state = AsyncData(updated);
    await _repository.upsertItem(updated.firstWhere((i) => i.id == itemId));
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await _repository.clear();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.getItems);
  }
}

final dealCartProvider = AsyncNotifierProvider<DealCartNotifier, List<DealCartItem>>(DealCartNotifier.new);

final dealCartSummaryProvider = Provider<DealCartSummary>(
  (ref) => DealCartSummary.fromItems(ref.watch(dealCartProvider).value ?? const []),
);

final dealCartCountProvider = Provider<int>((ref) => ref.watch(dealCartProvider).value?.length ?? 0);
