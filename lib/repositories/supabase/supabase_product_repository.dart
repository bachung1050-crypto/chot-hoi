import 'package:flutter/foundation.dart';

import '../../core/ai/ai_search_service.dart';
import '../../core/ai/fallback_search_intent_parser.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/text_normalizer.dart';
import '../../mock/mock_data.dart';
import '../../models/category.dart';
import '../../models/db/category_record.dart';
import '../../models/db/product_record.dart';
import '../../models/product.dart';
import '../../models/search_result.dart';
import '../product_repository.dart';
import 'product_mapper.dart';

/// [ProductRepository] backed by `products` + `brands` + `categories`
/// + `marketplace_products` (+ `marketplaces`, `marketplace_product_images`).
class SupabaseProductRepository implements ProductRepository {
  /// [legacyFallback] resolves old mock ids (e.g. `iphone-16-256`) still referenced by the
  /// mock Saved / Deal Cart / Price Alert repositories until those move to Supabase.
  /// [aiSearch] parses natural language via Edge Function (or local fallback).
  SupabaseProductRepository(this._db, {AiSearchService? aiSearch, ProductRepository? legacyFallback})
    : _aiSearch = aiSearch ?? const FallbackAiSearchService(),
      _legacy = legacyFallback;

  final SupabaseService _db;
  final AiSearchService _aiSearch;
  final ProductRepository? _legacy;

  static const int _todayDealsLimit = 8;
  static const int _recommendationsLimit = 6;

  /// Light listing embed for home / category feeds (no history / reviews payload).
  static const String _listings = 'marketplace_products(*,marketplaces(*),marketplace_product_images(*))';

  /// Single-request scoring embed (verified FKs):
  /// - `price_history.marketplace_product_id` → `marketplace_products`
  /// - `reviews.marketplace_product_id` → `marketplace_products`
  /// - `review_summaries.product_id` → `products`
  static const String _listingsEnriched =
      'marketplace_products(*,marketplaces(*),marketplace_product_images(*),'
      'price_history(id,marketplace_product_id,price,original_price,source,recorded_at),'
      'reviews(id,marketplace_product_id,rating,title,content,sentiment,author_name,'
      'verified_purchase,review_date,created_at,updated_at))';

  static const String _reviewSummariesEmbed =
      'review_summaries(id,product_id,pros,cons,ai_score,model,total_reviews,generated_at,'
      'positive_summary,negative_summary)';

  /// Detail + Search scoring: listings with history/reviews + product-level summaries.
  static const String _detailSelect =
      '*,brands(*),categories(*),$_reviewSummariesEmbed,$_listingsEnriched';

  /// `!inner` turns an embed into a filter so rows without a match are dropped.
  static String _select({bool filterBrand = false, bool filterCategory = false, bool enrichScoringData = false}) {
    final listings = enrichScoringData ? _listingsEnriched : _listings;
    final summaries = enrichScoringData ? '$_reviewSummariesEmbed,' : '';
    return '*,brands${filterBrand ? '!inner' : ''}(*),categories${filterCategory ? '!inner' : ''}(*),'
        '$summaries$listings';
  }

  static List<Product> _toProducts(List<Map<String, dynamic>> rows) =>
      rows.map(ProductRecord.fromJson).map(ProductMapper.toProduct).nonNulls.toList();

  Future<List<Product>> _query({
    String? categorySlug,
    List<String> brandNames = const [],
    List<String> tokens = const [],
    bool enrichScoringData = false,
  }) {
    return _db.run((client) async {
      var query = client
          .from(DbTables.products)
          .select(
            _select(
              filterBrand: brandNames.isNotEmpty,
              filterCategory: categorySlug != null,
              enrichScoringData: enrichScoringData,
            ),
          )
          .eq('is_active', true);
      if (categorySlug != null) query = query.eq('categories.slug', categorySlug);
      if (brandNames.isNotEmpty) query = query.inFilter('brands.name', brandNames);
      if (tokens.isNotEmpty) {
        query = query.or([for (final t in tokens) 'name.ilike.*$t*,description.ilike.*$t*'].join(','));
      }
      return _toProducts(await query.order('name'));
    });
  }

