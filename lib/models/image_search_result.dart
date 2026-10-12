import 'dart:math' as math;

import 'product.dart';

/// What Chốt Hời AI recognised from a photo plus the deal analysis around it.
class ImageSearchResult {
  const ImageSearchResult({
    required this.imageUrl,
    required this.request,
    required this.product,
    required this.accuracyPercent,
    required this.tags,
    required this.similarProducts,
    required this.reasons,
  });

  final String imageUrl;

  /// Free text + quick chips the user added, empty when skipped.
  final String request;
  final Product product;
  final int accuracyPercent;
  final List<String> tags;

  /// Other products that look alike, shown under "Xem thêm".
  final List<Product> similarProducts;
  final List<String> reasons;

  int get resultCount => product.offers.length + similarProducts.length;

  /// How much the current price beats the 90-day average, in percent.
  int get betterThanAveragePercent {
    final average = product.averagePrice(90);
    if (average <= 0) return 0;
    return math.max(0, ((average - product.currentPrice) * 100 / average).round());
  }

  int get lowestOfferPrice => product.cheapestOffer.price;

  int get highestOfferPrice => product.highestOfferPrice;
}
