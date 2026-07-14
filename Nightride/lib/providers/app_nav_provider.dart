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
  const MapFocus(this.lat, this.lng, {this.label = '', this.placeId});
  final double lat;
  final double lng;
  final String label;
  final String? placeId;
}

final mapFocusProvider = StateProvider<MapFocus?>((ref) => null);
