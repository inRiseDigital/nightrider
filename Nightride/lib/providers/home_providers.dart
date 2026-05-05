// lib/features/home/presentation/providers/home_providers.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

final featuredCarouselIndexProvider =
    NotifierProvider<FeaturedCarouselIndexNotifier, int>(
      FeaturedCarouselIndexNotifier.new,
    );

class FeaturedCarouselIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

/// Like state per event id
final trendingLikeProvider = StateProvider.family<bool, String>(
  (ref, id) => false,
);

/// Dark mode UI toggle (UI only)
final homeDarkToggleProvider = StateProvider<bool>((ref) => true);

/// Accent color options shown in Appearance settings
const List<Color> kAccentColors = [
  Color(0xFF9F7AEA), // purple (default)
  Color(0xFFED64A6), // pink
  Color(0xFF448AFF), // blue
  Color(0xFF64FFDA), // teal
  Color(0xFFFFAB40), // orange
];

/// Index into kAccentColors for the selected accent
final accentColorIndexProvider = StateProvider<int>((ref) => 0);

/// Language UI selection (UI only)
enum HomeLanguage { en, de, fr, es, it, nl, sv, pt, ja, ar, ko, zh }

final homeLanguageProvider = StateProvider<HomeLanguage>(
  (ref) => HomeLanguage.en,
);

String langLabel(HomeLanguage lang) {
  const labels = {
    HomeLanguage.en: 'EN', HomeLanguage.de: 'DE', HomeLanguage.fr: 'FR',
    HomeLanguage.es: 'ES', HomeLanguage.it: 'IT', HomeLanguage.nl: 'NL',
    HomeLanguage.sv: 'SV', HomeLanguage.pt: 'PT', HomeLanguage.ja: 'JP',
    HomeLanguage.ar: 'AR', HomeLanguage.ko: 'KR', HomeLanguage.zh: 'ZH',
  };
  return labels[lang] ?? 'EN';
}

String langName(HomeLanguage lang) {
  const names = {
    HomeLanguage.en: 'English',    HomeLanguage.de: 'Deutsch',
    HomeLanguage.fr: 'Français',   HomeLanguage.es: 'Español',
    HomeLanguage.it: 'Italiano',   HomeLanguage.nl: 'Nederlands',
    HomeLanguage.sv: 'Svenska',    HomeLanguage.pt: 'Português',
    HomeLanguage.ja: '日本語',      HomeLanguage.ar: 'العربية',
    HomeLanguage.ko: '한국어',      HomeLanguage.zh: '中文',
  };
  return names[lang] ?? 'English';
}

// ── Firestore helpers ────────────────────────────────────────────────────────

String _fmtDate(String date) {
  if (date.length < 10) return date;
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  try {
    final parts = date.substring(0, 10).split('-');
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return '${months[m]} $d';
  } catch (_) {
    return date;
  }
}

FeaturedEvent _toFeatured(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  final venue = d['venue_name'] as String? ?? '';
  final city = d['city'] as String? ?? '';
  final sub = [venue, city].where((s) => s.isNotEmpty).join(' · ');
  return FeaturedEvent(
    id: doc.id,
    title: d['name'] as String? ?? '',
    subtitle: sub.isNotEmpty ? sub : 'Music Event',
    badgeText: d['genre'] as String? ?? 'Music',
    dateText: _fmtDate(d['date'] as String? ?? ''),
    imageUrl: d['cover_image'] as String? ?? '',
    genre: d['genre'] as String? ?? '',
    countryCode: d['country_code'] as String? ?? '',
  );
}

final eventDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  ref.keepAlive();
  if (id.isEmpty) return null;
  final doc =
      await FirebaseFirestore.instance.collection('events').doc(id).get();
  return doc.data();
});

TrendingEvent _toTrending(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  final city = d['city'] as String? ?? '';
  final country = d['country'] as String? ?? '';
  final loc = [city, country].where((s) => s.isNotEmpty).join(', ');
  return TrendingEvent(
    id: doc.id,
    title: d['name'] as String? ?? '',
    locationText: loc.isNotEmpty ? loc : 'Unknown',
    dateText: _fmtDate(d['date'] as String? ?? ''),
    categoryTag: (d['genre'] as String? ?? 'Music').toUpperCase(),
    imageUrl: d['cover_image'] as String? ?? '',
    interestedCountText: d['price_hint'] as String? ?? 'Tickets',
    countryCode: d['country_code'] as String? ?? '',
    language: d['language'] as String? ?? '',
  );
}

