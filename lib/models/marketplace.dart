import '../core/utils/price_math.dart';
import 'price_history.dart';

enum MarketplaceCode {
  shopee('SHOPEE'),
  tiktokShop('TIKTOK_SHOP'),
  lazada('LAZADA'),
  tiki('TIKI');

  const MarketplaceCode(this.dbValue);

  /// Value of `marketplaces.code`.
  final String dbValue;

  static MarketplaceCode? fromDb(String? value) {
    for (final code in values) {
      if (code.dbValue == value) return code;
    }
    return null;
  }
}

class Marketplace {
  const Marketplace({required this.id, required this.code, required this.name, this.logoUrl});

  /// Row of `public.marketplaces`. Returns null for marketplaces the app does not support yet.
  static Marketplace? fromJson(Map<String, dynamic> json) {
    final code = MarketplaceCode.fromDb(json['code'] as String?);
    if (code == null) return null;
    return Marketplace(
      id: json['id'] as String,
      code: code,
      name: json['name'] as String? ?? code.dbValue,
      logoUrl: json['logo_url'] as String?,
    );
  }

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

/// One marketplace listing of a product. Optional fields are null when the source
/// (e.g. mock data) does not provide them, and the UI simply hides them.
class MarketplaceOffer {
  const MarketplaceOffer({
    required this.marketplace,
    required this.price,
    required this.productUrl,
    this.inStock = true,
    this.marketplaceProductId,
    this.originalPrice,
    this.sellerName,
    this.rating,
    this.reviewCount,
    this.stockStatus,
    this.priceHistory = const [],
  });

  final Marketplace marketplace;
  final int price;

  /// Affiliate link when available, otherwise the plain product page.
  final String productUrl;
  final bool inStock;
  final String? marketplaceProductId;
  final int? originalPrice;
  final String? sellerName;
  final double? rating;
  final int? reviewCount;

  /// Raw `stock_status`, e.g. `in_stock`.
  final String? stockStatus;

  /// Oldest first.
  final List<PriceHistoryPoint> priceHistory;

  int get discountPercent => PriceMath.discountPercent(originalPrice: originalPrice, currentPrice: price);
}
