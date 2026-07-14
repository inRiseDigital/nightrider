// Yelp Fusion API — free tier: 500 calls/day, no credit card required.
// Endpoint: https://api.yelp.com/v3/businesses/search
// Provides: ratings, review counts, review snippets, and venue photos.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nightride/core/config/maps_config.dart';

class YelpBusiness {
  final String yelpId;
  final String name;
  final double? rating;
  final int reviewCount;
  final List<String> photoUrls;
  final double lat;
  final double lng;

  const YelpBusiness({
    required this.yelpId,
    required this.name,
    this.rating,
    required this.reviewCount,
    required this.photoUrls,
    required this.lat,
    required this.lng,
  });
}

class YelpReview {
  final String authorName;
  final int rating;
  final String text;
  final String timeCreated;

  const YelpReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.timeCreated,
  });
}

class YelpService {
  static const _base = 'https://api.yelp.com/v3';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $kYelpApiKey',
    'Content-Type':  'application/json',
  };

  static bool get isConfigured => kYelpApiKey.isNotEmpty;

  // ── Nearby search ──────────────────────────────────────────────────────────

  /// Search nearby nightlife venues. Returns up to [limit] results.
  static Future<List<YelpBusiness>> nearbySearch({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
    int limit = 50,
  }) async {
    if (!isConfigured) return [];
    try {
      final uri = Uri.parse('$_base/businesses/search').replace(
        queryParameters: {
          'latitude':   '$lat',
          'longitude':  '$lng',
          'radius':     '${radiusMeters.clamp(0, 40000)}',
          'categories': 'bars,nightlife,danceclubs,lounges,musicvenues,pubs',
          'limit':      '$limit',
          'sort_by':    'rating',
        },
      );
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        debugPrint('Yelp nearby: HTTP ${res.statusCode} — ${res.body}');
        return [];
      }
      final data       = json.decode(res.body) as Map<String, dynamic>;
      final businesses = (data['businesses'] as List?) ?? [];

      return businesses.map<YelpBusiness>((b) {
        final m        = b as Map<String, dynamic>;
        final coords   = m['coordinates'] as Map<String, dynamic>? ?? {};
        final photos   = (m['photos'] as List?)?.cast<String>() ?? [];
        final imgUrl   = m['image_url'] as String?;
        final allPhotos = [
          if (imgUrl != null && imgUrl.isNotEmpty) imgUrl,
          ...photos,
        ];
        return YelpBusiness(
          yelpId:     m['id']           as String? ?? '',
          name:       m['name']         as String? ?? '',
          rating:     (m['rating']      as num?)?.toDouble(),
          reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
          photoUrls:  allPhotos,
          lat:        (coords['latitude']  as num?)?.toDouble() ?? lat,
          lng:        (coords['longitude'] as num?)?.toDouble() ?? lng,
        );
      }).toList();
    } catch (e) {
      debugPrint('Yelp nearby error: $e');
      return [];
    }
  }

  // ── Match by name + location ───────────────────────────────────────────────

  /// Find the best Yelp match for a venue by name near [lat]/[lng].
  static Future<YelpBusiness?> findByName(
    String name,
    double lat,
    double lng,
  ) async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse('$_base/businesses/search').replace(
        queryParameters: {
          'term':      name,
          'latitude':  '$lat',
          'longitude': '$lng',
          'radius':    '200',
          'limit':     '3',
        },
      );
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;
      final data       = json.decode(res.body) as Map<String, dynamic>;
      final businesses = (data['businesses'] as List?) ?? [];
      if (businesses.isEmpty) return null;

      final m        = businesses[0] as Map<String, dynamic>;
      final coords   = m['coordinates'] as Map<String, dynamic>? ?? {};
      final imgUrl   = m['image_url'] as String?;
      return YelpBusiness(
        yelpId:      m['id']           as String? ?? '',
        name:        m['name']         as String? ?? name,
        rating:      (m['rating']      as num?)?.toDouble(),
        reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
        photoUrls:   imgUrl != null ? [imgUrl] : [],
        lat:         (coords['latitude']  as num?)?.toDouble() ?? lat,
        lng:         (coords['longitude'] as num?)?.toDouble() ?? lng,
      );
    } catch (e) {
      debugPrint('Yelp findByName error: $e');
      return null;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  /// Fetch up to 3 review snippets for a Yelp business ID (free tier limit).
  static Future<List<YelpReview>> getReviews(String yelpId) async {
    if (!isConfigured || yelpId.isEmpty) return [];
    try {
      final uri = Uri.parse('$_base/businesses/$yelpId/reviews');
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        debugPrint('Yelp reviews: HTTP ${res.statusCode}');
        return [];
      }
      final data    = json.decode(res.body) as Map<String, dynamic>;
      final reviews = (data['reviews'] as List?) ?? [];

      return reviews.map<YelpReview>((r) {
        final m    = r as Map<String, dynamic>;
        final user = m['user'] as Map<String, dynamic>? ?? {};
        return YelpReview(
          authorName:  user['name']         as String? ?? 'Anonymous',
          rating:      (m['rating']         as num?)?.toInt() ?? 0,
          text:        m['text']            as String? ?? '',
          timeCreated: m['time_created']    as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Yelp reviews error: $e');
      return [];
    }
  }
}
