// lib/data/services/overpass_service.dart
// Fetches nearby bars/clubs from OpenStreetMap Overpass API — free, no API key.
import 'dart:convert';
import 'package:http/http.dart' as http;

class OverpassVenue {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String type; // bar, nightclub, pub, biergarten
  final String? openingHours;
  final String? phone;
  final String? website;
  final String? address;

  const OverpassVenue({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    this.openingHours,
    this.phone,
    this.website,
    this.address,
  });

  String get typeLabel {
    switch (type) {
      case 'nightclub':   return 'Night Club';
      case 'bar':         return 'Bar';
      case 'pub':         return 'Pub';
      case 'biergarten':  return 'Beer Garden';
      case 'cocktail_bar': return 'Cocktail Bar';
      case 'wine_bar':    return 'Wine Bar';
      case 'sports_bar':  return 'Sports Bar';
      case 'lounge':      return 'Lounge';
      default:            return type.replaceAll('_', ' ');
    }
  }
}

class OverpassService {
  // Multiple mirrors — tried in order until one succeeds
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
  ];

  static Future<List<OverpassVenue>> fetchNearbyVenues({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
  }) async {
    // ── Expanded query ──────────────────────────────────────────────
    // 1. Standard amenity tags (global)
    // 2. leisure=nightclub|dance (common in South/Southeast Asia)
    // 3. club=* tag
    // 4. bar=yes on any node/way
    // 5. NAME-BASED search — catches venues tagged only with a name
    //    like "Humbugs Bar" with no amenity tag (very common in Sri Lanka)
    final query = '''
[out:json][timeout:45];
(
  node["amenity"~"bar|nightclub|pub|biergarten|cocktail_bar|wine_bar|sports_bar|lounge|casino|social_club|events_venue|dance"](around:$radiusMeters,$lat,$lng);
  way["amenity"~"bar|nightclub|pub|biergarten|cocktail_bar|wine_bar|sports_bar|lounge|casino|social_club|events_venue|dance"](around:$radiusMeters,$lat,$lng);
  node["leisure"~"nightclub|dance"](around:$radiusMeters,$lat,$lng);
  way["leisure"~"nightclub|dance"](around:$radiusMeters,$lat,$lng);
  node["club"](around:$radiusMeters,$lat,$lng);
  way["club"](around:$radiusMeters,$lat,$lng);
  node["bar"="yes"](around:$radiusMeters,$lat,$lng);
  way["bar"="yes"](around:$radiusMeters,$lat,$lng);
  node["name"~"bar|club|pub|lounge|nightclub|disco|cocktail|tavern|brewhouse|taproom",i](around:$radiusMeters,$lat,$lng);
  way["name"~"bar|club|pub|lounge|nightclub|disco|cocktail|tavern|brewhouse|taproom",i](around:$radiusMeters,$lat,$lng);
);
out center;
''';

    http.Response? resp;
    for (final endpoint in _endpoints) {
      try {
        resp = await http
            .post(Uri.parse(endpoint), body: {'data': query})
            .timeout(const Duration(seconds: 45));
        if (resp.statusCode == 200) break;
      } catch (_) {
        resp = null;
      }
    }

    if (resp == null || resp.statusCode != 200) return [];

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (json['elements'] as List? ?? []);

    final seen = <String>{};
    final venues = <OverpassVenue>[];

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = (tags['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;

      double? vLat, vLng;
      if (el['type'] == 'node') {
        vLat = (el['lat'] as num?)?.toDouble();
        vLng = (el['lon'] as num?)?.toDouble();
      } else if (el['type'] == 'way') {
        final center = el['center'] as Map<String, dynamic>?;
        vLat = (center?['lat'] as num?)?.toDouble();
        vLng = (center?['lon'] as num?)?.toDouble();
      }
      if (vLat == null || vLng == null) continue;

      // Deduplicate by name (same venue can appear as both node and way)
      final key = name.toLowerCase();
      if (!seen.add(key)) continue;

      final street  = tags['addr:street'] as String?;
      final houseNo = tags['addr:housenumber'] as String?;
      String? address;
      if (street != null) {
        address = houseNo != null ? '$street $houseNo' : street;
      }

      // leisure=nightclub is common in South/Southeast Asia
      final amenity = tags['amenity'] as String?;
      final leisure = tags['leisure'] as String?;
      final type = (amenity != null && amenity.isNotEmpty)
          ? amenity
          : (leisure == 'nightclub' ? 'nightclub' : 'bar');

      venues.add(OverpassVenue(
        id: '${el['id']}',
        name: name,
        lat: vLat,
        lng: vLng,
        type: type,
        openingHours: tags['opening_hours'] as String?,
        phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
        website: tags['website'] as String? ?? tags['contact:website'] as String?,
        address: address,
      ));
    }

    return venues;
  }
}
