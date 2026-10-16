/// Helpers for `products.specs` JSONB (flexible key/value map per category).
abstract final class ProductSpecs {
  /// Parses RAM GB from `specs.ram` only (e.g. "16GB", "16 GB", "16").
  /// Returns null when the key is missing or unparsable — never invents a value.
  static int? ramGb(Map<String, dynamic> specs) {
    final raw = specs['ram'];
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final match = RegExp(r'(\d+)\s*(gb|g)?', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  static bool hasRam(Map<String, dynamic> specs) => ramGb(specs) != null;

  /// One-line summary for UI/search soft-match (category-appropriate keys only).
  static String summary(Map<String, dynamic> specs) {
    if (specs.isEmpty) return '';
    const preferred = ['cpu', 'ram', 'storage', 'gpu', 'screen', 'chip', 'display', 'battery', 'anc', 'sensor', 'switch', 'connectivity', 'size', 'resolution', 'panel'];
    final parts = <String>[];
    for (final key in preferred) {
      final value = specs[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      parts.add(text);
    }
    if (parts.isEmpty) {
      for (final entry in specs.entries) {
        if (entry.key == 'use_cases') continue;
        final text = entry.value?.toString().trim() ?? '';
        if (text.isNotEmpty) parts.add(text);
      }
    }
    return parts.take(5).join(' | ');
  }

  static List<String> useCases(Map<String, dynamic> specs) {
    final raw = specs['use_cases'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
    ];
  }

  /// Flatten for AI payloads (string values + use_cases list).
  static Map<String, dynamic> toPayload(Map<String, dynamic> specs) {
    if (specs.isEmpty) return const {};
    final out = <String, dynamic>{};
    for (final entry in specs.entries) {
      if (entry.key == 'use_cases') {
        out['use_cases'] = useCases(specs);
      } else if (entry.value != null) {
        out[entry.key] = entry.value.toString();
      }
    }
    return out;
  }
}
