// lib/pages/category_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/data/services/overpass_service.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/providers/nearby_venues_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlack   = Color(0xFF070707);
const _kDark    = Color(0xFF151515);
const _kSurface = Color(0xFF0F0F0F);
const _kBorder  = Color(0xFF2A2A2A);
const _kLime    = Color(0xFFDFFF2F);
const _kPink    = Color(0xFFFF3D73);
const _kTeal    = Color(0xFF62D6C8);
const _kCream   = Color(0xFFF3EAD6);
const _kWhite   = Color(0xFFFAFAFA);

// ── Per-category identity ─────────────────────────────────────────────────────

class _Info {
  final String emoji;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final String desc;
  const _Info(this.emoji, this.bgColor, this.accentColor, this.textColor, this.desc);
}

const _kInfo = <String, _Info>{
  'CLUB':   _Info('🎪', Color(0xFFFF3D73), Color(0xFF070707), Color(0xFF070707),
      'The hottest clubs tonight — live lineups, crowd levels & exclusive tables.'),
  'DJ':     _Info('🎧', Color(0xFFFF3D73), Color(0xFF070707), Color(0xFF070707),
      'World-class DJs spinning deep house to hard techno. Find your set.'),
  'TECHNO': _Info('⚡', Color(0xFF62D6C8), Color(0xFF070707), Color(0xFF070707),
      'Relentless kicks and hypnotic grooves. The purest form of electronic music.'),
  'RAVE':   _Info('🌀', Color(0xFF62D6C8), Color(0xFF070707), Color(0xFF070707),
      'Underground raves, warehouse parties and open-air events. Pure energy.'),
  'EDM':    _Info('🔥', Color(0xFFDFFF2F), Color(0xFF070707), Color(0xFF070707),
      'Big drops, massive stages and festival vibes. The sound that moved millions.'),
  'HOUSE':  _Info('🎵', Color(0xFFDFFF2F), Color(0xFF070707), Color(0xFF070707),
      'Soulful grooves and four-to-the-floor beats. House music never sleeps.'),
  'LIVE':   _Info('🎤', Color(0xFFFF3D73), Color(0xFF070707), Color(0xFF070707),
      'Live bands, acoustic sets and raw performances. Real instruments, real energy.'),
};

_Info _infoFor(String cat) => _kInfo[cat] ??
    const _Info('🎶', Color(0xFFDFFF2F), Color(0xFF070707), Color(0xFF070707),
        'Explore events in this category.');

// ── Page ──────────────────────────────────────────────────────────────────────

class CategoryDetailPage extends ConsumerStatefulWidget {
  final String category;
  const CategoryDetailPage({super.key, required this.category});

