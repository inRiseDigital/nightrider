// lib/pages/home_page.dart
//
// Retro nightlife poster home screen.
// Palette: black=#070707, cream=#F3EAD6, neonLime=#DFFF2F,
//          hotPink=#FF3D73, teal=#62D6C8, darkGray=#151515, borderGray=#333333

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/components/home_featured_carousel.dart';
import 'package:nightride/pages/category_detail_page.dart';
import 'package:nightride/components/home_location_row.dart';
import 'package:nightride/components/home_section_title.dart';
import 'package:nightride/components/home_top_bar.dart';
import 'package:nightride/components/home_trending_list.dart';
import 'package:nightride/components/home_ui_bits.dart';
import 'package:nightride/components/layout/responsive_layout.dart';
import 'package:nightride/components/nightrite_refresh.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/services/overpass_service.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/pages/clubs_page.dart';
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
                  // ── Top bar ─────────────────────────────────────────────
                  ResponsivePagePadding(
                    child: HomeTopBar(username: username),
                  ),
                  SizedBox(
                      height: AppResponsive.gap(context, 20)),

                  // ── Hero headline ───────────────────────────────────────
                  ResponsivePagePadding(
                    child: _HeroHeadline(
                      onAiTap: () =>
                          ref.read(appNavProvider.notifier).setIndex(2),
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 8)),

                  // ── Location row (conditional) ──────────────────────────
                  if (locationLabel.isNotEmpty) ...[
                    ResponsivePagePadding(
                      child: HomeLocationRow(country: locationLabel),
                    ),
                    SizedBox(height: AppResponsive.gap(context, 24)),
                  ] else
                    SizedBox(height: AppResponsive.gap(context, 20)),

                  // ── Featured carousel — full-bleed ──────────────────────
                  const HomeFeaturedCarousel(),
                  SizedBox(height: AppResponsive.gap(context, 28)),

                  // ── LIVE RIGHT NOW stat cards ───────────────────────────
                  ResponsivePagePadding(
                    child: HomeSectionTitle(
                      title: 'LIVE RIGHT NOW',
                      accentColor: AppTheme.hotPink,
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
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 14)),
                  ResponsivePagePadding(
                    child: const _ExploreTileRow(),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 28)),

                  // ── TRENDING NEAR YOU horizontal scroll ─────────────────
                  ResponsivePagePadding(
                    child: HomeSectionTitle(
                      title: 'TRENDING NEAR YOU',
                      accentColor: AppTheme.cream,
                      onViewAll: () {},
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 14)),
                  // Trending list scrolls edge-to-edge with left padding only
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppResponsive.gap(context, 20)
                          .clamp(16.0, 28.0),
                    ),
                    child: const HomeTrendingList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero headline block ───────────────────────────────────────────────────────

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({required this.onAiTap});
  final VoidCallback onAiTap;

  @override
  Widget build(BuildContext context) {
    final titleFontSize =
        AppResponsive.font(context, 34).clamp(26.0, 42.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Text + button (left) ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "WHERE ARE WE GOING" line — cream
              Text(
                'WHERE ARE WE GOING',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.anton(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.cream,
                  letterSpacing: 1.2,
                  height: 1.1,
                ),
              ),
              // "TONIGHT?" line — hotPink accent
              Text(
                'TONIGHT?',
                style: GoogleFonts.anton(
                  fontSize: titleFontSize * 1.06,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.hotPink,
                  letterSpacing: 1.2,
                  height: 1.05,
                ),
              ),
              SizedBox(height: AppResponsive.gap(context, 18)),
              // AI plan button
              GestureDetector(
                onTap: onAiTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonLime.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✦',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI PLAN MY NIGHT',
                        style: GoogleFonts.anton(
                          fontSize: AppResponsive.font(context, 15)
                              .clamp(13.0, 17.0),
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Vinyl mascot (right, animated) ───────────────────────────
        const _AnimatedMascot(
          assetPath: 'assets/images/vinyl_mascot_3.png',
          size: 110,
        ),
      ],
    );
  }
}

// ── Animated mascot (float bob) ──────────────────────────────────────────────
class _AnimatedMascot extends StatefulWidget {
  const _AnimatedMascot({required this.assetPath, required this.size});
  final String assetPath;
  final double size;

  @override
  State<_AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<_AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: child,
      ),
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: Image.asset(
          widget.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
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
  _ExploreCat('TECHNO',     'TECHNO', Icons.language,               Color(0xFF6D28D9)),
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

class _ExploreTileState extends State<_ExploreTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final onDark = cat.bg != AppTheme.neonLime;
    final fg = onDark ? Colors.white : Colors.black;

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
              AnimatedBuilder(
                animation: _anim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _anim.value),
                  child: child,
                ),
                child: Icon(cat.icon, color: fg, size: 28),
              ),
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
            accent: AppTheme.teal,
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
            accent: AppTheme.neonLime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'EVENTS',
            value: eventsCount != null ? '$eventsCount' : '--',
            accent: AppTheme.hotPink,
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
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
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
