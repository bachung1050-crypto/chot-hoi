import 'json_read.dart';

/// Row of `public.price_history`. The chart uses [PriceHistoryPoint].
class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.id,
    required this.marketplaceProductId,
    required this.price,
    required this.recordedAt,
    this.originalPrice,
    this.source,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) => PriceHistoryEntry(
    id: json['id'] as String,
    marketplaceProductId: json['marketplace_product_id'] as String? ?? '',
    price: JsonRead.toInt(json['price']),
    originalPrice: JsonRead.toIntOrNull(json['original_price']),
    source: json['source'] as String?,
    recordedAt: JsonRead.toDate(json['recorded_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  final String id;
  final String marketplaceProductId;
  final int price;
  final int? originalPrice;

  /// e.g. `demo`, later `shopee_api`.
  final String? source;
  final DateTime recordedAt;
}
