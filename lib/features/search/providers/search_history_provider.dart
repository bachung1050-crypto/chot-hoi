import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_history_entry.dart';
import '../../../models/search_result.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/search_history_repository.dart';
import '../../auth/providers/auth_providers.dart';

/// Signed-in user's recent searches (newest first); empty when signed out.
class SearchHistoryNotifier extends AsyncNotifier<List<SearchHistoryEntry>> {
  SearchHistoryRepository get _repository => ref.read(searchHistoryRepositoryProvider);

  List<SearchHistoryEntry> get _current => state.value ?? const [];

  @override
  Future<List<SearchHistoryEntry>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.watch(searchHistoryRepositoryProvider).getRecent();
  }

  /// Saves a finished search. Never throws: history must not break searching.
  Future<void> record(SearchResult result) async {
    if (ref.read(currentUserIdProvider) == null) return;
    try {
      final entry = await _repository.add(
        result.intent.query,
        intent: result.intent,
        resultCount: result.products.length,
      );
      if (entry != null) {
        state = AsyncData([entry, ..._current]);
        ref.invalidate(searchCountProvider);
      }
    } catch (_) {}
  }

  Future<void> deleteQuery(String query) =>
      _optimistic(_current.where((e) => e.query != query).toList(), () => _repository.deleteQuery(query));

  Future<void> clear() => _optimistic(const [], _repository.clear);

  Future<void> _optimistic(List<SearchHistoryEntry> next, Future<void> Function() request) async {
    final previous = _current;
    state = AsyncData(next);
    try {
      await request();
      ref.invalidate(searchCountProvider);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final searchHistoryProvider = AsyncNotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
  SearchHistoryNotifier.new,
);

/// Distinct recent queries for the search screen chips.
final recentSearchQueriesProvider = Provider<List<String>>((ref) {
  final entries = ref.watch(searchHistoryProvider).value ?? const [];
  final seen = <String>{};
  return [
    for (final entry in entries)
      if (seen.add(entry.query)) entry.query,
  ].take(8).toList();
});

/// Total searches of the signed-in user (profile stats).
final searchCountProvider = FutureProvider<int>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return 0;
  return ref.watch(searchHistoryRepositoryProvider).count();
});
