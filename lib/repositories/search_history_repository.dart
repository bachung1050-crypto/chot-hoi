import '../models/search_history_entry.dart';
import '../models/search_result.dart';

/// `search_histories` of the signed-in user.
abstract interface class SearchHistoryRepository {
  /// Newest first.
  Future<List<SearchHistoryEntry>> getRecent({int limit = 20});

  /// Skipped (returns null) when [query] repeats the latest entry.
  Future<SearchHistoryEntry?> add(String query, {SearchIntent? intent, int? resultCount});

  /// Removes every entry with exactly this query.
  Future<void> deleteQuery(String query);

  Future<void> clear();

  Future<int> count();
}
