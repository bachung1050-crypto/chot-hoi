import 'db/json_read.dart';

/// Row of `public.search_histories`.
class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.query,
    this.parsedIntent = const {},
    this.resultCount,
    this.createdAt,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) => SearchHistoryEntry(
    id: json['id'] as String,
    query: json['query'] as String? ?? '',
    parsedIntent: JsonRead.map(json['parsed_intent']) ?? const {},
    resultCount: JsonRead.toIntOrNull(json['result_count']),
    createdAt: JsonRead.toDate(json['created_at']),
  );

  final String id;
  final String query;

  /// `jsonb` snapshot of the understood intent (category, budget, brands...).
  final Map<String, dynamic> parsedIntent;
  final int? resultCount;
  final DateTime? createdAt;

  /// Same search typed twice in a row: compared case-insensitively.
  static bool sameQuery(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();
}
