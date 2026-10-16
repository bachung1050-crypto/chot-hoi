import 'json_read.dart';

/// Row of `public.categories`. The UI uses [ProductCategory]; see `ProductMapper`.
class CategoryRecord {
  const CategoryRecord({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.level = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryRecord.fromJson(Map<String, dynamic> json) => CategoryRecord(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    parentId: json['parent_id'] as String?,
    level: JsonRead.toInt(json['level'], 1),
    isActive: json['is_active'] as bool? ?? true,
    createdAt: JsonRead.toDate(json['created_at']),
    updatedAt: JsonRead.toDate(json['updated_at']),
  );

  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final int level;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
