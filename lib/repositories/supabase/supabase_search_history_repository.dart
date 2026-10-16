import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../models/search_history_entry.dart';
import '../../models/search_result.dart';
import '../search_history_repository.dart';

class SupabaseSearchHistoryRepository implements SearchHistoryRepository {
  const SupabaseSearchHistoryRepository(this._db);

  static const String _columns = 'id,query,parsed_intent,result_count,created_at';

  final SupabaseService _db;

  @override
  Future<List<SearchHistoryEntry>> getRecent({int limit = 20}) {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.searchHistories)
          .select(_columns)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(SearchHistoryEntry.fromJson).toList();
    });
  }

  @override
  Future<SearchHistoryEntry?> add(String query, {SearchIntent? intent, int? resultCount}) {
    final userId = _db.requireUserId();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value();
    return _db.run((client) async {
      final latest = await client
          .from(DbTables.searchHistories)
          .select('query')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (latest != null && SearchHistoryEntry.sameQuery(latest['query'] as String? ?? '', trimmed)) return null;
      final row = await client
          .from(DbTables.searchHistories)
          .insert({
            'user_id': userId,
            'query': trimmed,
            'parsed_intent': intent?.toJson() ?? const <String, dynamic>{},
            'result_count': ?resultCount,
          })
          .select(_columns)
          .single();
      return SearchHistoryEntry.fromJson(row);
    });
  }

  @override
  Future<void> deleteQuery(String query) {
    final userId = _db.requireUserId();
    return _db.run((client) => client.from(DbTables.searchHistories).delete().eq('user_id', userId).eq('query', query));
  }

  @override
  Future<void> clear() {
    final userId = _db.requireUserId();
    return _db.run((client) => client.from(DbTables.searchHistories).delete().eq('user_id', userId));
  }

  @override
  Future<int> count() {
    final userId = _db.requireUserId();
    return _db.run((client) => client.from(DbTables.searchHistories).count(CountOption.exact).eq('user_id', userId));
  }
}
