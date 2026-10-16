import 'package:chot_hoi/core/ai/ai_search_service.dart';
import 'package:chot_hoi/core/ai/fallback_search_intent_parser.dart';
import 'package:chot_hoi/core/ai/supabase_ai_search_service.dart';
import 'package:chot_hoi/models/search_intent.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests for Phase 5.1 OpenAI search wiring (no live OpenAI calls).
void main() {
  group('SearchIntent from Edge Function payload', () {
    test('parses OpenAI-shaped JSON including useCase coding → code', () {
      final intent = SearchIntent.fromJson({
        'category': 'laptop',
        'brands': ['ASUS', 'Lenovo'],
        'minPrice': null,
        'maxPrice': 25000000,
        'minRam': 16,
        'useCase': 'coding',
        'keyword': null,
        'features': <String>[],
      }, query: 'Tìm laptop dưới 25 triệu để code, ưu tiên ASUS hoặc Lenovo, RAM ít nhất 16GB');

      expect(intent.category, 'laptop');
      expect(intent.categoryId, 'laptop');
      expect(intent.brands, ['ASUS', 'Lenovo']);
      expect(intent.maxPrice, 25000000);
      expect(intent.minRam, 16);
      expect(intent.useCase, 'code');
      expect(intent.purpose, 'code');
    });

    test('empty / failure responses fall back locally', () async {
      const service = FallbackAiSearchService();
      expect((await service.parseSearchIntent('')).query, isEmpty);

      final intent = FallbackSearchIntentParser.parse('Tìm laptop dưới 25 triệu để code');
      expect(intent.maxPrice, 25000000);
      expect(intent.categoryId, 'laptop');
      expect(intent.useCase, 'code');
    });
  });

  test('Flutter invokes function name ai-search only', () {
    expect(SupabaseAiSearchService.functionName, 'ai-search');
  });
}
