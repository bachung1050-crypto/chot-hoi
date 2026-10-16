abstract final class PriceMath {
  /// `(original - current) / original * 100`, rounded; 0 when there is no real discount.
  static int discountPercent({required int? originalPrice, required int currentPrice}) {
    final original = originalPrice ?? 0;
    if (original <= 0 || original <= currentPrice) return 0;
    return ((original - currentPrice) / original * 100).round();
  }
}
