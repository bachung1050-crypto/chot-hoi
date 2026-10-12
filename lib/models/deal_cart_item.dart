import 'dart:math' as math;

import 'marketplace.dart';
import 'product.dart';

class DealCartItem {
  const DealCartItem({required this.id, required this.product, required this.offer, this.quantity = 1});

  final String id;
  final Product product;
  final MarketplaceOffer offer;
  final int quantity;

  int get unitPrice => offer.price;

  int get subtotal => unitPrice * quantity;

  int get discountPercent {
    if (product.originalPrice <= unitPrice) return 0;
    return ((product.originalPrice - unitPrice) / product.originalPrice * 100).round();
  }

  /// Saved versus the original listed price.
  int get savedVsOriginal => math.max(0, product.originalPrice - unitPrice) * quantity;

  /// Saved by choosing this marketplace over the most expensive one.
  int get savedVsOtherMarketplaces => (product.highestOfferPrice - unitPrice) * quantity;

  DealCartItem copyWith({int? quantity}) {
    return DealCartItem(id: id, product: product, offer: offer, quantity: quantity ?? this.quantity);
  }
}

class DealCartSummary {
  const DealCartSummary({
    required this.itemCount,
    required this.total,
    required this.savedVsOriginal,
    required this.aiSaving,
  });

  factory DealCartSummary.fromItems(List<DealCartItem> items) {
    return DealCartSummary(
      itemCount: items.fold(0, (sum, i) => sum + i.quantity),
      total: items.fold(0, (sum, i) => sum + i.subtotal),
      savedVsOriginal: items.fold(0, (sum, i) => sum + i.savedVsOriginal),
      aiSaving: items.fold(0, (sum, i) => sum + i.savedVsOtherMarketplaces),
    );
  }

  final int itemCount;
  final int total;
  final int savedVsOriginal;
  final int aiSaving;
}
