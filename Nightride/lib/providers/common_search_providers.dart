// lib/providers/search_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nightride/domain/search_models.dart';
import '../data/search_dummy_data.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchBarFocusedProvider = StateProvider<bool>((ref) => false);

final _firestoreSearchProvider = StreamProvider<List<SearchSuggestionItem>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            final city = d['city'] as String? ?? '';
            final country = d['country'] as String? ?? '';
            final loc = [city, country].where((s) => s.isNotEmpty).join(', ');
            return SearchSuggestionItem(
              id: doc.id,
              title: d['name'] as String? ?? '',
              subtitle: loc.isNotEmpty ? loc : 'Music Event',
            );
          }).toList());
});

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
