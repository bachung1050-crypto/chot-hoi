import '../../models/category.dart';
import '../../models/search_result.dart';
import 'text_normalizer.dart';

/// Rule-based stand-in for the AI intent extraction that will run on the backend.
abstract final class SearchQueryParser {
  static final RegExp _budget = RegExp(r'(?:duoi|toi da|khong qua|tam|<)\s*(\d+(?:[.,]\d+)?)\s*(trieu|tr|m|k|nghin)?');

  static const Map<String, List<String>> _purposeKeywords = {
    'code': ['code', 'lap trinh', 'dev'],
    'gaming': ['game', 'gaming'],
    'office': ['van phong', 'hoc tap', 'sinh vien'],
    'design': ['do hoa', 'design', 'edit video'],
  };

  static const List<String> _dealKeywords = ['deal', 'giam gia', 'sale', 'khuyen mai'];

  static SearchIntent parse(
    String query, {
    required List<ProductCategory> categories,
    required Iterable<String> brands,
  }) {
    final text = TextNormalizer.normalize(query);

    String? categoryId;
    for (final category in categories) {
      if (category.keywords.any(text.contains)) {
        categoryId = category.id;
        break;
      }
    }

    int? maxPrice;
    final match = _budget.firstMatch(text);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
      final unit = match.group(2);
      final multiplier = switch (unit) {
        'k' || 'nghin' => 1000,
        'trieu' || 'tr' || 'm' => 1000000,
        _ => amount < 1000 ? 1000000 : 1,
      };
      maxPrice = (amount * multiplier).round();
    }

    final matchedBrands = [
      for (final brand in brands)
        if (RegExp('\\b${RegExp.escape(TextNormalizer.normalize(brand))}\\b').hasMatch(text)) brand,
    ];

    String? purpose;
    for (final entry in _purposeKeywords.entries) {
      if (entry.value.any(text.contains)) {
        purpose = entry.key;
        break;
      }
    }

    return SearchIntent(
      query: query.trim(),
      categoryId: categoryId,
      maxPrice: maxPrice,
      brands: matchedBrands,
      purpose: purpose,
      dealsOnly: _dealKeywords.any(text.contains),
    );
  }
}
