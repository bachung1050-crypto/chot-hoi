enum MarketplaceCode { shopee, tiktokShop, lazada, tiki }

class Marketplace {
  const Marketplace({required this.id, required this.code, required this.name, this.logoUrl});

  final String id;
  final MarketplaceCode code;
  final String name;

  /// Remote logo. When null the UI renders a branded monogram.
  final String? logoUrl;

  @override
  bool operator ==(Object other) => other is Marketplace && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class MarketplaceOffer {
  const MarketplaceOffer({
    required this.marketplace,
    required this.price,
    required this.productUrl,
    this.inStock = true,
  });

  final Marketplace marketplace;
  final int price;
  final String productUrl;
  final bool inStock;
}
