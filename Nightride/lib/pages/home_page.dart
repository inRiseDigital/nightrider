// lib/pages/home_page.dart
//
// Retro nightlife poster home screen.
// Palette: black=#070707, cream=#F3EAD6, neonLime=#DFFF2F,
//          hotPink=#FF3D73, teal=#62D6C8, darkGray=#151515, borderGray=#333333

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/components/home_drawer.dart';
import 'package:nightride/components/home_featured_carousel.dart';
import 'package:nightride/pages/category_detail_page.dart';
import 'package:nightride/components/home_location_row.dart';
import 'package:nightride/components/home_section_title.dart';
import 'package:nightride/components/home_top_bar.dart';
import 'package:nightride/components/home_ui_bits.dart';
import 'package:nightride/components/layout/responsive_layout.dart';
import 'package:nightride/components/nightrite_refresh.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/services/overpass_service.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/pages/clubs_page.dart';
import 'package:nightride/pages/events_grid_page.dart';
import 'package:nightride/pages/explore_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/providers/live_hub_providers.dart';
import 'package:nightride/providers/nearby_venues_provider.dart';
import 'package:nightride/providers/profile_providers.dart';

// ── App title constant (keep for backward-compat references) ──────────────────
const kAppTitle = 'NIGHT RITE';

// ── Home page ─────────────────────────────────────────────────────────────────

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).data;
    final username = profile.displayName.isNotEmpty
        ? profile.displayName
        : profile.username.isNotEmpty
            ? profile.username
            : '';

    final locationLabel = profile.city.isNotEmpty
        ? profile.city
        : profile.countryCode.isNotEmpty
            ? profile.countryCode
            : '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const HomeDrawer(),
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: const HomeSmoothScrollBehavior(),
          child: NightRiteRefresh(
            onRefresh: () async {
              ref.invalidate(featuredEventsProvider);
              ref.invalidate(trendingEventsProvider);
              ref.invalidate(clubUpdatesProvider);
              ref.invalidate(nearbyVenuesProvider);
              await Future<void>.delayed(
                  const Duration(milliseconds: 600));
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                top: AppDimensions.pagePaddingTop(context),
                bottom: AppResponsive.bottomNavHeight(context) +
                    MediaQuery.viewPaddingOf(context).bottom +
                    AppResponsive.gap(context, 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar — hamburger + bell ──────────────────────────
                  const ResponsivePagePadding(
                    child: HomeTopBar(),
                  ),
                  SizedBox(
                      height: AppResponsive.gap(context, 18)),

                  // ── Hero: artwork + greeting + AI Plan My Night stripe ──
                  // The stripe is part of the hero rather than a sibling below
                  // it, so it can sit in the artwork's empty lower-left pocket
                  // with the vinyl mascot standing to its right.
                  ResponsivePagePadding(
                    child: _HeroBubble(
                      displayName: username,
                      onAiPlanTap: () =>
                          ref.read(appNavProvider.notifier).setIndex(2),
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 18)),

                  // ── LIVE RIGHT NOW stat cards ───────────────────────────
                  ResponsivePagePadding(
                    child: HomeSectionTitle(
                      title: 'LIVE RIGHT NOW',
                      accentColor: AppTheme.cream,
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ClubsPage()),
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 14)),
                  ResponsivePagePadding(
                    child: const _LiveNowStatCards(),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 28)),

                  // ── EXPLORE category grid ───────────────────────────────
                  ResponsivePagePadding(
                    child: HomeSectionTitle(
                      title: 'EXPLORE',
                      accentColor: AppTheme.cream,
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ExplorePage()),
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 14)),
                  ResponsivePagePadding(
                    child: const _ExploreTileRow(),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 28)),

                  // ── TRENDING NEAR YOU — featured carousel ───────────────
                  // The old one-at-a-time trending list was folded into this
                  // carousel instead of showing as a separate section.
                  ResponsivePagePadding(
                    child: HomeSectionTitle(
                      title: 'TRENDING NEAR YOU',
                      accentColor: AppTheme.cream,
                      onViewAll: () {},
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 14)),
                  const HomeFeaturedCarousel(),
                  SizedBox(height: AppResponsive.gap(context, 28)),

                  // ── Location row (conditional) ──────────────────────────
                  if (locationLabel.isNotEmpty) ...[
                    ResponsivePagePadding(
                      child: HomeLocationRow(country: locationLabel),
                    ),
                    SizedBox(height: AppResponsive.gap(context, 20)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────
//
// The illustrated hero artwork — a single asset that bakes in the speech bubble,
// "WHERE ARE WE GOING TONIGHT?" headline, hanging disco ball and vinyl mascot
// that used to be drawn widget-by-widget — with the personalised greeting laid
// over it, riding the bubble's top border line.

class _HeroBubble extends StatelessWidget {
  const _HeroBubble({required this.displayName, required this.onAiPlanTap});
  final String displayName;
  final VoidCallback onAiPlanTap;

  // The overlays are anchored to features of the artwork, so they're expressed
  // as fractions of the asset and every one of them is tied to its real aspect
  // ratio. IF THE ASSET IS RE-CROPPED, THESE MUST BE RE-MEASURED — a crop moves
  // the artwork inside its own canvas, so the fractions below go stale even
  // though the picture looks the same.
  //
  // Current asset: 2048x1640.
  static const _assetAspect = 2048 / 1640;

  // Greeting. The bubble's hand-drawn top border runs from (400, 166) to
  // (1200, 74), rising left-to-right at 6.56°; the greeting matches that slope
  // and is anchored just above the line.
  static const _borderAngle = -0.1145; // radians ≈ -6.56°
  static const _greetingLeft = 0.145; // of width; clear of the rounded corner
  static const _greetingBottom = 0.889; // of height; rests on the border line

  // Stripe. The artwork leaves a pocket in its lower-left: the bubble's tail
  // bottoms out at y 0.710 and nothing else occupies x < 0.62 below it, while
  // the mascot's body starts at x 0.687 and its feet land at y 0.924. The
  // stripe drops into that pocket, so the mascot stands to its right.
  static const _stripeBandTop = 0.716; // of height; just clear of the tail
  static const _stripeBandBottom = 0.05; // of height; up from the lower edge
  static const _stripeRightInset = 0.38; // of width; ~0.07 clear of the mascot

  @override
  Widget build(BuildContext context) {
    // First name only — a full "HEY YOMITH RATHNYAKA!" overruns the border line.
    final firstName = displayName.trim().split(RegExp(r'\s+')).first;
    final greeting = firstName.isEmpty ? 'THERE' : firstName.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Size the box to the asset's own ratio. Forcing a square here would
          // letterbox a non-square asset under BoxFit.contain — the artwork
          // would shrink inside an unchanged footprint and drift away from the
          // anchors below, which is exactly what a crop must not cause.
          final w = constraints.maxWidth;
          final h = w / _assetAspect;
          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                // The asset has a transparent backdrop, so it composites straight
                // onto the page black with no visible rectangle edge — keep it
                // that way. A flattened export on pure black would show a seam
                // against the #070707 background.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hero_tonight.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Where are we going tonight?',
                  ),
                ),
                Positioned(
                  left: w * _greetingLeft,
                  bottom: h * _greetingBottom,
                  child: Transform.rotate(
                    angle: _borderAngle,
                    // Pivot on the anchored corner so the text pivots along the
                    // border line instead of drifting off it.
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * 0.62),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'HEY $greeting!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.anton(
                                fontSize: AppResponsive.font(context, 21)
                                    .clamp(18.0, 24.0),
                                fontWeight: FontWeight.w400,
                                color: AppTheme.neonLime,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Transform.rotate(
                            angle: 0.35,
                            child: Icon(Icons.bolt_rounded,
                                color: AppTheme.hotPink, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Banding the stripe rather than pinning it to a fixed offset
                // lets it centre itself in the pocket whatever height its own
                // padding and text scale work out to.
                Positioned(
                  left: 0,
                  right: w * _stripeRightInset,
                  top: h * _stripeBandTop,
                  bottom: h * _stripeBandBottom,
                  child: Align(
                    alignment: Alignment.center,
                    child: _AiPlanStripe(onTap: onAiPlanTap),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── AI Plan My Night — highlighter stripe CTA ────────────────────────────────

class _AiPlanStripe extends StatelessWidget {
  const _AiPlanStripe({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: -0.015,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.neonLime,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonLime.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✦',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI PLAN MY NIGHT',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 16).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EXPLORE — colored icon tile row ──────────────────────────────────────────
class _ExploreCat {
  final String label;
  final String category;
  final IconData icon;
  final Color bg;
  const _ExploreCat(this.label, this.category, this.icon, this.bg);
}

const _kExploreCats = <_ExploreCat>[
  _ExploreCat('TECHNO',     'TECHNO', Icons.language,               AppTheme.teal),
  _ExploreCat('HOUSE',      'HOUSE',  Icons.sentiment_satisfied_alt, AppTheme.neonLime),
  _ExploreCat('LATIN',      'EDM',    Icons.park,                    AppTheme.teal),
  _ExploreCat('LIVE MUSIC', 'LIVE',   Icons.bolt,                    AppTheme.hotPink),
];

class _ExploreTileRow extends StatelessWidget {
  const _ExploreTileRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _kExploreCats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ExploreTile(cat: _kExploreCats[i])),
        ],
      ],
    );
  }
}

class _ExploreTile extends StatefulWidget {
  const _ExploreTile({required this.cat});
  final _ExploreCat cat;

  @override
  State<_ExploreTile> createState() => _ExploreTileState();
}

class _ExploreTileState extends State<_ExploreTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    // All accent tiles (lime/teal/pink) are bright enough for black text.
    const fg = Colors.black;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CategoryDetailPage(category: cat.category),
        ));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cat.bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: cat.bg.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cat.icon, color: fg, size: 28),
              const SizedBox(height: 8),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: 10,
                  color: fg,
                  letterSpacing: 0.8,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LIVE RIGHT NOW — 3 stat cards ────────────────────────────────────────────

class _LiveNowStatCards extends ConsumerWidget {
  const _LiveNowStatCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Events count — use trendingEventsProvider length (real Firestore data)
    final trendingAsync = ref.watch(trendingEventsProvider);
    final eventsCount =
        trendingAsync.asData?.value.length;

    // Clubs count — from clubUpdatesProvider (Firestore live hub)
    final clubsAsync = ref.watch(clubUpdatesProvider);
    final clubsList = clubsAsync.asData?.value ?? [];
    final openClubs = clubsList
        .where((c) => c.status == ClubStatus.open)
        .length;

    // Bars count — from nearbyVenuesProvider filtered by bar type
    // TODO: connect to real venue count API — currently derived from nearby OSM data
    final venuesAsync = ref.watch(nearbyVenuesProvider);
    final barCount = venuesAsync.asData?.value
        .where((v) =>
            v.type == 'bar' ||
            v.type == 'pub' ||
            v.type == 'cocktail_bar' ||
            v.type == 'wine_bar')
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'CLUBS',
            value: openClubs > 0
                ? '$openClubs'
                : clubsList.isNotEmpty
                    ? '${clubsList.length}'
                    : '--',
            // TODO: connect to real club count API when available
            accent: AppTheme.neonLime,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClubsPage()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'BARS',
            value: barCount != null && barCount > 0
                ? '$barCount'
                : '--',
            // TODO: connect to real bar count API when available
            accent: AppTheme.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _BarsListPage()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'EVENTS',
            value: eventsCount != null ? '$eventsCount' : '--',
            accent: AppTheme.hotPink,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventsGridPage()),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.anton(
                fontSize:
                    AppResponsive.font(context, 28).clamp(22.0, 34.0),
                fontWeight: FontWeight.w400,
                color: Colors.black,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:
                    AppResponsive.font(context, 10).clamp(9.0, 11.0),
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.60),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bars list page ────────────────────────────────────────────────────────────
//
// "BARS" stat card destination — no dedicated bars page exists yet, so this
// reuses the nearby-venue list/card/sheet already built for the map tab,
// filtered down to bar-type venues.

class _BarsListPage extends ConsumerWidget {
  const _BarsListPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(nearbyVenuesProvider);
    final userPos = ref.watch(userLocationProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppTheme.cream),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BARS',
          style: GoogleFonts.anton(
            color: AppTheme.cream,
            fontSize: AppResponsive.font(context, 20).clamp(16.0, 24.0),
            letterSpacing: 2,
          ),
        ),
      ),
      body: venuesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.teal),
        ),
        error: (_, __) => Center(
          child: Text(
            'Could not load bars nearby',
            style: TextStyle(color: AppTheme.cream.withValues(alpha: 0.5)),
          ),
        ),
        data: (venues) {
          final bars = venues
              .where((v) =>
                  v.type == 'bar' ||
                  v.type == 'pub' ||
                  v.type == 'cocktail_bar' ||
                  v.type == 'wine_bar')
              .toList();

          if (bars.isEmpty) {
            return Center(
              child: Text(
                'NO BARS NEARBY',
                style: GoogleFonts.anton(
                  color: AppTheme.cream.withValues(alpha: 0.4),
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final venue = bars[i];
              final distanceKm = userPos != null
                  ? haversineKm(
                      userPos.latitude, userPos.longitude, venue.lat, venue.lng)
                  : 0.0;
              void openDirections() {
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=${venue.lat},${venue.lng}';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }

              return _NearbyVenueListCard(
                venue: venue,
                distanceKm: distanceKm,
                onTap: () => _NearbyVenueSheet.show(
                    context, venue, distanceKm, openDirections),
                onDirections: openDirections,
              );
            },
          );
        },
      ),
    );
  }
}

