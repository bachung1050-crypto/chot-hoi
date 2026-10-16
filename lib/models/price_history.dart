import 'dart:math' as math;

class PriceHistoryPoint {
  const PriceHistoryPoint({required this.date, required this.price});

  final DateTime date;
  final int price;
}

enum PriceTrend { down, flat, up }

/// Summary of a price series for the "Lịch sử giá" block.
class PriceHistoryStats {
  const PriceHistoryStats({
    required this.lowest,
    required this.highest,
    required this.average,
    required this.trend,
    required this.changePercent,
  });

  /// Returns null for an empty series.
  static PriceHistoryStats? fromPoints(List<PriceHistoryPoint> points) {
    if (points.isEmpty) return null;
    final prices = points.map((p) => p.price).toList();
    final first = prices.first;
    final last = prices.last;
    final change = first == 0 ? 0.0 : (last - first) / first * 100;
    return PriceHistoryStats(
      lowest: prices.reduce(math.min),
      highest: prices.reduce(math.max),
      average: prices.fold<int>(0, (sum, p) => sum + p) ~/ prices.length,
      changePercent: change,
      trend: change <= -_flatThreshold
          ? PriceTrend.down
          : change >= _flatThreshold
          ? PriceTrend.up
          : PriceTrend.flat,
    );
  }

  /// Moves smaller than this (in %) count as stable.
  static const double _flatThreshold = 1;

  final int lowest;
  final int highest;
  final int average;
  final PriceTrend trend;

  /// Last vs first point, in percent.
  final double changePercent;
}
