import 'dart:math' as math;

import '../core/utils/product_specs.dart';
import 'deal_verdict.dart';
import 'marketplace.dart';
import 'price_history.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.tagline,
    required this.brand,
    required this.categoryId,
    required this.imageUrl,
    required this.galleryUrls,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.currentPrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.chotHoiScore,
    required this.isGoodDeal,
    required this.inStock,
    required this.marketplace,
    required this.marketplaceProductId,
    required this.productUrl,
    required this.affiliateUrl,
    required this.specsSummary,
    required this.badges,
    required this.useCases,
    required this.aiSummary,
    required this.aiHighlights,
    required this.pros,
    required this.cons,
    required this.offers,
    required this.priceHistory,
    this.reviewAiScore,
    this.specs = const {},
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String tagline;
  final String brand;
  final String categoryId;
  final String imageUrl;
  final List<String> galleryUrls;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final int currentPrice;
  final int originalPrice;
  final int discountPercent;

  /// 0-100 score produced by Chốt Hời AI.
  final int chotHoiScore;
  final bool isGoodDeal;
  final bool inStock;

  /// Marketplace currently offering [currentPrice] (the cheapest one).
  final Marketplace marketplace;
  final String marketplaceProductId;
  final String productUrl;
  final String affiliateUrl;

  /// Short one-line spec, e.g. "Ryzen 7 7735HS | 16GB | 512GB".
  final String specsSummary;
  final List<String> badges;

  /// Purpose tags such as `code`, `gaming`, `office`.
  final List<String> useCases;

  /// Raw `products.specs` JSONB (empty when absent).
  final Map<String, dynamic> specs;
  final String aiSummary;
  final List<String> aiHighlights;
  final List<String> pros;
  final List<String> cons;
  final List<MarketplaceOffer> offers;

  /// Daily prices, oldest first.
  final List<PriceHistoryPoint> priceHistory;

  /// Optional `review_summaries.ai_score` (null when no summary row).
  final int? reviewAiScore;

  /// Parsed RAM GB from [specs] only (`specs.ram`). Null = missing data.
  int? get ramGb => ProductSpecs.ramGb(specs);

  DealVerdict get verdict => DealVerdict.fromScore(chotHoiScore);

  /// Score on a 10-point scale, e.g. 89 -> "8.9".
  String get scoreOutOfTen => (chotHoiScore / 10).toStringAsFixed(1);

  int get saving => math.max(0, originalPrice - currentPrice);

  List<MarketplaceOffer> get sortedOffers => [...offers]..sort((a, b) => a.price.compareTo(b.price));

  MarketplaceOffer get cheapestOffer => sortedOffers.first;

  int get highestOfferPrice => offers.map((o) => o.price).reduce(math.max);

  /// How much cheaper the best marketplace is versus the most expensive one.
  int get marketplaceGap => highestOfferPrice - cheapestOffer.price;

  List<PriceHistoryPoint> historyForDays(int days) {
    if (priceHistory.length <= days) return priceHistory;
    return priceHistory.sublist(priceHistory.length - days);
  }

  int lowestPrice(int days) => historyForDays(days).map((p) => p.price).reduce(math.min);

  int averagePrice(int days) {
    final points = historyForDays(days);
    return points.fold<int>(0, (sum, p) => sum + p.price) ~/ points.length;
  }
}
