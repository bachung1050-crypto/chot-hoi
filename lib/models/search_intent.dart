import '../core/utils/text_normalizer.dart';
import 'db/json_read.dart';

/// Structured interpretation of a natural-language product search.
///
/// Produced by [AiSearchService] (Edge Function or local fallback), then consumed
/// by [ProductRepository] to query Supabase. Flutter never talks to OpenAI directly.
class SearchIntent {
  const SearchIntent({
    this.query = '',
    this.category,
    this.brands = const [],
    this.minPrice,
    this.maxPrice,
    this.minRam,
    this.useCase,
    this.keyword,
    this.features = const [],
    this.dealsOnly = false,
  });

  factory SearchIntent.fromJson(Map<String, dynamic> json, {String query = ''}) {
    final brands = json['brands'];
    final features = json['features'];
    return SearchIntent(
      query: query.isNotEmpty ? query : (json['query'] as String? ?? ''),
      category: json['category'] as String?,
      brands: brands is List ? brands.whereType<String>().toList() : const [],
      minPrice: JsonRead.toIntOrNull(json['minPrice'] ?? json['min_price']),
      maxPrice: JsonRead.toIntOrNull(json['maxPrice'] ?? json['max_price']),
      minRam: JsonRead.toIntOrNull(json['minRam'] ?? json['min_ram']),
      useCase: _normalizeUseCase(
        json['useCase'] as String? ?? json['use_case'] as String? ?? json['purpose'] as String?,
      ),
      keyword: json['keyword'] as String?,
      features: features is List ? features.whereType<String>().toList() : const [],
      dealsOnly: json['dealsOnly'] as bool? ?? json['deals_only'] as bool? ?? false,
    );
  }

  /// Original user text (kept for search history and keyword fallback).
  final String query;

  /// Human / AI category label, e.g. `laptop`, `điện thoại`.
  final String? category;

  final List<String> brands;

  /// VND amounts (integers in this app; JSON may send doubles).
  final int? minPrice;
  final int? maxPrice;

  /// Minimum RAM in GB when the query mentions it. Soft-matched in product text —
  /// there is no dedicated `ram` column in the current schema.
  final int? minRam;

  /// e.g. `code`, `gaming`, `office`, `design`.
  final String? useCase;

  /// Free-text leftover when structured filters are thin.
  final String? keyword;

  final List<String> features;

  /// Local-parser flag for deal-oriented queries ("sale", "giảm giá").
  final bool dealsOnly;

  /// UI category key (`phone`, `laptop`, …) derived from [category].
  String? get categoryId => SearchCategoryMap.toUiKey(category);

  /// Alias used by existing filter chips / [ProductFilter].
  String? get purpose => useCase;

  Map<String, dynamic> toJson() => {
    if (category != null) 'category': category,
    if (brands.isNotEmpty) 'brands': brands,
    if (minPrice != null) 'min_price': minPrice,
    if (maxPrice != null) 'max_price': maxPrice,
    if (minRam != null) 'min_ram': minRam,
    if (useCase != null) 'use_case': useCase,
    if (keyword != null && keyword!.isNotEmpty) 'keyword': keyword,
    if (features.isNotEmpty) 'features': features,
    if (dealsOnly) 'deals_only': true,
  };

  static String? _normalizeUseCase(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = TextNormalizer.normalize(raw);
    if (text.contains('code') || text.contains('coding') || text.contains('lap trinh') || text.contains('dev')) {
      return 'code';
    }
    if (text.contains('game') || text.contains('gaming')) return 'gaming';
    if (text.contains('van phong') || text.contains('office') || text.contains('hoc tap')) return 'office';
    if (text.contains('design') || text.contains('do hoa') || text.contains('edit')) return 'design';
    return raw.trim();
  }
}

/// Maps AI / Vietnamese category labels onto the app's UI category keys and DB slugs.
abstract final class SearchCategoryMap {
  static const Map<String, String> _uiKeyByAlias = {
    'laptop': 'laptop',
    'may tinh xach tay': 'laptop',
    'notebook': 'laptop',
    'macbook': 'laptop',
    'dien thoai': 'phone',
    'smartphone': 'phone',
    'phone': 'phone',
    'iphone': 'phone',
    'tai nghe': 'headphone',
    'headphone': 'headphone',
    'earbuds': 'headphone',
    'gia dung': 'home',
    'thoi trang': 'fashion',
    'chuot': 'mouse',
    'mouse': 'mouse',
    'ban phim': 'keyboard',
    'keyboard': 'keyboard',
    'man hinh': 'monitor',
    'monitor': 'monitor',
    'smartwatch': 'watch',
    'dong ho': 'watch',
    'phu kien': 'accessory',
  };

  static String? toUiKey(String? category) {
    if (category == null || category.trim().isEmpty) return null;
    final normalized = TextNormalizer.normalize(category);
    return _uiKeyByAlias[normalized] ??
        _uiKeyByAlias.entries.where((e) => normalized.contains(e.key)).firstOrNull?.value;
  }
}