String get _todayIso {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

bool _isUpcoming(Map<String, dynamic> d) {
  final date = d['date'] as String? ?? '';
  // ISO format dates (YYYY-MM-DD) can be compared as strings
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(date)) return date.compareTo(_todayIso) >= 0;
  // Organizer text dates (e.g. "May 10, 2026") — always show
  return true;
}

bool _isVisible(Map<String, dynamic> d) {
  final status = d['status'] as String?;
  // Seeded events have no status — always show; organizer events must be published
  return status == null || status == 'published';
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortUpcomingFirst(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final upcoming = docs.where((d) => _isUpcoming(d.data())).toList()
    ..sort((a, b) => ((a.data()['date'] as String?) ?? '')
        .compareTo((b.data()['date'] as String?) ?? ''));
  final past = docs.where((d) => !_isUpcoming(d.data())).toList()
    ..sort((a, b) => ((b.data()['date'] as String?) ?? '')
        .compareTo((a.data()['date'] as String?) ?? ''));
  return [...upcoming, ...past];
}

final featuredEventsProvider = StreamProvider<List<FeaturedEvent>>((ref) {
  final country = ref.watch(selectedCountryProvider);
  Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('events');
  if (country != 'ALL') q = q.where('country_code', isEqualTo: country);
  return q.limit(country == 'ALL' ? 60 : 200).snapshots().map((snap) {
    final sorted = _sortUpcomingFirst(
      snap.docs.where((d) => _isVisible(d.data())).toList(),
    );
    return sorted.map(_toFeatured).take(10).toList();
  });
});

final trendingEventsProvider = StreamProvider<List<TrendingEvent>>((ref) {
  final country = ref.watch(selectedCountryProvider);
  Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('events');
  if (country != 'ALL') q = q.where('country_code', isEqualTo: country);
  return q.limit(country == 'ALL' ? 100 : 300).snapshots().map((snap) {
    final sorted = _sortUpcomingFirst(
      snap.docs.where((d) => _isVisible(d.data())).toList(),
    );
    return sorted.map(_toTrending).take(20).toList();
  });
});

MapBottomCardData _toMapCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data();
  final city = d['city'] as String? ?? '';
  final country = d['country'] as String? ?? '';
  final genre = d['genre'] as String? ?? 'Music';
  return MapBottomCardData(
    id: doc.id,
    title: d['name'] as String? ?? '',
    subtitle: genre,
    locationLine: [city, country].where((s) => s.isNotEmpty).join(', '),
    imageUrl: d['cover_image'] as String? ?? '',
    tags: [genre],
    distanceKm: 0.0,
    openText: _fmtDate(d['date'] as String? ?? ''),
    priceHint: d['price_hint'] as String? ?? 'Tickets',
    lat: (d['lat'] as num? ?? 0).toDouble(),
    lng: (d['lng'] as num? ?? 0).toDouble(),
  );
}

final mapEventsProvider = StreamProvider<List<MapBottomCardData>>((ref) {
  return FirebaseFirestore.instance
      .collection('events')
      .limit(300)
      .snapshots()
      .map((snap) {
        final sorted = _sortUpcomingFirst(
          snap.docs.where((d) => _isVisible(d.data())).toList(),
        );
        return sorted.map(_toMapCard).toList();
      });
});

// ── Location & distance helpers ──────────────────────────────────────────────

