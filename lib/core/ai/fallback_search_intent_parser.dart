import '../../models/search_intent.dart';
import '../utils/text_normalizer.dart';

/// Rule-based intent parser used when the Edge Function / OpenAI is unavailable.
///
/// Does not invent products — only extracts filters from the query text.
abstract final class FallbackSearchIntentParser {
  static final RegExp _maxBudget = RegExp(
    r'(?:duoi|toi da|khong qua|tam|<)\s*(\d+(?:[.,]\d+)?)\s*(trieu|tr|m|k|nghin)?',
  );
  static final RegExp _minBudget = RegExp(r'(?:tu|tren|>)\s*(\d+(?:[.,]\d+)?)\s*(trieu|tr|m|k|nghin)?');
  static final RegExp _ram = RegExp(r'(?:ram\s*)?(\d+)\s*gb(?:\s*ram)?|ram\s*(\d+)');

  static const Map<String, List<String>> _categoryKeywords = {
    'laptop': ['laptop', 'may tinh xach tay', 'notebook', 'macbook'],
    'điện thoại': ['dien thoai', 'smartphone', 'iphone', 'phone'],
    'tai nghe': ['tai nghe', 'headphone', 'earbuds', 'airpods'],
    'chuột': ['chuot', 'mouse'],
    'bàn phím': ['ban phim', 'keyboard'],
    'màn hình': ['man hinh', 'monitor'],
    'smartwatch': ['smartwatch', 'dong ho thong minh', 'apple watch'],
    'gia dụng': ['gia dung', 'robot hut bui'],
    'thời trang': ['thoi trang', 'giay', 'sneaker'],
    'phụ kiện': ['phu kien', 'sac du phong', 'pin du phong'],
  };

  static const List<String> _knownBrands = [
    'ASUS',
    'Lenovo',
    'Apple',
    'Samsung',
    'Sony',
    'HP',
    'Dell',
    'Acer',
    'MSI',
    'Xiaomi',
    'Oppo',
    'Logitech',
    'Razer',
    'LG',
    'Huawei',
  ];

  static const Map<String, String> _brandAliases = {
    'iphone': 'Apple',
    'macbook': 'Apple',
    'ipad': 'Apple',
    'airpods': 'Apple',
    'galaxy': 'Samsung',
  };

  static const Map<String, List<String>> _useCaseKeywords = {
    'code': ['code', 'coding', 'lap trinh', 'dev', 'developer'],
    'gaming': ['game', 'gaming'],
    'office': ['van phong', 'hoc tap', 'sinh vien'],
    'design': ['do hoa', 'design', 'edit video'],
  };

  static const List<String> _dealKeywords = ['deal', 'giam gia', 'sale', 'khuyen mai'];

  static const List<String> _stopWords = [
    'tim',
    'tim kiem',
    'cho',
    'toi',
    'minh',
    'mot',
    'cai',
    'de',
    'voi',
    'va',
    'hoac',
    'uu',
    'tien',
    'duoi',
    'tren',
    'tu',
    'toi da',
    'khong',
    'qua',
    'tam',
    'trieu',
    'tr',
    'gb',
    'ram',
  ];

  static SearchIntent parse(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchIntent(query: '', keyword: '');
    }

    final text = TextNormalizer.normalize(trimmed);

    String? category;
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any(text.contains)) {
        category = entry.key;
        break;
      }
    }

    final brands = <String>{
      for (final brand in _knownBrands)
        if (RegExp('\\b${RegExp.escape(TextNormalizer.normalize(brand))}\\b').hasMatch(text)) brand,
      for (final entry in _brandAliases.entries)
        if (text.contains(entry.key)) entry.value,
    }.toList();

    final maxMatch = _maxBudget.firstMatch(text);
    final maxPrice = maxMatch == null ? null : _toVnd(maxMatch.group(1)!, maxMatch.group(2));

    final minMatch = _minBudget.firstMatch(text);
    final minPrice = minMatch == null ? null : _toVnd(minMatch.group(1)!, minMatch.group(2));

    int? minRam;
    final ramMatch = _ram.firstMatch(text);
    if (ramMatch != null) {
      minRam = int.tryParse(ramMatch.group(1) ?? ramMatch.group(2) ?? '');
    }

    String? useCase;
    for (final entry in _useCaseKeywords.entries) {
      if (entry.value.any(text.contains)) {
        useCase = entry.key;
        break;
      }
    }

    final features = <String>[
      if (text.contains('chong on') || text.contains('noise cancell')) 'noise_cancelling',
      if (text.contains('chinh hang')) 'official',
      if (minRam != null) 'ram_${minRam}gb',
    ];

    final keyword = _keywordLeftover(text, category: category, brands: brands, useCase: useCase);
    final hasStructure =
        category != null ||
        brands.isNotEmpty ||
        maxPrice != null ||
        minPrice != null ||
        minRam != null ||
        useCase != null;

    return SearchIntent(
      query: trimmed,
      category: category,
      brands: brands,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRam: minRam,
      useCase: useCase,
      keyword: hasStructure ? (keyword.isEmpty ? null : keyword) : trimmed,
      features: features,
      dealsOnly: _dealKeywords.any(text.contains),
    );
  }

  static int _toVnd(String amountText, String? unit) {
    final amount = double.tryParse(amountText.replaceAll(',', '.')) ?? 0;
    final multiplier = switch (unit) {
      'k' || 'nghin' => 1000,
      'trieu' || 'tr' || 'm' => 1000000,
      _ => amount < 1000 ? 1000000 : 1,
    };
    return (amount * multiplier).round();
  }

  static String _keywordLeftover(
    String normalized, {
    required String? category,
    required List<String> brands,
    required String? useCase,
  }) {
    var text = normalized;
    for (final brand in brands) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(TextNormalizer.normalize(brand))}\\b'), ' ');
    }
    for (final alias in _brandAliases.keys) {
      text = text.replaceAll(alias, ' ');
    }
    if (category != null) {
      for (final kw in _categoryKeywords[category] ?? const <String>[]) {
        text = text.replaceAll(kw, ' ');
      }
    }
    if (useCase != null) {
      for (final kw in _useCaseKeywords[useCase] ?? const <String>[]) {
        text = text.replaceAll(kw, ' ');
      }
    }
    text = text.replaceAll(_maxBudget, ' ').replaceAll(_minBudget, ' ').replaceAll(_ram, ' ');
    for (final stop in _stopWords) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(stop)}\\b'), ' ');
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
