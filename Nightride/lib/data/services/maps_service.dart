import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceResult {
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String? placeId;
  final double? rating;
  final bool? openNow;

  const PlaceResult({
    required this.name,
    this.address,
    this.lat,
    this.lng,
    this.placeId,
    this.rating,
    this.openNow,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) => PlaceResult(
        name: json['name'] as String,
        address: json['address'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        placeId: json['place_id'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        openNow: json['open_now'] as bool?,
      );
}

class TravelInfo {
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final String mode;
  final String navigationUrl;

  const TravelInfo({
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.mode,
    required this.navigationUrl,
  });

  factory TravelInfo.fromJson(Map<String, dynamic> json) => TravelInfo(
        distanceText: json['distance_text'] as String,
        distanceMeters: json['distance_meters'] as int,
        durationText: json['duration_text'] as String,
        durationSeconds: json['duration_seconds'] as int,
        mode: json['mode'] as String,
        navigationUrl: json['navigation_url'] as String,
      );
}

class MapsService {
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://5r5cqck5-8000.asse.devtunnels.ms',
  );

  Future<List<PlaceResult>> searchPlaces(
    String query,
    double lat,
    double lng, {
    int radius = 5000,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/maps/place/search').replace(
        queryParameters: {
          'query': query,
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<TravelInfo?> getTravelInfo({
    required double userLat,
    required double userLng,
    required double destLat,
    required double destLng,
    required String destName,
    String mode = 'driving',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/maps/travel').replace(
        queryParameters: {
          'user_lat': userLat.toString(),
          'user_lng': userLng.toString(),
          'dest_lat': destLat.toString(),
          'dest_lng': destLng.toString(),
          'dest_name': destName,
          'mode': mode,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return TravelInfo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
