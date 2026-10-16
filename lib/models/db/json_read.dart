import 'dart:convert';

/// Lenient readers for PostgREST JSON. Postgres `numeric` arrives as `num`
/// (or `String` for very large values), so prices are normalized here.
abstract final class JsonRead {
  static int toInt(Object? value, [int fallback = 0]) => switch (value) {
    final num n => n.round(),
    final String s => num.tryParse(s)?.round() ?? fallback,
    _ => fallback,
  };

  static int? toIntOrNull(Object? value) => value == null ? null : toInt(value);

  static double toDouble(Object? value, [double fallback = 0]) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s) ?? fallback,
    _ => fallback,
  };

  static DateTime? toDate(Object? value) => value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic>? map(Object? value) => value is Map<String, dynamic>
      ? value
      : (value is Map ? Map<String, dynamic>.from(value) : null);

  /// JSONB object → map (empty when null / not an object).
  static Map<String, dynamic> objectMap(Object? value) => map(value) ?? const {};

  static List<Map<String, dynamic>> list(Object? value) =>
      value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

  /// `jsonb` string arrays, plain string lists, or a single non-empty string.
  static List<String> stringList(Object? value) {
    if (value is List) {
      return [
        for (final item in value)
          if (item != null && item.toString().trim().isNotEmpty) item.toString().trim(),
      ];
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.startsWith('[')) {
        try {
          return stringList(jsonDecode(trimmed));
        } catch (_) {
          return [trimmed];
        }
      }
      return [trimmed];
    }
    return const [];
  }
}
