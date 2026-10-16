import 'marketplace.dart';
import 'product.dart';

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.product,
    required this.targetPrice,
    this.enabled = true,
    this.offer,
    this.triggeredAt,
  });

  final String id;
  final Product product;
  final int targetPrice;
  final bool enabled;

  /// Marketplace being watched; null means the cheapest one.
  final MarketplaceOffer? offer;

  /// Set by the backend once the target was hit.
  final DateTime? triggeredAt;

  int get currentPrice => offer?.price ?? product.currentPrice;

  bool get isReached => currentPrice <= targetPrice;

  PriceAlert copyWith({bool? enabled, int? targetPrice}) {
    return PriceAlert(
      id: id,
      product: product,
      targetPrice: targetPrice ?? this.targetPrice,
      enabled: enabled ?? this.enabled,
      offer: offer,
      triggeredAt: triggeredAt,
    );
  }
}
