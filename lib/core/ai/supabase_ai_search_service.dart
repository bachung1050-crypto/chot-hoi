import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/search_intent.dart';
import '../services/supabase_service.dart';
import 'ai_search_service.dart';

/// Calls the `ai-search` Edge Function (OpenAI behind Supabase secrets).
///
/// On any failure — function not deployed, AI unavailable, network — falls back
/// to [fallback] so search never crashes and never invents products.
class SupabaseAiSearchService implements AiSearchService {
  // Named `fallback:` so the argument binds across libraries (not `this._fallback`).
  // ignore: prefer_initializing_formals
  const SupabaseAiSearchService(this._db, {required AiSearchService fallback}) : _fallback = fallback;

  final SupabaseService _db;
  final AiSearchService _fallback;

  static const String functionName = 'ai-search';

  @override
  Future<SearchIntent> parseSearchIntent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const SearchIntent(query: '', keyword: '');

    try {
      final response = await _db.client.functions.invoke(
        functionName,
        body: {'query': trimmed},
      );

      // Non-2xx from Edge (e.g. 400 empty query) lands here with status / data.
      final data = response.data;
      if (data is! Map) return await _fallback.parseSearchIntent(trimmed);

      final map = Map<String, dynamic>.from(data);
      if (map['success'] == false) {
        // Stable codes from the function: EMPTY_QUERY, AI_UNAVAILABLE, …
        return await _fallback.parseSearchIntent(trimmed);
      }

      final payload = map['data'];
      if (payload is! Map) return await _fallback.parseSearchIntent(trimmed);

      return _toIntent(Map<String, dynamic>.from(payload), trimmed);
    } on FunctionException {
      return _fallback.parseSearchIntent(trimmed);
    } on Exception {
      return _fallback.parseSearchIntent(trimmed);
    }
  }

  static SearchIntent _toIntent(Map<String, dynamic> payload, String query) {
    final intent = SearchIntent.fromJson(payload, query: query);
    if (intent.query.isNotEmpty) return intent;
    return SearchIntent(
      query: query,
      category: intent.category,
      brands: intent.brands,
      minPrice: intent.minPrice,
      maxPrice: intent.maxPrice,
      minRam: intent.minRam,
      useCase: intent.useCase,
      keyword: intent.keyword,
      features: intent.features,
      dealsOnly: intent.dealsOnly,
    );
  }
}
