abstract final class TextNormalizer {
  static const Map<String, String> _groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  static final Map<String, String> _map = {
    for (final entry in _groups.entries)
      for (final char in entry.value.split('')) char: entry.key,
  };

  /// Lowercases and strips Vietnamese diacritics: "Điện thoại" -> "dien thoai".
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().trim().split('')) {
      buffer.write(_map[char] ?? char);
    }
    return buffer.toString();
  }
}
