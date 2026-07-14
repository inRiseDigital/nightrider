// lib/components/home_trending_list.dart
//
// Retro nightlife poster style — horizontal scroll of sticker/polaroid-style
// event cards. Uses real data from trendingEventsProvider.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

class HomeTrendingList extends ConsumerWidget {
  const HomeTrendingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingEventsProvider);

    if (async.isLoading) {
      return const _TrendingSkeletonRow();
    }

    final allLive = async.asData?.value ?? [];
    final filtered = ref.watch(filteredTrendingProvider);
    final cat = ref.watch(selectedCategoryProvider);
    final country = ref.watch(selectedCountryProvider);

    // No Firestore data at all — show dummy fallback
    if (allLive.isEmpty) return _buildRow(kTrendingEvents);

    // Filter active but nothing in Firestore matches — fall back to dummy
    if (filtered.isEmpty && (cat != 'ALL' || country != 'ALL')) {
      final fallback = cat == 'ALL'
          ? kTrendingEvents
          : kTrendingEvents
              .where((e) => e.categoryTag == cat)
              .toList();
      return _buildRow(
          fallback.isNotEmpty ? fallback : kTrendingEvents);
    }

    return _buildRow(filtered.isNotEmpty ? filtered : allLive);
  }

  Widget _buildRow(List<TrendingEvent> events) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: events.length,
        itemBuilder: (ctx, i) => _PolaroidCard(event: events[i]),
      ),
    );
  }
}

// ── Polaroid / sticker card ───────────────────────────────────────────────────

class _PolaroidCard extends ConsumerWidget {
  const _PolaroidCard({required this.event});
  final TrendingEvent event;

  // Pick an accent colour per genre tag for the venue name row
  Color _accentFor(String tag) {
    final t = tag.toUpperCase();
    if (t.contains('TECHNO') || t.contains('INDUSTRIAL')) {
      return AppTheme.teal;
    }
    if (t.contains('HOUSE')) return AppTheme.neonLime;
    if (t.contains('LATIN') || t.contains('REGGAETON')) {
      return AppTheme.hotPink;
    }
    if (t.contains('LIVE') || t.contains('BAND')) return AppTheme.cream;
    if (t.contains('EDM') || t.contains('DANCE')) {
      return const Color(0xFFFFAA3E);
    }
    if (t.contains('HIP') || t.contains('RAP') || t.contains('TRAP')) {
      return const Color(0xFFDD6BFF);
    }
    return AppTheme.hotPink;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs =
        ref.watch(favouritesStreamProvider).asData?.value ?? [];
    final bool liked = favs.any((f) => f['id'] == event.id);
    final accent = _accentFor(event.categoryTag);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
      ),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderGray, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
              child: SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFF1A1A1A)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.borderGray,
                          size: 30,
                        ),
                      ),
                    ),
                    // Bottom gradient scrim
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category tag — top left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          event.categoryTag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: accent,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Heart button — top right
                    Positioned(
                      top: 7,
                      right: 7,
                      child: GestureDetector(
                        onTap: () => _toggleFavourite(ref, liked),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: liked
                                ? AppTheme.hotPink
                                : AppTheme.cream
                                    .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    // Date badge — bottom left
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppTheme.borderGray,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          event.dateText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cream
                                .withValues(alpha: 0.85),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Text area — polaroid bottom strip ──────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Event name
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.anton(
                        fontSize: AppResponsive.font(context, 13)
                            .clamp(11.0, 14.5),
                        fontWeight: FontWeight.w400,
                        color: AppTheme.cream,
                        letterSpacing: 0.5,
                        height: 1.25,
                      ),
                    ),
                    // Location in accent colour
                    Text(
                      event.locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.3,
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

  Future<void> _toggleFavourite(WidgetRef ref, bool isLiked) async {
    final svc = ref.read(favouritesServiceProvider);
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    if (isLiked) {
      await svc.remove(user.uid, event.id);
    } else {
      await svc.add(user.uid, {
        'id': event.id,
        'name': event.title,
        'title': event.title,
        'cover_image': event.imageUrl,
        'city': event.locationText,
        'country': event.countryCode,
        'country_code': event.countryCode,
        'date': event.rawDate,
        'genre': event.categoryTag,
      });
    }
  }
}

// ── Skeleton placeholder ──────────────────────────────────────────────────────

class _TrendingSkeletonRow extends StatelessWidget {
  const _TrendingSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          width: 175,
          decoration: BoxDecoration(
            color: AppTheme.darkGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGray, width: 1),
          ),
        ),
      ),
    );
  }
}