// ── Nearby venue list card ────────────────────────────────────────────────────

class _NearbyVenueListCard extends StatelessWidget {
  final OverpassVenue venue;
  final double distanceKm;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _NearbyVenueListCard({
    required this.venue,
    required this.distanceKm,
    required this.onTap,
    required this.onDirections,
  });

  String get _distText {
    if (distanceKm <= 0) return '—';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final tc = _NearbyVenueCard.typeColor(venue.type);
    final tl = _NearbyVenueCard.typeLabel(venue.type);
    final hours = venue.openingHours;
    final address = venue.address;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tc.withValues(alpha: 0.10),
              AppTheme.darkGray,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: tc.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                      color: tc, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: tc.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: tc)),
                            const SizedBox(width: 4),
                            Text(tl,
                                style: TextStyle(
                                    color: tc,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.cream,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      if (address != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.location_on_rounded,
                              size: 11,
                              color: AppTheme.cream.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color:
                                        AppTheme.cream.withValues(alpha: 0.42),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_distText,
                        style: TextStyle(
                            color: AppTheme.cream.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onDirections,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: tc.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Icon(Icons.navigation_rounded,
                            size: 16, color: tc),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (hours != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cream.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.cream.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(hours,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.cream.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.info_outline_rounded, size: 14),
                label: const Text('More Details',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tc,
                  side: BorderSide(color: tc.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby venue card ─────────────────────────────────────────────────────────

class _NearbyVenueCard extends StatelessWidget {
  final OverpassVenue venue;
  final double distanceKm;
  final VoidCallback onDirections;

  const _NearbyVenueCard({
    required this.venue,
    required this.distanceKm,
    required this.onDirections,
  });

  static Color typeColor(String type) {
    switch (type) {
      case 'nightclub':
        return const Color(0xFFE879F9);
      case 'bar':
        return AppTheme.teal;
      case 'pub':
        return const Color(0xFFFBBF24);
      case 'biergarten':
        return AppTheme.neonLime;
      case 'cocktail_bar':
        return const Color(0xFFf48fb1);
      case 'wine_bar':
        return AppTheme.hotPink;
      case 'sports_bar':
        return AppTheme.teal;
      default:
        return AppTheme.teal;
    }
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'nightclub':
        return 'NIGHT CLUB';
      case 'bar':
        return 'BAR';
      case 'pub':
        return 'PUB';
      case 'biergarten':
        return 'BEER GARDEN';
      case 'cocktail_bar':
        return 'COCKTAIL';
      case 'wine_bar':
        return 'WINE BAR';
      case 'sports_bar':
        return 'SPORTS BAR';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  String get _distText {
    if (distanceKm <= 0) return '—';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final tc = typeColor(venue.type);
    final tl = typeLabel(venue.type);

    return GestureDetector(
      onTap: () =>
          _NearbyVenueSheet.show(context, venue, distanceKm, onDirections),
      child: Container(
        width: 162,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tc.withValues(alpha: 0.12),
              AppTheme.darkGray,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: tc.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: tc.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: tc.withValues(alpha: 0.45), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: tc)),
                      const SizedBox(width: 4),
                      Text(tl,
                          style: TextStyle(
                              color: tc,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_distText,
                    style: TextStyle(
                        color: AppTheme.cream.withValues(alpha: 0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 7),
            Text(venue.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.cream,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1)),
            const SizedBox(height: 3),
            Text(
              venue.address ?? venue.typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppTheme.cream.withValues(alpha: 0.42),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.cream.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      venue.openingHours ?? 'Check hours',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.cream.withValues(
                              alpha: venue.openingHours != null ? 0.55 : 0.35),
                          fontSize: 8,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: onDirections,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tc.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.navigation_rounded,
                        size: 13, color: tc),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Venue detail bottom sheet ─────────────────────────────────────────────────

class _NearbyVenueSheet extends StatelessWidget {
  final OverpassVenue venue;
  final double distanceKm;
  final VoidCallback onDirections;

  const _NearbyVenueSheet({
    required this.venue,
    required this.distanceKm,
    required this.onDirections,
  });

  static void show(BuildContext ctx, OverpassVenue venue, double distKm,
      VoidCallback onDir) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NearbyVenueSheet(
          venue: venue, distanceKm: distKm, onDirections: onDir),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = _NearbyVenueCard.typeColor(venue.type);
    final tl = _NearbyVenueCard.typeLabel(venue.type);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    String distText = '—';
    if (distanceKm > 0) {
      distText = distanceKm < 1
          ? '${(distanceKm * 1000).round()} m away'
          : '${distanceKm.toStringAsFixed(1)} km away';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.borderGray,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tc.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: tc)),
                const SizedBox(width: 5),
                Text(tl,
                    style: TextStyle(
                        color: tc,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(venue.name,
              style: TextStyle(
                  color: AppTheme.cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          if (venue.address != null) ...[
            const SizedBox(height: 4),
            Text(venue.address!,
                style: TextStyle(
                    color: AppTheme.cream.withValues(alpha: 0.5),
                    fontSize: 13)),
          ],
          const SizedBox(height: 16),
          _SheetRow(
              icon: Icons.near_me_rounded,
              label: 'Distance',
              value: distText),
          if (venue.openingHours != null)
            _SheetRow(
                icon: Icons.schedule_rounded,
                label: 'Hours',
                value: venue.openingHours!),
          if (venue.phone != null)
            _SheetRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: venue.phone!),
          if (venue.website != null)
            _SheetRow(
                icon: Icons.language_rounded,
                label: 'Website',
                value: venue.website!),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDirections();
              },
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tc,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Data © OpenStreetMap contributors',
              style: TextStyle(
                  color: AppTheme.cream.withValues(alpha: 0.22),
                  fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet info row ────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.cream.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon,
                size: 17,
                color: AppTheme.cream.withValues(alpha: 0.55)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppTheme.cream.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppTheme.cream,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
