// Free open-map stack — no Google APIs required.
//   Routing  : OSRM  (router.project-osrm.org)
//   Geocoding: Nominatim (nominatim.openstreetmap.org)
//   Details  : Overpass API (overpass-api.de)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenPlaceInfo {
  final String name;
  final String address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String typeLabel;
  final bool? openNow;

  const OpenPlaceInfo({
    required this.name,
    required this.address,
    this.phone,
    this.website,
    this.openingHours,
    required this.typeLabel,
    this.openNow,
  });
}

class OsrmRoute {
  final double durationSeconds;
  final double distanceMeters;
  final String encodedPolyline;

  const OsrmRoute({
    required this.durationSeconds,
    required this.distanceMeters,
    required this.encodedPolyline,
  });

  String get durationText {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class OpenMapService {
  static const _osrm      = 'https://router.project-osrm.org/route/v1';
  static const _nominatim = 'https://nominatim.openstreetmap.org';
  static const _overpass  = 'https://overpass-api.de/api/interpreter';
  static const _ua        = 'NightrideApp/1.0';

  // ── OSRM routing ─────────────────────────────────────────────────────────

  static String _osrmProfile(String mode) {
    switch (mode) {
      case 'walking':   return 'foot';
      case 'bicycling': return 'bike';
      default:          return 'driving'; // driving + transit → driving
    }
  }

  static Future<OsrmRoute?> getRoute(
    double startLat, double startLng,
    double endLat,   double endLng, {
    String mode = 'driving',
  }) async {
    final profile = _osrmProfile(mode);
    // OSRM expects lng,lat order
    final url =
        '$_osrm/$profile/$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=polyline';
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes[0] as Map<String, dynamic>;
      return OsrmRoute(
        durationSeconds: (r['duration'] as num).toDouble(),
        distanceMeters:  (r['distance'] as num).toDouble(),
        encodedPolyline: r['geometry'] as String,
      );
    } catch (e) {
      debugPrint('OSRM error ($mode): $e');
      return null;
    }
  }

  // ── Venue details via Overpass ────────────────────────────────────────────

  static Future<OpenPlaceInfo?> getVenueDetails(
      String name, double lat, double lng) async {
    final safeName = name.replaceAll('"', '').replaceAll('\\', '');
    final query = '''
[out:json][timeout:10];
(
  node["name"~"$safeName",i](around:300,$lat,$lng);
  way["name"~"$safeName",i](around:300,$lat,$lng);
);
out tags;
''';
    try {
      final res = await http
          .post(Uri.parse(_overpass), body: {'data': query})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data   = json.decode(res.body) as Map<String, dynamic>;
        final elements = (data['elements'] as List?) ?? [];
        if (elements.isNotEmpty) {
          final tags = elements[0]['tags'] as Map<String, dynamic>? ?? {};
          final address = _buildAddress(tags) ?? await reverseGeocode(lat, lng) ?? '';
          final amenity = tags['amenity'] as String? ?? '';
          return OpenPlaceInfo(
            name:         tags['name'] as String? ?? name,
            address:      address,
            phone:        tags['phone'] as String? ?? tags['contact:phone'] as String?,
            website:      tags['website'] as String? ?? tags['contact:website'] as String?,
            openingHours: tags['opening_hours'] as String?,
            typeLabel:    amenity.isNotEmpty ? _typeLabel(amenity) : name,
            openNow:      _isOpen24_7(tags['opening_hours'] as String?),
          );
        }
      }
    } catch (e) {
      debugPrint('Overpass details error: $e');
    }
    // Fallback: reverse geocode only
    final address = await reverseGeocode(lat, lng) ?? '';
    return OpenPlaceInfo(name: name, address: address, typeLabel: 'Venue');
  }

  // ── Nominatim reverse geocoding ───────────────────────────────────────────

  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_nominatim/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final res = await http.get(uri, headers: {
        'User-Agent': _ua,
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Build a short address from components rather than the full display_name
      final addr = data['address'] as Map<String, dynamic>? ?? {};
      final parts = <String>[
        if (addr['road'] != null) addr['road'] as String,
        if (addr['suburb'] != null) addr['suburb'] as String,
        if (addr['city'] != null) addr['city'] as String
        else if (addr['town'] != null) addr['town'] as String
        else if (addr['village'] != null) addr['village'] as String,
      ];
      return parts.isNotEmpty ? parts.join(', ') : data['display_name'] as String?;
    } catch (e) {
      debugPrint('Nominatim error: $e');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _buildAddress(Map<String, dynamic> tags) {
    final street  = tags['addr:street']      as String?;
    final houseNo = tags['addr:housenumber'] as String?;
    final city    = tags['addr:city']        as String?;
    if (street == null) return null;
    var a = houseNo != null ? '$street $houseNo' : street;
    if (city != null) a += ', $city';
    return a;
  }

  static String _typeLabel(String amenity) {
    switch (amenity) {
      case 'nightclub':    return 'Night Club';
      case 'bar':          return 'Bar';
      case 'pub':          return 'Pub';
      case 'biergarten':   return 'Beer Garden';
      case 'cocktail_bar': return 'Cocktail Bar';
      case 'wine_bar':     return 'Wine Bar';
      case 'sports_bar':   return 'Sports Bar';
      case 'lounge':       return 'Lounge';
      default:             return amenity.replaceAll('_', ' ');
    }
  }

  static bool? _isOpen24_7(String? hours) {
    if (hours == null) return null;
    if (hours.trim() == '24/7') return true;
    return null; // full OSM parser out of scope
  }
}
