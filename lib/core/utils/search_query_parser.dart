import '../../models/category.dart';
import '../../models/search_intent.dart';
import '../ai/fallback_search_intent_parser.dart';

/// Thin wrapper kept for call sites that still pass category/brand catalogs.
///
/// Phase 5.1 parsing lives in [FallbackSearchIntentParser] (and the Edge Function).
/// Catalog arguments are ignored — the fallback uses built-in keywords so it
/// matches the Edge Function when OpenAI is not configured.
abstract final class SearchQueryParser {
  static SearchIntent parse(
    String query, {
    List<ProductCategory> categories = const [],
    Iterable<String> brands = const [],
  }) {
    // catalogs kept in the signature for backward compatibility with older call sites
    return FallbackSearchIntentParser.parse(query);
  }
}
