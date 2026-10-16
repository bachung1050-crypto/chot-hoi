import 'json_read.dart';

/// Row of `public.reviews` (FK: `marketplace_product_id` → `marketplace_products`).
class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.marketplaceProductId,
    required this.rating,
    this.title,
    this.content,
    this.sentiment,
    this.authorName,
    this.verifiedPurchase = false,
    this.reviewDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewRecord.fromJson(Map<String, dynamic> json) => ReviewRecord(
    id: json['id'] as String,
    marketplaceProductId: json['marketplace_product_id'] as String? ?? '',
    rating: JsonRead.toDouble(json['rating']),
    title: json['title'] as String?,
    content: json['content'] as String?,
    sentiment: json['sentiment'] as String?,
    authorName: json['author_name'] as String?,
    verifiedPurchase: json['verified_purchase'] as bool? ?? false,
    reviewDate: JsonRead.toDate(json['review_date']),
    createdAt: JsonRead.toDate(json['created_at']),
    updatedAt: JsonRead.toDate(json['updated_at']),
  );

  final String id;
  final String marketplaceProductId;
  final double rating;
  final String? title;
  final String? content;
  final String? sentiment;
  final String? authorName;
  final bool verifiedPurchase;
  final DateTime? reviewDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