  /// Search prefers enriched rows; on embed/RLS failure still returns products without extras.
  Future<List<Product>> _queryForSearch({
    String? categorySlug,
    List<String> brandNames = const [],
    List<String> tokens = const [],
  }) async {
    try {
      return await _query(
        categorySlug: categorySlug,
        brandNames: brandNames,
        tokens: tokens,
        enrichScoringData: true,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseProductRepository] scoring enrich failed; '
          'falling back to listings-only. cause=${error.runtimeType}',
        );
        debugPrint('$stack');
      }
      return _query(categorySlug: categorySlug, brandNames: brandNames, tokens: tokens);
    }
  }

  @override
  Future<List<Product>> getProducts() => _query();

  @override
  Future<List<ProductCategory>> getCategories() {
    return _db.run((client) async {
      final rows = await client.from(DbTables.categories).select().eq('is_active', true).isFilter('parent_id', null);
      return rows.map(CategoryRecord.fromJson).map(ProductMapper.toCategory).toList()
        ..sort((a, b) => ProductMapper.categoryOrder(a).compareTo(ProductMapper.categoryOrder(b)));
    });
  }

  @override
  Future<List<Product>> getTodayDeals() async {
    final products = await getProducts();
    final deals = products.where((p) => p.isGoodDeal).toList();
    final pool = deals.isEmpty ? products : deals;
    pool.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return pool.take(_todayDealsLimit).toList();
  }

  @override
  Future<List<Product>> getRecommendations() async {
    final products = await getProducts();
    products.sort((a, b) => b.chotHoiScore.compareTo(a.chotHoiScore));
    return products.take(_recommendationsLimit).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    if (!ProductMapper.isDbId(id)) return _legacy?.getProductById(id);
    return _db.run((client) async {
      final row = await client.from(DbTables.products).select(_detailSelect).eq('id', id).maybeSingle();
      return row == null ? null : ProductMapper.toProduct(ProductRecord.fromJson(row));
    });
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) =>
      _query(categorySlug: ProductMapper.categorySlug(categoryId));

  @override
  Future<List<String>> getAiSuggestions() async => MockData.aiSuggestions;

  /// Flow: query → [AiSearchService] (Edge Function / fallback) → filters on Supabase.
  @override
  Future<SearchResult> searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResult(
        intent: SearchIntent(query: '', keyword: ''),
        products: [],
      );
    }

    try {
      final intent = await _aiSearch.parseSearchIntent(trimmed);
      final products = await _search(intent)
        ..sort((a, b) => _rank(a, b, intent));
      return SearchResult(intent: intent, products: products);
    } catch (error) {
      // Edge Function missing, AI service misconfigured, or network/RLS: local parser + DB.
      if (error is SearchFailure) rethrow;
      try {
        final intent = FallbackSearchIntentParser.parse(trimmed);
        final products = await _search(intent)
          ..sort((a, b) => _rank(a, b, intent));
        return SearchResult(intent: intent, products: products);
      } on DataFailure catch (inner) {
        throw SearchFailure(inner.message);
      }
    }
  }

  /// Applies structured filters supported by the current schema.
  ///
  /// - category → `categories.slug` (via UI key mapping)
  /// - brands → `brands.name`
  /// - maxPrice / minPrice → cheapest `marketplace_products.current_price` (client-side;
  ///   PostgREST cannot easily OR across listing embeds for "any listing ≤ X")
  /// - keyword / leftover tokens → `products.name|description` ilike
  /// - minRam / features / useCase → soft-match on name+description (no dedicated columns)
  Future<List<Product>> _search(SearchIntent intent) async {
    final categoryId = intent.categoryId;
    final categorySlug = categoryId == null ? null : ProductMapper.categorySlug(categoryId);
    final brands = intent.brands;

    final keywordSource = intent.keyword?.trim().isNotEmpty == true
        ? intent.keyword!
        : (categorySlug == null && brands.isEmpty ? intent.query : '');
    final tokens = _tokens(keywordSource);

    var products = await _queryForSearch(categorySlug: categorySlug, brandNames: brands, tokens: tokens);

    // When category+brand both set, `_query` ANDs them. If empty, relax brand filter.
    if (products.isEmpty && categorySlug != null && brands.isNotEmpty) {
      products = await _queryForSearch(categorySlug: categorySlug, tokens: tokens);
    }

    if (intent.maxPrice != null) {
      products = products.where((p) => p.currentPrice <= intent.maxPrice!).toList();
    }
    if (intent.minPrice != null) {
      products = products.where((p) => p.currentPrice >= intent.minPrice!).toList();
    }

    // No `ram` / `use_case` columns — soft filter only when it still leaves results.
    if (intent.minRam != null) {
      final withRam = products.where((p) => _mentionsRam(p, intent.minRam!)).toList();
      if (withRam.isNotEmpty) products = withRam;
    }
    if (intent.useCase != null) {
      final withUse = products.where((p) => _mentionsUseCase(p, intent.useCase!)).toList();
      if (withUse.isNotEmpty) products = withUse;
    }

    if (intent.dealsOnly) {
      products = products.where((p) => p.isGoodDeal).toList();
    }

    if (tokens.isNotEmpty && categorySlug == null && brands.isEmpty) {
      final normalizedTokens = tokens.map(TextNormalizer.normalize).toList();
      int hits(Product p) {
        final haystack = TextNormalizer.normalize('${p.name} ${p.brand} ${p.description}');
        return normalizedTokens.where(haystack.contains).length;
      }

      final best = products.fold<int>(0, (max, p) => hits(p) > max ? hits(p) : max);
      if (best > 0) products = products.where((p) => hits(p) == best).toList();
    }

    return products;
  }

  static bool _mentionsRam(Product p, int minRam) {
    final ramGb = p.ramGb;
    if (ramGb != null) return ramGb >= minRam;
    // No structured RAM — keep product in results; scorer will flag missing data.
    return true;
  }

  static bool _mentionsUseCase(Product p, String useCase) {
    final text = TextNormalizer.normalize('${p.name} ${p.description} ${p.tagline} ${p.specsSummary}');
    return switch (useCase) {
      'code' =>
        text.contains('code') ||
            text.contains('lap trinh') ||
            text.contains('office') ||
            text.contains('ryzen') ||
            text.contains('intel'),
      'gaming' =>
        text.contains('gaming') ||
            text.contains('game') ||
            text.contains('rtx') ||
            text.contains('tuf') ||
            text.contains('loq'),
      'office' => text.contains('office') || text.contains('van phong') || text.contains('ultrabook'),
      'design' => text.contains('design') || text.contains('do hoa') || text.contains('studio'),
      _ => text.contains(TextNormalizer.normalize(useCase)),
    };
  }

  /// Letters/digits only so tokens are safe inside a PostgREST `or=(...)` filter.
  static List<String> _tokens(String query) => query
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), ''))
      .where((t) => t.length > 1)
      .toList();

  /// Within budget first, then preferred brands, then Chốt Hời score.
  static int _rank(Product a, Product b, SearchIntent intent) {
    int budgetRank(Product p) {
      final max = intent.maxPrice;
      return max == null || p.currentPrice <= max ? 0 : 1;
    }

    int brandRank(Product p) => intent.brands.isEmpty || intent.brands.contains(p.brand) ? 0 : 1;

    final byBudget = budgetRank(a).compareTo(budgetRank(b));
    if (byBudget != 0) return byBudget;
    final byBrand = brandRank(a).compareTo(brandRank(b));
    if (byBrand != 0) return byBrand;
    return b.chotHoiScore.compareTo(a.chotHoiScore);
  }
}
