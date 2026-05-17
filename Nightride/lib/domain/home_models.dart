// lib/features/home/domain/home_models.dart
import 'package:flutter/foundation.dart';

@immutable
class FeaturedEvent {
  const FeaturedEvent({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.dateText,
    required this.imageUrl,
    this.genre = '',
    this.countryCode = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String dateText;
  final String imageUrl;
  final String genre;
  final String countryCode;
}

@immutable
class CategoryChip {
  const CategoryChip({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;
}

@immutable
class TrendingEvent {
  const TrendingEvent({
    required this.id,
    required this.title,
    required this.locationText,
    required this.dateText,
    required this.categoryTag,
    required this.imageUrl,
    required this.interestedCountText,
    this.avatars = const <String>[],
    this.countryCode = '',
    this.language = '',
    this.rawDate = '',
  });

  final String id;
  final String title;
  final String locationText;
  final String dateText;
  final String categoryTag;
  final String imageUrl;
  final String interestedCountText;
  final List<String> avatars;
  final String countryCode;
  final String language;
  /// Raw ISO date string (YYYY-MM-DD) used for notification scheduling and countdown display.
  final String rawDate;
}
