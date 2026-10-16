import 'package:chot_hoi/core/ai/ai_search_service.dart';
import 'package:chot_hoi/core/ai/fallback_search_intent_parser.dart';
import 'package:chot_hoi/core/ai/supabase_ai_search_service.dart';
import 'package:chot_hoi/models/search_intent.dart';
import 'package:chot_hoi/repositories/mock/mock_product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FallbackSearchIntentParser', () {
    test('1. Tìm laptop dưới 25 triệu', () {
      final intent = FallbackSearchIntentParser.parse('Tìm laptop dưới 25 triệu');
      expect(intent.category, 'laptop');
      expect(intent.categoryId, 'laptop');
      expect(intent.maxPrice, 25000000);
      expect(intent.brands, isEmpty);
    });

    test('2. Tìm laptop ASUS dưới 20 triệu', () {
      final intent = FallbackSearchIntentParser.parse('Tìm laptop ASUS dưới 20 triệu');
      expect(intent.category, 'laptop');
      expect(intent.brands, contains('ASUS'));
      expect(intent.maxPrice, 20000000);
    });

    test('3. Laptop để code RAM 16GB', () {
      final intent = FallbackSearchIntentParser.parse('Laptop để code RAM 16GB');
      expect(intent.category, 'laptop');
      expect(intent.useCase, 'code');
      expect(intent.purpose, 'code');
      expect(intent.minRam, 16);
      expect(intent.features, contains('ram_16gb'));
    });

    test('4. Điện thoại Samsung dưới 15 triệu', () {
      final intent = FallbackSearchIntentParser.parse('Điện thoại Samsung dưới 15 triệu');
      expect(intent.category, 'điện thoại');
      expect(intent.categoryId, 'phone');
      expect(intent.brands, contains('Samsung'));
      expect(intent.maxPrice, 15000000);
    });

    test('5. Tìm MacBook dưới 30 triệu', () {
      final intent = FallbackSearchIntentParser.parse('Tìm MacBook dưới 30 triệu');
      expect(intent.category, 'laptop');
      expect(intent.brands, contains('Apple'));
      expect(intent.maxPrice, 30000000);
    });

    test('6. Query rỗng', () {
      final intent = FallbackSearchIntentParser.parse('   ');
      expect(intent.query, '');
      expect(intent.keyword, '');
      expect(intent.category, isNull);
      expect(intent.maxPrice, isNull);
    });

    test('7. Không parse được → keyword = query gốc', () {
      final intent = FallbackSearchIntentParser.parse('xyzabc không rõ ràng');
      expect(intent.keyword, 'xyzabc không rõ ràng');
      expect(intent.category, isNull);
    });

    test('iPhone maps to phone + Apple', () {
      final intent = FallbackSearchIntentParser.parse('iPhone dưới 15 triệu');
      expect(intent.categoryId, 'phone');
      expect(intent.brands, contains('Apple'));
      expect(intent.maxPrice, 15000000);
    });
  });

  group('SearchIntent JSON', () {
    test('fromJson / toJson round-trip (camelCase Edge Function payload)', () {
      final intent = SearchIntent.fromJson({
        'category': 'laptop',
        'brands': ['ASUS'],
        'minPrice': null,
        'maxPrice': 25000000,
        'minRam': 16,
        'useCase': 'coding',
        'keyword': null,
        'features': ['ram_16gb'],
      }, query: 'Tìm laptop dưới 25 triệu để code');

      expect(intent.query, 'Tìm laptop dưới 25 triệu để code');
      expect(intent.useCase, 'code');
      expect(intent.maxPrice, 25000000);
      expect(intent.toJson()['max_price'], 25000000);
      expect(intent.toJson()['use_case'], 'code');
    });
  });

  group('AiSearchService fallback (no OpenAI key)', () {
    test('FallbackAiSearchService never throws and matches parser', () async {
      const service = FallbackAiSearchService();
      final intent = await service.parseSearchIntent('Tìm laptop dưới 25 triệu');
      expect(intent.maxPrice, 25000000);
      expect(intent.categoryId, 'laptop');
    });

    test('empty query is safe', () async {
      const service = FallbackAiSearchService();
      final intent = await service.parseSearchIntent('');
      expect(intent.query, isEmpty);
    });
  });

  group('Mock product search via intent', () {
    late MockProductRepository repository;

    setUp(() {
      repository = MockProductRepository(latency: Duration.zero);
    });

    test('laptop under 25M returns laptops within budget', () async {
      final result = await repository.searchProducts('Tìm laptop dưới 25 triệu');
      expect(result.intent.categoryId, 'laptop');
      expect(result.intent.maxPrice, 25000000);
      expect(result.products, isNotEmpty);
      expect(result.products.every((p) => p.categoryId == 'laptop'), isTrue);
      expect(result.products.every((p) => p.currentPrice <= 25000000), isTrue);
    });

    test('ASUS laptop under 20M prefers ASUS', () async {
      final result = await repository.searchProducts('Tìm laptop ASUS dưới 20 triệu');
      expect(result.intent.brands, contains('ASUS'));
      expect(result.products.every((p) => p.currentPrice <= 20000000), isTrue);
    });

    test('empty query returns no products and does not crash', () async {
      final result = await repository.searchProducts('  ');
      expect(result.products, isEmpty);
      expect(result.intent.query, isEmpty);
    });

    test('MacBook under 30M maps to Apple laptops', () async {
      final result = await repository.searchProducts('Tìm MacBook dưới 30 triệu');
      expect(result.intent.brands, contains('Apple'));
      expect(result.intent.categoryId, 'laptop');
    });
  });

  test('Edge Function name is ai-search', () {
    expect(SupabaseAiSearchService.functionName, 'ai-search');
  });
}
