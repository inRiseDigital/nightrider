// lib/providers/nearby_venues_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/data/services/overpass_service.dart';
import 'package:nightride/providers/home_providers.dart';

final nearbyVenuesProvider = FutureProvider<List<OverpassVenue>>((ref) async {
  final pos = ref.watch(userLocationProvider).asData?.value;
  if (pos == null) return [];
  return OverpassService.fetchNearbyVenues(
    lat: pos.latitude,
    lng: pos.longitude,
    radiusMeters: 15000,
  );
});
