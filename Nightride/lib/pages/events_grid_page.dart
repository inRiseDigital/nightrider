// lib/pages/events_grid_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlack   = Color(0xFF070707);
const _kDark    = Color(0xFF151515);
const _kBorder  = Color(0xFF2A2A2A);
const _kLime    = Color(0xFFDFFF2F);
const _kPink    = Color(0xFFFF3D73);
const _kTeal    = Color(0xFF62D6C8);
const _kCream   = Color(0xFFF3EAD6);
const _kWhite   = Color(0xFFFAFAFA);

// ── Category accent ────────────────────────────────────────────────────────────
Color _catAccent(String cat) {
  switch (cat) {
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

// ── Page ──────────────────────────────────────────────────────────────────────

class EventsGridPage extends ConsumerWidget {
  const EventsGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async   = ref.watch(trendingEventsProvider);
    final topPad  = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBlack,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ─────────────────────────────────────────────────────
            _TopBar(topPad: topPad),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: _kLime,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: _kWhite.withValues(alpha: 0.25), size: 48),
                      const Gap(16),
                      Text(
                        AppLocalizations.of(context)!.couldNotLoadEvents,
                        style: TextStyle(
                          color: _kWhite.withValues(alpha: 0.38),
                          fontSize: AppResponsive.font(context, 14),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🎧',
                            style: TextStyle(
                                fontSize: AppResponsive.font(context, 56)),
                          ),
                          const Gap(16),
                          Text(
                            AppLocalizations.of(context)!.noEventsFound,
                            style: TextStyle(
                              color: _kWhite.withValues(alpha: 0.35),
                              fontSize: AppResponsive.font(context, 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by category
                  final Map<String, List<dynamic>> grouped = {};
                  for (final e in events) {
                    grouped.putIfAbsent(e.categoryTag, () => []).add(e);
                  }
                  final categories = grouped.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat       = categories[i];
                      final catEvents = grouped[cat]!;
                      final accent    = _catAccent(cat);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Section header ────────────────────────────
                            _CategoryHeader(
                              label: cat,
                              count: catEvents.length,
                              accent: accent,
                            ),
                            const Gap(14),

                            // ── Horizontal sticker scroll ─────────────────
                            SizedBox(
                              height: AppResponsive.gap(context, 228)
                                  .clamp(195.0, 250.0),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: catEvents.length,
                                itemBuilder: (context, j) {
                                  final event = catEvents[j];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _StickerCard(
                                      id: event.id,
                                      title: event.title,
                                      dateText: event.dateText,
                                      locationText: event.locationText,
                                      imageUrl: event.imageUrl,
                                      categoryTag: event.categoryTag,
                                      accent: accent,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final double topPad;
  const _TopBar({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBlack,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kDark,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kWhite, size: 16),
            ),
          ),
          const Gap(14),

          // Title
          Text(
            'TRENDING',
            style: GoogleFonts.anton(
              color: _kCream,
              fontSize: AppResponsive.font(context, 28),
              letterSpacing: 2.0,
            ),
          ),

          const Spacer(),

          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kLime.withValues(alpha: 0.40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _kLime,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.70),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const Gap(6),
                Text(
                  'LIVE',
                  style: GoogleFonts.anton(
                    color: _kLime,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category section header ───────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  const _CategoryHeader({
    required this.label,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Neon left bar
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.55),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const Gap(10),

        // Label
        Text(
          label,
          style: GoogleFonts.anton(
            color: _kWhite,
            fontSize: AppResponsive.font(context, 17),
            letterSpacing: 1.8,
          ),
        ),
        const Gap(10),

        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.anton(
              color: accent,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sticker event card ────────────────────────────────────────────────────────

class _StickerCard extends StatelessWidget {
  const _StickerCard({
    required this.id,
    required this.title,
    required this.dateText,
    required this.locationText,
    required this.imageUrl,
    required this.categoryTag,
    required this.accent,
  });

  final String id;
  final String title;
  final String dateText;
  final String locationText;
  final String imageUrl;
  final String categoryTag;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cardW = AppResponsive.gap(context, 162).clamp(142.0, 188.0);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: id)),
      ),
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: _kDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + overlays ─────────────────────────────────────────
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.40, 1.0],
                      ),
                    ),
                  ),

                  // Category sticker — top left
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        categoryTag,
                        style: GoogleFonts.anton(
                          color: accent.computeLuminance() > 0.4
                              ? _kBlack
                              : _kWhite,
                          fontSize: 8,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Date pill — bottom left of image
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kPink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          color: _kWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Text info ─────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.anton(
                        color: _kCream,
                        fontSize: AppResponsive.font(context, 12),
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                    const Gap(5),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 10, color: _kTeal),
                        const Gap(3),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _kTeal,
                              fontSize: AppResponsive.font(context, 10),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
