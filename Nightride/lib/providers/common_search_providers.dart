// lib/providers/search_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nightride/domain/event.dart';
import 'package:nightride/domain/search_models.dart';
import 'package:nightride/services/firestore_service.dart';
import '../data/search_dummy_data.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchBarFocusedProvider = StateProvider<bool>((ref) => false);

/// status == 'published', ordered by name, with a prefix range on name.
/// Index: events(status ASC, name ASC)
///
/// This only matches names that literally *start with* the typed text
/// (Firestore range queries are byte-order, case-sensitive) — a query-side
/// narrowing, not the old client-side substring search. [searchFilteredProvider]
/// still does a final case-insensitive contains-check over title+subtitle on
/// top of these results.
final _firestoreSearchProvider = StreamProvider<List<SearchSuggestionItem>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return firestoreService.streamSearchEvents(query).map(
        (events) => events.map(_toSuggestion).toList(),
      );
});

SearchSuggestionItem _toSuggestion(Event e) {
  final loc = [e.city, e.countryCode].where((s) => s.isNotEmpty).join(', ');
  return SearchSuggestionItem(
    id: e.id,
    title: e.name,
    subtitle: loc.isNotEmpty ? loc : 'Music Event',
  );
}

final searchSourceProvider = Provider<List<SearchSuggestionItem>>((ref) {
  return ref.watch(_firestoreSearchProvider).maybeWhen(
    data: (items) => items,
    orElse: () => kSearchSuggestions,
  );
});

final searchFilteredProvider = Provider<List<SearchSuggestionItem>>((ref) {
  final String q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final List<SearchSuggestionItem> all = ref.watch(searchSourceProvider);

  if (q.isEmpty) return all;

  return all.where((SearchSuggestionItem item) {
    final String hay = '${item.title} ${item.subtitle}'.toLowerCase();
    return hay.contains(q);
  }).toList();
});

/// ✅ NEW: UI state for search (idle / results / empty)
enum SearchUiState { idle, results, empty }

final searchUiStateProvider = Provider<SearchUiState>((ref) {
  final String q = ref.watch(searchQueryProvider).trim();
  final List<SearchSuggestionItem> results = ref.watch(searchFilteredProvider);

  if (q.isEmpty) return SearchUiState.idle;
  if (results.isEmpty) return SearchUiState.empty;
  return SearchUiState.results;
});
