import 'dart:math' as math;

import '../../core/services/supabase_service.dart';
import '../../core/utils/price_math.dart';
import '../../core/utils/product_specs.dart';
import '../../mock/mock_categories.dart';
import '../../models/category.dart';
import '../../models/db/category_record.dart';
import '../../models/db/marketplace_product.dart';
import '../../models/db/product_record.dart';
import '../../models/db/review_record.dart';
import '../../models/db/review_summary_record.dart';
import '../../models/marketplace.dart';
import '../../models/price_history.dart';
import '../../models/product.dart';

/// Converts Supabase rows into the UI models the existing screens already render.
abstract final class ProductMapper {
  /// PostgREST embed of a product with everything [toProduct] needs.
  static const String productEmbed =
      'products(*,brands(*),categories(*),marketplace_products(*,marketplaces(*),marketplace_product_images(*)))';

  /// `categories.slug` -> UI category key used by icons, tints and routes.
  static const Map<String, String> _categoryKeyBySlug = {
    'dien-thoai': 'phone',
    'laptop': 'laptop',
    'tai-nghe': 'headphone',
    'gia-dung': 'home',
    'thoi-trang': 'fashion',
    'chuot-may-tinh': 'mouse',
    'ban-phim': 'keyboard',
    'man-hinh': 'monitor',
    'smartwatch': 'watch',
    'phu-kien': 'accessory',
  };

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Database ids are uuids; mock/demo products use readable slugs.
  static bool isDbId(String id) => _uuid.hasMatch(id);

  /// Demo products (e.g. from image search) cannot be stored in user tables.
  static void requireDbProductId(String productId) {
    if (!isDbId(productId)) throw const DataFailure('Sản phẩm demo chưa có trong cơ sở dữ liệu nên chưa thể lưu.');
  }

  static String categoryKey(String slug) => _categoryKeyBySlug[slug] ?? slug;

  static String categorySlug(String categoryKey) {
    for (final entry in _categoryKeyBySlug.entries) {
      if (entry.value == categoryKey) return entry.key;
    }
    return categoryKey;
  }

  /// Known categories keep their curated Vietnamese label, icon and search keywords.
  static ProductCategory toCategory(CategoryRecord record) {
    final key = categoryKey(record.slug);
    final known = MockCategories.all.where((c) => c.id == key).firstOrNull;
    if (known != null) return known;
    return ProductCategory(id: key, name: record.name, iconKey: key, keywords: [record.slug.replaceAll('-', ' ')]);
  }

  /// Display order of the UI categories; unknown ones go last.
  static int categoryOrder(ProductCategory category) {
    final index = MockCategories.all.indexWhere((c) => c.id == category.id);
    return index == -1 ? MockCategories.all.length : index;
  }

  /// Returns null when the product has no active listing on a supported marketplace,
  /// because every product screen needs at least one price offer.
  static Product? toProduct(ProductRecord record) {
    final listings = record.marketplaceProducts.where((m) => m.isActive && m.marketplace != null).toList()
      ..sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
    if (listings.isEmpty) return null;

    final cheapest = listings.first;
    final currentPrice = cheapest.currentPrice;
    final originalPrice = math.max(currentPrice, cheapest.originalPrice ?? currentPrice);
    final discountPercent = PriceMath.discountPercent(originalPrice: originalPrice, currentPrice: currentPrice);
    final gallery = _gallery(listings, preferred: cheapest);
    final offers = listings.map(_toOffer).toList();
    final summary = record.reviewSummaries.firstOrNull;
    final rating = _resolveRating(record, cheapest, summary);
    final reviewCount = _resolveReviewCount(record, cheapest, summary);
    final score = _interimScore(discountPercent: discountPercent, rating: rating);

    return Product(
      id: record.id,
      name: record.name,
      slug: record.slug,
      description: record.description ?? '',
      tagline: '',
      brand: record.brand?.name ?? '',
      categoryId: categoryKey(record.category?.slug ?? ''),
      imageUrl: gallery.firstOrNull ?? '',
      galleryUrls: gallery,
      rating: rating,
      reviewCount: reviewCount,
      soldCount: 0,
      currentPrice: currentPrice,
      originalPrice: originalPrice,
      discountPercent: discountPercent,
      chotHoiScore: score,
      isGoodDeal: score >= 80,
      inStock: listings.any((m) => m.inStock),
      marketplace: cheapest.marketplace!,
      marketplaceProductId: cheapest.id,
      productUrl: cheapest.productUrl,
      affiliateUrl: cheapest.buyUrl,
      specsSummary: ProductSpecs.summary(record.specs),
      badges: const [],
      useCases: ProductSpecs.useCases(record.specs),
      specs: record.specs,
      aiSummary: summary?.positiveSummary?.trim() ?? '',
      aiHighlights: summary == null
          ? const []
          : summary.toReviewSummary(fromCache: true).highlights,
      pros: summary?.pros ?? const [],
      cons: summary?.cons ?? const [],
      offers: offers,
      priceHistory: offers.first.priceHistory,
      reviewAiScore: summary?.aiScore,
    );
  }

  static MarketplaceOffer _toOffer(MarketplaceProduct listing) => MarketplaceOffer(
    marketplace: listing.marketplace!,
    price: listing.currentPrice,
    productUrl: listing.buyUrl,
    inStock: listing.inStock,
    marketplaceProductId: listing.id,
    originalPrice: listing.originalPrice,
    sellerName: listing.sellerName,
    rating: listing.rating,
    reviewCount: listing.reviewCount,
    stockStatus: listing.stockStatus,
    priceHistory: [
      for (final entry in listing.priceHistory) PriceHistoryPoint(date: entry.recordedAt, price: entry.price),
    ],
  );

  /// Prefer catalog rating, then cheapest listing, then average of embedded review rows.
  /// Never invents a star rating from `review_summaries.ai_score`.
  static double _resolveRating(ProductRecord record, MarketplaceProduct cheapest, ReviewSummaryRecord? _) {
    if (record.rating > 0) return record.rating;
    final listing = cheapest.rating;
    if (listing != null && listing > 0) return listing;
    return _averageReviewRating(cheapest.reviews) ?? 0;
  }

  static int _resolveReviewCount(ProductRecord record, MarketplaceProduct cheapest, ReviewSummaryRecord? summary) {
    if (record.reviewCount > 0) return record.reviewCount;
    if (cheapest.reviewCount > 0) return cheapest.reviewCount;
    if (summary != null && summary.totalReviews > 0) return summary.totalReviews;
    if (cheapest.reviews.isNotEmpty) return cheapest.reviews.length;
    return 0;
  }

  static double? _averageReviewRating(List<ReviewRecord> reviews) {
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  }

  /// Images of the cheapest listing first, then any extra images from other marketplaces.
  static List<String> _gallery(List<MarketplaceProduct> listings, {required MarketplaceProduct preferred}) {
    final urls = <String>{
      for (final image in preferred.images) image.imageUrl,
      for (final listing in listings)
        for (final image in listing.images) image.imageUrl,
    }..remove('');
    return urls.toList();
  }

  /// Placeholder 0-99 score until the backend AI deal score exists:
  /// rewards discount and rating so ranking/badges stay meaningful.
  static int _interimScore({required int discountPercent, required double rating}) {
    final raw = 60 + discountPercent * 1.5 + (rating - 4) * 20;
    return raw.round().clamp(0, 99);
  }
}
