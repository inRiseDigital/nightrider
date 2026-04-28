// lib/models/search_models.dart
import 'package:flutter/foundation.dart';

@immutable
class SearchSuggestionItem {
  const SearchSuggestionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? avatarUrl;
}
