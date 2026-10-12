import 'product.dart';

class PriceAlert {
  const PriceAlert({required this.id, required this.product, required this.targetPrice, this.enabled = true});

  final String id;
  final Product product;
  final int targetPrice;
  final bool enabled;

  bool get isReached => product.currentPrice <= targetPrice;

  PriceAlert copyWith({bool? enabled}) {
    return PriceAlert(id: id, product: product, targetPrice: targetPrice, enabled: enabled ?? this.enabled);
  }
}
