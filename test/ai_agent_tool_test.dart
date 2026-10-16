import 'package:chot_hoi/core/ai/ai_agent_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiAgentToolNames', () {
    test('exposes all Phase 5.4 tools', () {
      expect(AiAgentToolNames.all, containsAll([
        AiAgentToolNames.searchProducts,
        AiAgentToolNames.comparePrices,
        AiAgentToolNames.getPriceHistory,
        AiAgentToolNames.getReviews,
        AiAgentToolNames.getReviewSummary,
        AiAgentToolNames.getChotHoiScore,
        AiAgentToolNames.saveProduct,
        AiAgentToolNames.createPriceAlert,
      ]));
      expect(AiAgentToolNames.all.length, 8);
    });
  });

  group('AiAgentToolPlanner — use cases', () {
    test('Test 1: search laptop ASUS under budget', () {
      final tools = AiAgentToolPlanner.expectedTools('Tìm laptop ASUS dưới 25 triệu để code');
      expect(tools, [AiAgentToolNames.searchProducts]);
    });

    test('Test 2: current price → search + compare', () {
      final tools = AiAgentToolPlanner.expectedTools('ASUS Vivobook S 14 OLED hiện giá bao nhiêu?');
      expect(tools, [AiAgentToolNames.searchProducts, AiAgentToolNames.comparePrices]);
    });

    test('Test 3: price quality → history', () {
      final tools = AiAgentToolPlanner.expectedTools('Sản phẩm này giá hiện tại có tốt không?');
      expect(tools, [AiAgentToolNames.getPriceHistory]);
    });

    test('Test 4: reviews', () {
      final tools = AiAgentToolPlanner.expectedTools('Người dùng đánh giá sản phẩm này thế nào?');
      expect(tools.first, AiAgentToolNames.getReviewSummary);
      expect(tools, contains(AiAgentToolNames.getReviews));
    });

    test('Test 5: worth buying → score', () {
      final tools = AiAgentToolPlanner.expectedTools('Sản phẩm này có đáng mua không?');
      expect(tools, [AiAgentToolNames.getChotHoiScore]);
    });

    test('Test 6: price alert requires auth tool', () {
      final tools = AiAgentToolPlanner.expectedTools('Nhắc tôi khi sản phẩm này xuống 20 triệu');
      expect(tools, [AiAgentToolNames.createPriceAlert]);
      expect(AiAgentToolPlanner.requiresAuth(tools.single), isTrue);
    });

    test('Test 7: save product requires auth tool', () {
      final tools = AiAgentToolPlanner.expectedTools('Lưu sản phẩm này');
      expect(tools, [AiAgentToolNames.saveProduct]);
      expect(AiAgentToolPlanner.requiresAuth(tools.single), isTrue);
    });

    test('empty message → no tools', () {
      expect(AiAgentToolPlanner.expectedTools(''), isEmpty);
      expect(AiAgentToolPlanner.expectedTools('   '), isEmpty);
    });

    test('unknown request → no invented tool', () {
      expect(AiAgentToolPlanner.expectedTools('xyzabc hoàn toàn vô nghĩa'), isEmpty);
    });
  });
}
