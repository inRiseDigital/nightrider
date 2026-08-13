// lib/features/home/presentation/providers/home_providers.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/domain/event.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/firestore_service.dart';
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

/// Dark mode UI toggle (UI only)
final homeDarkToggleProvider = StateProvider<bool>((ref) => true);

/// Accent color options shown in Appearance settings — Night Rite brand palette
const List<Color> kAccentColors = [
  Color(0xFFdbdf57), // neon lime (brand default)
  Color(0xFFf15991), // hot pink
  Color(0xFF2ec4b6), // teal
  Color(0xFF448AFF), // electric blue
  Color(0xFFFFD700), // gold
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
//
// All list queries below run server-side against the composite indexes in
// nightride-webpanel/firestore.indexes.json — see FirestoreService for which
// index backs each one. Client-side date-string comparisons and status
// filtering (the old `_isUpcoming`/`_isVisible`/`_sortUpcomingFirst` trio)
// are gone: `startAt` is a real Timestamp now, so `where(startAt >= now)
// orderBy(startAt)` does the range query the old string comparison only
// pretended to do, and `status` is queried directly instead of filtered
// client-side after the fact.

String _fmtTimestamp(Timestamp? ts) {
  if (ts == null) return '';
  final dt = ts.toDate();
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month]} ${dt.day}';
}

FeaturedEvent _toFeatured(Event e) {
  final sub = [e.venueName, e.city].where((s) => s.isNotEmpty).join(' · ');
  return FeaturedEvent(
    id: e.id,
    title: e.name,
    subtitle: sub.isNotEmpty ? sub : 'Music Event',
    badgeText: e.genre.isNotEmpty ? e.genre : 'Music',
    dateText: _fmtTimestamp(e.startAt),
    imageUrl: e.coverImage,
    genre: e.genre,
    countryCode: e.countryCode,
  );
}

// NOTE: event_detail_page.dart no longer uses this — it defines its own
// FutureProvider.family<Event?, String> and reads the typed Event directly,
// now that the Event.toLegacyDetailMap() shim this provider used to call has
// been deleted. Left in place only because nothing else in this file's
// public surface depends on removing it and no other caller was found.
final eventDetailProvider =
    FutureProvider.family<Event?, String>((ref, id) async {
  ref.keepAlive();
  if (id.isEmpty) return null;
  return firestoreService.getEvent(id);
});

TrendingEvent _toTrending(Event e) {
  final loc = [e.city, e.countryCode].where((s) => s.isNotEmpty).join(', ');
  return TrendingEvent(
    id: e.id,
    title: e.name,
    locationText: loc.isNotEmpty ? loc : 'Unknown',
    dateText: _fmtTimestamp(e.startAt),
    categoryTag: (e.genre.isNotEmpty ? e.genre : 'Music').toUpperCase(),
    imageUrl: e.coverImage,
    // The old code stuffed the free-text `price_hint` into this field, so
    // sorting by "interested count" (lib/pages/category_detail_page.dart)
    // was actually sorting by whatever digits happened to appear in the
    // price string. `interestedCount` is real now.
    interestedCountText: '+${e.interestedCount}',
    countryCode: e.countryCode,
    language: e.language,
    rawDate: e.isoDate,
  );
}

/// Featured carousel: upcoming published events, soonest first.
/// Query: status=='published' && startAt>=now, orderBy startAt asc, limit 10.
/// Index: events(status ASC, startAt ASC) / events(status ASC, countryCode ASC, startAt ASC)
final featuredEventsProvider = StreamProvider<List<FeaturedEvent>>((ref) {
  final country = ref.watch(selectedCountryProvider);
  final stream = country == 'ALL'
      ? firestoreService.streamUpcomingEvents(limit: 10)
      : firestoreService.streamUpcomingEventsByCountry(country, limit: 10);
  return stream.map((events) => events.map(_toFeatured).toList());
});

/// Trending: top N published events by interestedCount, globally — country
/// narrowing happens client-side in [filteredTrendingProvider] on top of this.
/// Query: status=='published', orderBy interestedCount desc, limit 20.
/// Index: events(status ASC, interestedCount DESC)
final trendingEventsProvider = StreamProvider<List<TrendingEvent>>((ref) {
  return firestoreService
      .streamTrendingEvents(limit: 20)
      .map((events) => events.map(_toTrending).toList());
});

MapBottomCardData _toMapCard(Event e) {
  final genre = e.genre.isNotEmpty ? e.genre : 'Music';
  return MapBottomCardData(
    id: e.id,
    title: e.name,
    subtitle: genre,
    locationLine: [e.city, e.countryCode].where((s) => s.isNotEmpty).join(', '),
    imageUrl: e.coverImage,
    tags: [genre],
    distanceKm: 0.0,
    openText: _fmtTimestamp(e.startAt),
    priceHint: e.price.hintText,
    lat: e.geo?.latitude ?? 0,
    lng: e.geo?.longitude ?? 0,
  );
}

/// Map pins: upcoming published events.
/// Query: status=='published' && startAt>=now, orderBy startAt asc, limit 300.
/// Index: events(status ASC, startAt ASC)
final mapEventsProvider = StreamProvider<List<MapBottomCardData>>((ref) {
  return firestoreService
      .streamUpcomingEvents(limit: 300)
      .map((events) => events.map(_toMapCard).toList());
});

// ── Location & distance helpers ──────────────────────────────────────────────

final userLocationProvider = StreamProvider<geo.Position?>((ref) async* {
  if (kIsWeb) { yield null; return; }
  final status = await Permission.locationWhenInUse.request();
  if (!status.isGranted) { yield null; return; }

  // 1. Try last known position instantly (works on emulator if location was set)
  try {
    final last = await geo.Geolocator.getLastKnownPosition();
    if (last != null) yield last;
  } catch (_) {}

  // 2. Try a fresh fix — low accuracy + 15s timeout so emulator doesn't hang
  try {
    final fresh = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.low,
      ),
    ).timeout(const Duration(seconds: 15));
    yield fresh;
  } catch (_) {}

  // 3. Stream ongoing updates
  try {
    yield* geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.medium,
        distanceFilter: 100,
      ),
    );
  } catch (_) {}
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
  if (km > 1500) {
    // Too far to drive — show flight estimate (~900 km/h cruise speed)
    final flightHours = (km / 900).ceil();
    return '~${flightHours}h flight';
  }
  // Drive time: 40 km/h city, 70 km/h mixed, 100 km/h highway
  final speedKmh = km < 50 ? 40.0 : (km < 200 ? 70.0 : 100.0);
  final totalMins = (km / speedKmh * 60).round();
  if (totalMins >= 120) {
    final hours = (totalMins / 60).round();
    return '~${hours}h drive';
  }
  return '~$totalMins min drive';
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

/// Distinct country codes among published events, for the country filter row.
/// Query: status=='published', limit 500. Single equality filter — no
/// composite index required.
final availableCountriesProvider = StreamProvider<List<String>>((ref) {
  ref.keepAlive();
  const pinned = {'JP', 'LK'};
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(pinned.toList()..sort());
  return firestoreService.streamPublishedCountryCodes(limit: 500).map((codes) {
    final seen = <String>{...pinned, ...codes};
    return seen.toList()..sort();
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
