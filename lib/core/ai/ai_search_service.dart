import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/search_intent.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import 'fallback_search_intent_parser.dart';
import 'supabase_ai_search_service.dart';

/// Parses a natural-language query into a [SearchIntent].
///
/// Flutter implementations must never call OpenAI directly — only a local
/// fallback or a Supabase Edge Function that holds `OPENAI_API_KEY` as a secret.
abstract interface class AiSearchService {
  Future<SearchIntent> parseSearchIntent(String query);
}

/// Always uses [FallbackSearchIntentParser] (mock mode / offline).
class FallbackAiSearchService implements AiSearchService {
  const FallbackAiSearchService();

  @override
  Future<SearchIntent> parseSearchIntent(String query) async => FallbackSearchIntentParser.parse(query);
}

final aiSearchServiceProvider = Provider<AiSearchService>((ref) {
  if (AppConfig.useMockData) return const FallbackAiSearchService();
  return SupabaseAiSearchService(ref.watch(supabaseServiceProvider), fallback: const FallbackAiSearchService());
});
