// lib/features/shell/presentation/providers/app_nav_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final appNavProvider = NotifierProvider<AppNavNotifier, int>(
  AppNavNotifier.new,
);

class AppNavNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

class MapFocus {
  const MapFocus(
    this.lat,
    this.lng, {
    this.label = '',
    this.placeId,
    this.id = '',
    this.subtitle = '',
    this.locationLine = '',
    this.imageUrl = '',
    this.tags = const <String>[],
    this.priceHint = '',
  });
  final double lat;
  final double lng;
  final String label;
  final String? placeId;

  // Optional detail fields so the map can show a place sheet for the focused
  // location without having to re-fetch it from the events pool.
  final String id;
  final String subtitle;
  final String locationLine;
  final String imageUrl;
  final List<String> tags;
  final String priceHint;
}

final mapFocusProvider = StateProvider<MapFocus?>((ref) => null);
