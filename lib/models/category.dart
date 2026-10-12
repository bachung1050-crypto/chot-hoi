class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    this.imageUrl,
    this.keywords = const [],
  });

  final String id;
  final String name;

  /// Resolved to an icon by `AppIcons.category`.
  final String iconKey;
  final String? imageUrl;

  /// Normalized (no diacritics) search keywords.
  final List<String> keywords;
}
