import 'product.dart';

/// Response from Edge Function `ai-agent`.
class AiAgentResponse {
  const AiAgentResponse({
    required this.success,
    required this.message,
    this.intent,
    this.products = const [],
    this.productIds = const [],
    this.actions = const [],
    this.sources = const [],
    this.verdict,
    this.score,
    this.actionRequired,
    this.errorCode,
  });

  factory AiAgentResponse.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List
        ? [
            for (final item in value)
              if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
          ]
        : const [];

    final productsRaw = json['products'];
    final productIds = <String>[];
    if (productsRaw is List) {
      for (final item in productsRaw) {
        if (item is Map) {
          final id = item['id']?.toString();
          if (id != null && id.isNotEmpty) productIds.add(id);
        } else if (item != null) {
          productIds.add(item.toString());
        }
      }
    }
    productIds.addAll(strings(json['productIds'] ?? json['product_ids']));

    return AiAgentResponse(
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?)?.trim() ?? '',
      intent: json['intent'] as String?,
      productIds: productIds.toSet().toList(),
      actions: strings(json['actions']),
      sources: strings(json['sources']),
      verdict: json['verdict'] as String?,
      score: (json['score'] as num?)?.round(),
      actionRequired: json['action_required'] as String? ?? json['actionRequired'] as String?,
      errorCode: json['code'] as String? ?? json['errorCode'] as String?,
    );
  }

  final bool success;
  final String message;
  final String? intent;

  /// Optional hydrated products (filled by Flutter after resolving [productIds]).
  final List<Product> products;
  final List<String> productIds;

  /// Tool / step labels already completed (e.g. "Đã tìm sản phẩm").
  final List<String> actions;
  final List<String> sources;
  final String? verdict;
  final int? score;

  /// e.g. "Vui lòng đăng nhập để sử dụng tính năng này."
  final String? actionRequired;
  final String? errorCode;

  AiAgentResponse copyWith({
    bool? success,
    String? message,
    String? intent,
    List<Product>? products,
    List<String>? productIds,
    List<String>? actions,
    List<String>? sources,
    String? verdict,
    int? score,
    String? actionRequired,
    String? errorCode,
  }) =>
      AiAgentResponse(
        success: success ?? this.success,
        message: message ?? this.message,
        intent: intent ?? this.intent,
        products: products ?? this.products,
        productIds: productIds ?? this.productIds,
        actions: actions ?? this.actions,
        sources: sources ?? this.sources,
        verdict: verdict ?? this.verdict,
        score: score ?? this.score,
        actionRequired: actionRequired ?? this.actionRequired,
        errorCode: errorCode ?? this.errorCode,
      );
}
