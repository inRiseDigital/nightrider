// Free replacement for Google Places API.
//   Nearby search  : Overpass API  (overpass-api.de)  — completely free
//   Text search    : Nominatim     (nominatim.org)     — free, 1 req/s
//   Place details  : Overpass API  (via open_map_service.dart)
//
// Drop-in replacement — same models and method signatures as before.
import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'open_map_service.dart';
import 'yelp_service.dart';

// ── Models (unchanged interface) ─────────────────────────────────────────────

class PlaceSearchResult {
  final String placeId;
  final String name;
  final String address;
  final double lat, lng;
  final double? rating;
  final bool? openNow;
  final List<String> types;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.openNow,
    this.types = const [],
  });
}

class PlaceReview {
  final String authorName;
  final int rating;
  final String text;
  final String relativeTime;

  const PlaceReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.relativeTime,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double lat, lng;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  final List<String>? weekdayText;
  final String? phoneNumber;
  final String? website;
  final List<String> photoUrls;
  final List<PlaceReview> reviews;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
    this.weekdayText,
    this.phoneNumber,
    this.website,
    this.photoUrls = const [],
    this.reviews = const [],
  });
}

// ── Service ──────────────────────────────────────────────────────────────────

class PlacesService {
  static const _overpass  = 'https://overpass-api.de/api/interpreter';
  static const _nominatim = 'https://nominatim.openstreetmap.org';
  static const _ua        = 'NightrideApp/1.0 (contact: dev@nightride.app)';

  // Nightlife amenity types to query in Overpass
  static const _nightlifeAmenities =
      'nightclub|bar|pub|biergarten|cocktail_bar|wine_bar|lounge|sports_bar';

  // ── Nearby search (Overpass) ────────────────────────────────────────────────