  @override
  ConsumerState<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends ConsumerState<CategoryDetailPage> {
  int _tab = 0;
  static const _tabs = ['ALL', 'TONIGHT', 'HOT'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(selectedCategoryProvider.notifier).state = widget.category;
      }
    });
  }

  List<TrendingEvent> _events() {
    final live = ref.watch(filteredTrendingProvider);
    var events = live;

    if (events.isEmpty) {
      events = kTrendingEvents.where((e) => e.categoryTag == widget.category).toList();
      if (events.isEmpty) events = kTrendingEvents;
    }

    switch (_tab) {
      case 1:
        final t = events
            .where((e) =>
                e.dateText.toLowerCase().contains('tonight') ||
                e.dateText.toLowerCase().contains('today'))
            .toList();
        return t.isEmpty ? events : t;
      case 2:
        final sorted = [...events];
        sorted.sort((a, b) {
          int n(String s) =>
              int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return n(b.interestedCountText).compareTo(n(a.interestedCountText));
        });
        return sorted;
      default:
        return events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info      = _infoFor(widget.category);
    final hPad      = AppResponsive.pagePadding(context);
    final topPad    = MediaQuery.viewPaddingOf(context).top;
    final bottomPad = AppResponsive.bottomNavHeight(context) +
        MediaQuery.viewPaddingOf(context).bottom + 32;
    final events    = _events();

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        ref.read(selectedCategoryProvider.notifier).state = 'ALL';
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: info.bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Colored hero header ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _CategoryHero(
                  info: info,
                  category: widget.category,
                  topPad: topPad,
                  hPad: hPad,
                  eventCount: events.length,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),

              // ── Black body starts here ────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBlack,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(8),
                      _FilterRow(
                        tabs: _tabs,
                        selected: _tab,
                        accentColor: info.bgColor,
                        hPad: hPad,
                        onTap: (i) => setState(() => _tab = i),
                      ),
                      const Gap(4),
                    ],
                  ),
                ),
              ),

              // ── Nearby clubs from OSM (CLUB category only) ──────────
              if (widget.category == 'CLUB')
                SliverToBoxAdapter(
                  child: Container(
                    color: _kBlack,
                    child: _NearbyClubsSection(hPad: hPad),
                  ),
                ),

              SliverToBoxAdapter(
                child: Container(
                  color: _kBlack,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                    child: events.isEmpty
                        ? _EmptyState(info: info, category: widget.category)
                        : _EventGrid(events: events),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Colored hero header ────────────────────────────────────────────────────────

class _CategoryHero extends StatelessWidget {
  final _Info info;
  final String category;
  final double topPad;
  final double hPad;
  final int eventCount;
  final VoidCallback onBack;

  const _CategoryHero({
    required this.info,
    required this.category,
    required this.topPad,
    required this.hPad,
    required this.eventCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bg = info.bgColor;
    final isDark = bg.computeLuminance() < 0.4;
    final textCol = isDark ? _kCream : _kBlack;
    final subTextCol = isDark
        ? _kCream.withValues(alpha: 0.65)
        : _kBlack.withValues(alpha: 0.60);

    return Container(
      color: bg,
      padding: EdgeInsets.fromLTRB(hPad, topPad + 12, hPad, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button row
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textCol,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const Gap(28),

          // Giant emoji — centered
          Text(
            info.emoji,
            style: const TextStyle(fontSize: 88),
          ),
          const Gap(16),

          // Category name — Anton, huge, uppercase
          Text(
            category.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.anton(
              color: textCol,
              fontSize: AppResponsive.font(context, 64),
              height: 0.92,
              letterSpacing: 2.0,
            ),
          ),
          const Gap(14),

          // Description
          Text(
            info.desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextCol,
              fontSize: AppResponsive.font(context, 13),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(24),

          // Stats row — pill chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(value: '$eventCount', label: 'EVENTS', textColor: textCol, bg: bg),
              const Gap(10),
              _StatPill(value: 'GLOBAL', label: 'VENUES', textColor: textCol, bg: bg),
              const Gap(10),
              _StatPill(value: 'LIVE', label: 'NOW', textColor: textCol, bg: bg),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color bg;
  const _StatPill({
    required this.value,
    required this.label,
    required this.textColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = bg.computeLuminance() < 0.4;
    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.anton(
              color: textColor,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final Color accentColor;
  final double hPad;
  final ValueChanged<int> onTap;

  const _FilterRow({
    required this.tabs,
    required this.selected,
    required this.accentColor,
    required this.hPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
        separatorBuilder: (_, __) => const Gap(8),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final sel = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: sel ? accentColor : _kDark,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel ? accentColor : _kBorder,
                  width: 1.5,
                ),
                boxShadow: sel
                    ? [BoxShadow(
                        color: accentColor.withValues(alpha: 0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i],
                style: GoogleFonts.anton(
                  color: sel
                      ? (accentColor.computeLuminance() > 0.4 ? _kBlack : _kWhite)
                      : _kWhite.withValues(alpha: 0.45),
                  fontSize: AppResponsive.font(context, 13),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Event grid — sticker style ────────────────────────────────────────────────

class _EventGrid extends StatelessWidget {
  final List<TrendingEvent> events;
  const _EventGrid({required this.events});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: events.length,
      itemBuilder: (ctx, i) => _StickerEventCard(event: events[i]),
    );
  }
}

// ── Sticker event card ────────────────────────────────────────────────────────

class _StickerEventCard extends StatelessWidget {
  final TrendingEvent event;
  const _StickerEventCard({required this.event});

  Color get _accentForCat {
    switch (event.categoryTag) {
      case 'TECHNO':
      case 'RAVE':
        return _kTeal;
      case 'HOUSE':
      case 'EDM':
        return _kLime;
      default:
        return _kPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForCat;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _kDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — 60% of card
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: _kDark),
                    errorWidget: (_, __, ___) => Container(
                      color: _kDark,
                      alignment: Alignment.center,
                      child: Icon(Icons.music_note_rounded,
                          color: accent.withValues(alpha: 0.35), size: 32),
                    ),
                  ),

                  // Gradient scrim
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xBB000000)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),

                  // Category sticker — top left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        event.categoryTag,
                        style: GoogleFonts.anton(
                          color: accent.computeLuminance() > 0.4
                              ? _kBlack
                              : _kWhite,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Date badge — bottom left of image
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlack.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(
                        event.dateText,
                        style: const TextStyle(
                          color: _kCream,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text area — 40% of card
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.anton(
                        color: _kWhite,
                        fontSize: AppResponsive.font(context, 13),
                        letterSpacing: 0.4,
                        height: 1.15,
                      ),
                    ),
                    const Gap(5),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 10, color: _kTeal),
                        const Gap(3),
                        Expanded(
                          child: Text(
                            event.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _kTeal,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // VIEW button
                    Container(
                      width: double.infinity,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VIEW',
                        style: GoogleFonts.anton(
                          color: accent.computeLuminance() > 0.4 ? _kBlack : _kWhite,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby clubs section (OSM / Overpass) ────────────────────────────────────

class _NearbyClubsSection extends ConsumerWidget {
  final double hPad;
  const _NearbyClubsSection({required this.hPad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);
    final venuesAsync   = ref.watch(nearbyVenuesProvider);

    // No location yet — waiting
    if (locationAsync.isLoading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 4),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal),
          ),
        ),
      );
    }

    final pos = locationAsync.asData?.value;
    if (pos == null) return const SizedBox.shrink(); // permission denied

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _kTeal, size: 15),
              const Gap(6),
              Text(
                'CLUBS NEAR YOU',
                style: GoogleFonts.anton(
                  color: _kCream,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        venuesAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kTeal),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (venues) {
            if (venues.isEmpty) {
              return Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                child: Text(
                  'No clubs found nearby. Try expanding your search area.',
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                separatorBuilder: (_, __) => const Gap(10),
                itemCount: venues.length,
                itemBuilder: (_, i) => _NearbyClubCard(venue: venues[i]),
              ),
            );
          },
        ),

        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: hPad),
          color: _kBorder,
        ),
        const Gap(16),

        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 4),
          child: Text(
            'UPCOMING EVENTS',
            style: GoogleFonts.anton(
              color: _kCream,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Nearby club card ──────────────────────────────────────────────────────────

class _NearbyClubCard extends StatelessWidget {
  final OverpassVenue venue;
  const _NearbyClubCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.nightlife_rounded, color: _kTeal, size: 18),
          ),
          const Gap(8),
          Text(
            venue.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anton(
              color: _kWhite,
              fontSize: 12,
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              venue.typeLabel.toUpperCase(),
              style: const TextStyle(
                color: _kTeal,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (venue.address != null) ...[
            const Gap(4),
            Text(
              venue.address!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _kWhite.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Info info;
  final String category;
  const _EmptyState({required this.info, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 64)),
          const Gap(20),
          Text(
            'NO $category EVENTS YET',
            textAlign: TextAlign.center,
            style: GoogleFonts.anton(
              color: _kWhite.withValues(alpha: 0.65),
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          const Gap(8),
          Text(
            'Check back soon — events are added daily',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kWhite.withValues(alpha: 0.30),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
