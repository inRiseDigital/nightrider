import 'package:flutter/foundation.dart';

@immutable
class MapCategory {
  const MapCategory(this.label);
  final String label;
}

@immutable
class MapBottomCardData {
  const MapBottomCardData({
    this.id = '',
    this.placeId,
    required this.title,
    required this.subtitle,
    required this.locationLine,
    required this.imageUrl,
    required this.tags,
    required this.distanceKm,
    required this.openText,
    required this.priceHint,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String? placeId;
  final String title;
  final String subtitle;
  final String locationLine;
  final String imageUrl;
  final List<String> tags;
  final double distanceKm;
  final String openText;
  final String priceHint;
  final double lat;
  final double lng;

  MapBottomCardData copyWith({
    String? id,
    String? placeId,
    String? title,
    String? subtitle,
    String? locationLine,
    String? imageUrl,
    List<String>? tags,
    double? distanceKm,
    String? openText,
    String? priceHint,
    double? lat,
    double? lng,
  }) {
    return MapBottomCardData(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      locationLine: locationLine ?? this.locationLine,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      distanceKm: distanceKm ?? this.distanceKm,
      openText: openText ?? this.openText,
      priceHint: priceHint ?? this.priceHint,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

const List<MapCategory> kMapCategories = <MapCategory>[
  MapCategory('DJ'),
  MapCategory('EDM'),
  MapCategory('Techno'),
  MapCategory('Hip-Hop'),
  MapCategory('J-Pop'),
  MapCategory('House'),
  MapCategory('Trap'),
  MapCategory('R&B'),
];

const List<MapBottomCardData> kBottomCards = <MapBottomCardData>[
  MapBottomCardData(
    title: 'WARP Shinjuku — Neon District Special Guest All Night Long',
    subtitle: 'Club • Nightlife',
    locationLine: 'Tokyo, Shinjuku City',
    imageUrl:
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=900&q=80',
    tags: <String>['4.5', 'EDM', 'Night', '21+', 'VIP'],
    distanceKm: 1.1,
    openText: 'Open • 10PM - 4AM',
    priceHint: 'From \$12',
    lat: 35.6938,
    lng: 139.7034,
  ),
  MapBottomCardData(
    title: 'Neon Warehouse Sessions (After Hours)',
    subtitle: 'After Party • Techno',
    locationLine: 'Colombo, Sri Lanka',
    imageUrl:
        'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=900&q=80',
    tags: <String>['4.7', 'Techno', 'Night', '18+'],
    distanceKm: 1.1,
    openText: 'Open • 9PM - 3AM',
    priceHint: 'From \$8',
    lat: 6.9271,
    lng: 79.8612,
  ),
  MapBottomCardData(
    title: 'Skyline Rave Festival — Main Stage',
    subtitle: 'Festival • EDM',
    locationLine: 'Galle Face, Colombo',
    imageUrl:
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=900&q=80',
    tags: <String>['4.3', 'DJ', 'EDM', 'Outdoor', '21+'],
    distanceKm: 4.8,
    openText: 'Tonight • 7PM - Late',
    priceHint: 'From \$15',
    lat: 6.9318,
    lng: 79.8415,
  ),
];
