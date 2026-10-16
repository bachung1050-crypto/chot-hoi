import 'package:chot_hoi/core/ai/ai_agent_service.dart';
import 'package:chot_hoi/models/ai_agent_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiAgentResponse.fromJson', () {
    test('parses full successful agent payload', () {
      final response = AiAgentResponse.fromJson({
        'success': true,
        'message': 'Giá đang tốt, đánh giá ổn.',
        'intent': 'worth_buying',
        'products': [
          {'id': 'p1', 'name': 'ASUS Vivobook'},
          {'id': 'p2'},
        ],
        'actions': ['Đã tìm sản phẩm', 'Đã so sánh giá'],
        'sources': ['products', 'marketplace_products'],
        'verdict': 'ĐÁNG MUA',
        'score': 87,
        'action_required': null,
      });

      expect(response.success, isTrue);
      expect(response.message, contains('Giá đang tốt'));
      expect(response.intent, 'worth_buying');
      expect(response.productIds, ['p1', 'p2']);
      expect(response.actions, hasLength(2));
      expect(response.sources, contains('products'));
      expect(response.verdict, 'ĐÁNG MUA');
      expect(response.score, 87);
      expect(response.actionRequired, isNull);
    });

    test('parses authentication required', () {
      final response = AiAgentResponse.fromJson({
        'success': true,
        'message': 'Cần đăng nhập để lưu sản phẩm.',
        'intent': 'save',
        'products': [],
        'actions': ['Đã thử lưu sản phẩm'],
        'sources': ['saved_products'],
        'action_required': 'Vui lòng đăng nhập để sử dụng tính năng này.',
      });

      expect(response.actionRequired, contains('đăng nhập'));
      expect(response.productIds, isEmpty);
    });

    test('parses OpenAI / tool error fallback', () {
      final response = AiAgentResponse.fromJson({
        'success': false,
        'message': 'Chốt Hời AI chưa lấy được dữ liệu này.',
        'intent': 'error',
        'products': [],
        'actions': [],
        'sources': [],
        'code': 'AI_UNAVAILABLE',
      });

      expect(response.success, isFalse);
      expect(response.errorCode, 'AI_UNAVAILABLE');
      expect(response.message, contains('chưa lấy được'));
    });

    test('dedupes product ids from maps and productIds', () {
      final response = AiAgentResponse.fromJson({
        'success': true,
        'message': 'ok',
        'products': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'productIds': ['b', 'c'],
      });
      expect(response.productIds.toSet(), {'a', 'b', 'c'});
    });
  });

  group('FallbackAiAgentService', () {
    const service = FallbackAiAgentService();

    test('empty message', () async {
      final response = await service.ask('   ');
      expect(response.success, isFalse);
      expect(response.errorCode, 'EMPTY_MESSAGE');
    });

    test('unknown / offline request does not invent products', () async {
      final response = await service.ask('xyz không rõ');
      expect(response.success, isFalse);
      expect(response.productIds, isEmpty);
      expect(response.products, isEmpty);
      expect(response.score, isNull);
      expect(response.errorCode, 'AI_OFFLINE');
    });
  });
}
