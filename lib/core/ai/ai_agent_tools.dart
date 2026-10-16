/// Tool names exposed by Edge Function `ai-agent` (must stay in sync).
abstract final class AiAgentToolNames {
  static const searchProducts = 'SearchProducts';
  static const comparePrices = 'ComparePrices';
  static const getPriceHistory = 'GetPriceHistory';
  static const getReviews = 'GetReviews';
  static const getReviewSummary = 'GetReviewSummary';
  static const getChotHoiScore = 'GetChotHoiScore';
  static const saveProduct = 'SaveProduct';
  static const createPriceAlert = 'CreatePriceAlert';

  static const all = <String>{
    searchProducts,
    comparePrices,
    getPriceHistory,
    getReviews,
    getReviewSummary,
    getChotHoiScore,
    saveProduct,
    createPriceAlert,
  };
}

/// Offline oracle of which tools a well-behaved agent should prefer for known
/// Vietnamese shopping prompts. Used in unit tests — the live Edge Function
/// decides via OpenAI tool calling against real Supabase data.
abstract final class AiAgentToolPlanner {
  static List<String> expectedTools(String message) {
    final q = message.trim().toLowerCase();
    if (q.isEmpty) return const [];

    if (_isSave(q)) return const [AiAgentToolNames.saveProduct];
    if (_isPriceAlert(q)) return const [AiAgentToolNames.createPriceAlert];
    if (_isWorthBuying(q)) return const [AiAgentToolNames.getChotHoiScore];
    if (_isReview(q)) {
      return const [AiAgentToolNames.getReviewSummary, AiAgentToolNames.getReviews];
    }
    if (_isPriceHistory(q)) return const [AiAgentToolNames.getPriceHistory];
    if (_isCurrentPrice(q)) {
      return const [AiAgentToolNames.searchProducts, AiAgentToolNames.comparePrices];
    }
    if (_isSearch(q)) return const [AiAgentToolNames.searchProducts];

    return const [];
  }

  static bool requiresAuth(String tool) =>
      tool == AiAgentToolNames.saveProduct || tool == AiAgentToolNames.createPriceAlert;

  static bool _isSave(String q) =>
      q.contains('lưu sản phẩm') || q.startsWith('lưu ') || q == 'lưu sản phẩm này';

  static bool _isPriceAlert(String q) =>
      q.contains('nhắc tôi') || q.contains('cảnh báo') || q.contains('xuống');

  static bool _isWorthBuying(String q) =>
      q.contains('đáng mua') || q.contains('nen mua') || q.contains('nên mua');

  static bool _isReview(String q) =>
      q.contains('đánh giá') || q.contains('review') || q.contains('người dùng');

  static bool _isPriceHistory(String q) =>
      q.contains('giá hiện tại có tốt') ||
      q.contains('lịch sử giá') ||
      q.contains('giá có tốt không');

  static bool _isCurrentPrice(String q) =>
      q.contains('hiện giá') || q.contains('giá bao nhiêu') || q.contains('bao nhiêu tiền');

  static bool _isSearch(String q) =>
      q.contains('tìm') ||
      q.contains('laptop') ||
      q.contains('tai nghe') ||
      q.contains('điện thoại') ||
      q.contains('dưới');
}
