import 'json_read.dart';

/// Row of `public.brands`.
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    logoUrl: json['logo_url'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: JsonRead.toDate(json['created_at']),
    updatedAt: JsonRead.toDate(json['updated_at']),
  );

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