final userLocationProvider = StreamProvider<geo.Position?>((ref) async* {
  if (kIsWeb) { yield null; return; }
  final status = await Permission.locationWhenInUse.request();
  if (!status.isGranted) { yield null; return; }
  try {
    final initial = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.medium),
    );
    yield initial;
    yield* geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.medium,
        distanceFilter: 100,
      ),
    );
  } catch (_) {
    yield null;
  }
});

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String formatDistance(double km) {
  if (km <= 0) return '—';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

String formatTravel(double km) {
  if (km <= 0) return '';
  if (km < 5) {
    final mins = (km / 5 * 60).round();
    if (mins <= 45) return '~$mins min walk';
  }
  final mins = (km / 60 * 60).round();
  return '~$mins min drive';
}

// ── Category & country filters ───────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String>((ref) => 'ALL');
final selectedCountryProvider = StateProvider<String>((ref) => 'ALL');

/// Matches a Firestore genre string against a UI category label.
/// Works for both home categories (CLUB, DJ, TECHNO, RAVE, EDM, HOUSE, LIVE)
/// and map categories (DJ, EDM, Techno, Hip-Hop, J-Pop, House, Trap, R&B).
bool matchesGenre(String genre, String label) {
  if (label.toUpperCase() == 'ALL') return true;
  final t = genre.toUpperCase();
  final l = label.toUpperCase();
  switch (l) {
    case 'EDM':     return t.contains('EDM') || t.contains('ELECTRONIC') || t.contains('DANCE') || t.contains('TRANCE') || t.contains('PROGRESSIVE');
    case 'TECHNO':  return t.contains('TECHNO') || t.contains('INDUSTRIAL');
    case 'RAVE':    return t.contains('RAVE') || t.contains('ELECTRONIC') || t.contains('TECHNO');
    case 'HOUSE':   return t.contains('HOUSE');
    case 'DJ':      return t.contains('DJ') || t.contains('ELECTRONIC') || t.contains('DANCE');
    case 'CLUB':    return t.contains('CLUB') || t.contains('ELECTRONIC') || t.contains('DANCE') || t.contains('POP') || t.contains('LATIN');
    case 'LIVE':    return true;
    case 'HIP-HOP': return t.contains('HIP') || t.contains('RAP') || t.contains('HIP-HOP');
    case 'TRAP':    return t.contains('TRAP') || t.contains('HIP') || t.contains('RAP');
    case 'R&B':     return t.contains('R&B') || t.contains('RNB') || t.contains('SOUL') || t.contains('RHYTHM');
    case 'J-POP':   return t.contains('J-POP') || t.contains('JPOP') || t.contains('JAPAN') || t.contains('ANIME');
    default:        return t.contains(l);
  }
}

bool _matchesCategory(String tag, String selected) => matchesGenre(tag, selected);

final availableCountriesProvider = StreamProvider<List<String>>((ref) {
  ref.keepAlive();
  const pinned = {'JP', 'LK'};
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(pinned.toList()..sort());
  return FirebaseFirestore.instance
      .collection('events')
      .limit(500)
      .snapshots()
      .map((snap) {
        final seen = <String>{...pinned};
        final fromFirestore = snap.docs
            .map((d) => (d.data()['country_code'] as String? ?? '').toUpperCase())
            .where((c) => c.isNotEmpty && seen.add(c))
            .toList();
        return [...pinned, ...fromFirestore]..sort();
      });
});

final filteredTrendingProvider = Provider<List<TrendingEvent>>((ref) {
  final events = ref.watch(trendingEventsProvider).asData?.value;
  if (events == null) return [];
  final cat     = ref.watch(selectedCategoryProvider);
  final country = ref.watch(selectedCountryProvider);
  if (cat == 'ALL' && country == 'ALL') return events;
  return events.where((e) {
    final catOk     = cat     == 'ALL' || _matchesCategory(e.categoryTag, cat);
    final countryOk = country == 'ALL' || e.countryCode.toUpperCase() == country.toUpperCase();
    return catOk && countryOk;
  }).toList();
});

final filteredFeaturedProvider = Provider<List<FeaturedEvent>>((ref) {
  final events = ref.watch(featuredEventsProvider).asData?.value;
  if (events == null) return [];
  final cat     = ref.watch(selectedCategoryProvider);
  final country = ref.watch(selectedCountryProvider);
  if (cat == 'ALL' && country == 'ALL') return events;
  return events.where((e) {
    final catOk     = cat     == 'ALL' || _matchesCategory(e.genre.toUpperCase(), cat);
    final countryOk = country == 'ALL' || e.countryCode.toUpperCase() == country.toUpperCase();
    return catOk && countryOk;
  }).toList();
});