  /// Finds nearby nightlife venues using Overpass API — replaces Google Places nearbysearch.
  static Future<List<PlaceSearchResult>> nearbySearch({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final overpassQuery = '''
[out:json][timeout:20];
(
  node["amenity"~"^($_nightlifeAmenities)\$"](around:$radiusMeters,$lat,$lng);
  way["amenity"~"^($_nightlifeAmenities)\$"](around:$radiusMeters,$lat,$lng);
  relation["amenity"~"^($_nightlifeAmenities)\$"](around:$radiusMeters,$lat,$lng);
);
out center;
''';
    // Run Overpass + Yelp in parallel
    final futures = await Future.wait([
      http.post(Uri.parse(_overpass), body: {'data': overpassQuery})
          .timeout(const Duration(seconds: 25)),
      YelpService.nearbySearch(lat: lat, lng: lng, radiusMeters: radiusMeters),
    ]);

    final overpassRes  = futures[0] as http.Response;
    final yelpResults  = futures[1] as List<YelpBusiness>;

    if (overpassRes.statusCode != 200) {
      debugPrint('Overpass nearby: HTTP ${overpassRes.statusCode}');
      return [];
    }

    final data     = json.decode(overpassRes.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List?) ?? [];
    final seen     = <String>{};
    final results  = <PlaceSearchResult>[];

    for (final el in elements) {
      final m    = el as Map<String, dynamic>;
      final type = m['type'] as String? ?? 'node';
      final id   = '$type/${m['id']}';
      if (seen.contains(id)) continue;
      seen.add(id);

      final tags = m['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;

      final double? elLat = (m['lat'] as num?)?.toDouble()
          ?? ((m['center'] as Map?))?['lat'] as double?;
      final double? elLng = (m['lon'] as num?)?.toDouble()
          ?? ((m['center'] as Map?))?['lon'] as double?;
      if (elLat == null || elLng == null) continue;

      final amenity = tags['amenity'] as String? ?? '';
      final address = _buildAddress(tags) ?? '';

      // Match with nearest Yelp result within 200 m to get rating
      final yelpMatch = _closestYelp(yelpResults, elLat, elLng, 200);

      results.add(PlaceSearchResult(
        placeId: id,
        name:    name,
        address: address,
        lat:     elLat,
        lng:     elLng,
        rating:  yelpMatch?.rating,
        types:   amenity.isNotEmpty ? [amenity] : [],
      ));
    }
    return results;
  }

  /// Returns the Yelp business closest to [lat]/[lng] within [maxMeters].
  static YelpBusiness? _closestYelp(
    List<YelpBusiness> list, double lat, double lng, double maxMeters) {
    YelpBusiness? best;
    double bestDist = double.infinity;
    for (final b in list) {
      final d = _approxMeters(lat, lng, b.lat, b.lng);
      if (d < bestDist && d <= maxMeters) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  /// Rough metres between two coordinates (good enough for matching).
  static double _approxMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 111320.0;
    final dlat = (lat2 - lat1) * r;
    final dlng = (lng2 - lng1) * r * 0.7;
    return sqrt((dlat * dlat + dlng * dlng).clamp(0.0, double.infinity));
  }

  // ── Text search (Nominatim) ─────────────────────────────────────────────────

  /// Searches for a place by text — replaces Google Places textsearch.
  static Future<PlaceSearchResult?> searchByText(
    String query, {
    double? lat,
    double? lng,
    int radiusMeters = 5000,
  }) async {
    try {
      final params = <String, String>{
        'q':              query,
        'format':         'json',
        'limit':          '1',
        'addressdetails': '1',
        'extratags':      '1',
      };
      if (lat != null && lng != null) {
        // Bias results toward the user's location
        params['viewbox'] = _viewbox(lat, lng, radiusMeters);
        params['bounded'] = '0';
      }
      final uri = Uri.parse('$_nominatim/search').replace(queryParameters: params);
      final res = await http.get(uri, headers: {
        'User-Agent':    _ua,
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      final list = json.decode(res.body) as List?;
      if (list == null || list.isEmpty) return null;

      final r       = list[0] as Map<String, dynamic>;
      final placeId = 'osm/${r['osm_type']}/${r['osm_id']}';
      final addr    = r['address'] as Map<String, dynamic>? ?? {};
      final address = _formatNominatimAddress(addr) ?? r['display_name'] as String? ?? '';

      return PlaceSearchResult(
        placeId: placeId,
        name:    r['name'] as String? ?? query,
        address: address,
        lat:     double.tryParse(r['lat'] as String? ?? '') ?? 0,
        lng:     double.tryParse(r['lon'] as String? ?? '') ?? 0,
        types:   [(r['type'] as String?) ?? ''],
      );
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return null;
    }
  }

  // ── Place details (Overpass) ────────────────────────────────────────────────

  /// Fetches place details — replaces Google Places details endpoint.
  /// Uses OpenMapService.getVenueDetails() which queries Overpass.
  static Future<PlaceDetails?> getDetails(String placeId) async {
    // placeId format: "node/12345" or "way/12345"
    try {
      final parts  = placeId.split('/');
      final osmType = parts.length >= 2 ? parts[0] : 'node';
      final osmId   = parts.length >= 2 ? parts[1] : parts[0];

      final query = '''
[out:json][timeout:15];
$osmType($osmId);
out tags center;
''';
      final res = await http
          .post(Uri.parse(_overpass), body: {'data': query})
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data     = json.decode(res.body) as Map<String, dynamic>;
        final elements = (data['elements'] as List?) ?? [];
        if (elements.isNotEmpty) {
          final el   = elements[0] as Map<String, dynamic>;
          final tags = el['tags'] as Map<String, dynamic>? ?? {};

          final double? elLat = (el['lat'] as num?)?.toDouble()
              ?? ((el['center'] as Map?))?['lat'] as double?;
          final double? elLng = (el['lon'] as num?)?.toDouble()
              ?? ((el['center'] as Map?))?['lon'] as double?;

          String address = _buildAddress(tags) ?? '';
          if (address.isEmpty && elLat != null && elLng != null) {
            address = await OpenMapService.reverseGeocode(elLat, elLng) ?? '';
          }

          final hours = tags['opening_hours'] as String?;
          final weekdayText = hours != null ? [hours] : null;

          final venueName = tags['name'] as String? ?? '';

          // Enrich with Yelp photos + reviews in parallel
          List<String> photoUrls = const [];
          List<PlaceReview> reviews = const [];
          if (elLat != null && elLng != null && venueName.isNotEmpty) {
            final yelpBiz = await YelpService.findByName(venueName, elLat, elLng);
            if (yelpBiz != null) {
              photoUrls = yelpBiz.photoUrls;
              final yelpReviews = await YelpService.getReviews(yelpBiz.yelpId);
              reviews = yelpReviews.map((r) => PlaceReview(
                authorName:  r.authorName,
                rating:      r.rating,
                text:        r.text,
                relativeTime: r.timeCreated,
              )).toList();
            }
          }

          return PlaceDetails(
            placeId:         placeId,
            name:            venueName,
            address:         address,
            lat:             elLat ?? 0,
            lng:             elLng ?? 0,
            openNow:         _isOpen247(hours),
            weekdayText:     weekdayText,
            phoneNumber:     tags['phone'] as String? ?? tags['contact:phone'] as String?,
            website:         tags['website'] as String? ?? tags['contact:website'] as String?,
            photoUrls:       photoUrls,
            reviews:         reviews,
          );
        }
      }
    } catch (e) {
      debugPrint('Overpass details error: $e');
    }
    return null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String? _buildAddress(Map<String, dynamic> tags) {
    final street  = tags['addr:street']      as String?;
    final houseNo = tags['addr:housenumber'] as String?;
    final city    = tags['addr:city']        as String?;
    if (street == null) return null;
    var a = houseNo != null ? '$houseNo $street' : street;
    if (city != null) a += ', $city';
    return a;
  }

  static String? _formatNominatimAddress(Map<String, dynamic> addr) {
    final parts = <String>[
      if (addr['road'] != null)    addr['road']    as String,
      if (addr['suburb'] != null)  addr['suburb']  as String,
      if (addr['city'] != null)    addr['city']    as String
      else if (addr['town'] != null)   addr['town']   as String
      else if (addr['village'] != null) addr['village'] as String,
    ];
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  static bool? _isOpen247(String? hours) {
    if (hours == null) return null;
    return hours.trim() == '24/7' ? true : null;
  }

  /// Creates a viewbox string for Nominatim location bias.
  static String _viewbox(double lat, double lng, int radiusMeters) {
    final delta = radiusMeters / 111320.0;
    final minLat = lat - delta;
    final maxLat = lat + delta;
    final minLng = lng - delta;
    final maxLng = lng + delta;
    return '$minLng,$maxLat,$maxLng,$minLat';
  }
}
