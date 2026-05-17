// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/components/home_category_rail.dart';
import 'package:nightride/components/home_country_filter.dart';
import 'package:nightride/components/home_featured_carousel.dart';
import 'package:nightride/components/home_location_row.dart';
import 'package:nightride/components/home_section_title.dart';
import 'package:nightride/components/home_top_bar.dart';
import 'package:nightride/components/home_trending_list.dart';
import 'package:nightride/components/home_ui_bits.dart';
import 'package:nightride/components/layout/responsive_layout.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/live_hub_dummy_data.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/live_hub_providers.dart';
import 'package:nightride/pages/clubs_page.dart';
import 'package:nightride/providers/profile_providers.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/home_dummy_data.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider).data;
    final locationLabel = profile.city.isNotEmpty
        ? profile.city
        : profile.countryCode.isNotEmpty
            ? profile.countryCode
            : '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: const HomeSmoothScrollBehavior(),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.background, AppTheme.scaffold],
              ),
            ),
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
                  ResponsivePagePadding(
                    child: HomeTopBar(title: kAppTitle),
                  ),
                  const ResponsiveGap.subSection(),
                  ResponsiveContentContainer(
                    child: ResponsivePagePadding(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (locationLabel.isNotEmpty) ...[
                            HomeLocationRow(country: locationLabel),
                            const ResponsiveGap.section(),
                          ] else
                            const ResponsiveGap.s(),
                          const HomeFeaturedCarousel(),
                          const ResponsiveGap.section(),
                          HomeSectionTitle(title: l.exploreCategories),
                          const ResponsiveGap.subSection(),
                          const HomeCategoryRail(),
                          const ResponsiveGap.subSection(),
                          const HomeCountryFilter(),
                          const ResponsiveGap.section(),
                          // ── Clubs Right Now (live) ─────────────────────
                          const _LiveNowHeader(),
                          const SizedBox(height: 12),
                          const _LiveClubsRow(),
                          const ResponsiveGap.section(),
                          HomeSectionTitle(title: l.trendingEvents),
                          const ResponsiveGap.subSection(),
                          const HomeTrendingList(),
                        ],
                      ),
                    ),
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

// ── "Clubs Right Now" header ──────────────────────────────────────────────────

class _LiveNowHeader extends StatelessWidget {
  const _LiveNowHeader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ClubsPage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4ADE80),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.75),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Clubs Right Now',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppResponsive.font(context, 17),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            size: 12,
          ),
          const Spacer(),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF4ADE80),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal clubs row ──────────────────────────────────────────────────────

class _LiveClubsRow extends ConsumerWidget {
  const _LiveClubsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clubUpdatesProvider);
    final firestoreClubs = async.asData?.value ?? [];
    final clubs = firestoreClubs.isNotEmpty ? firestoreClubs : kClubUpdates;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: clubs.length,
        itemBuilder: (ctx, i) => _ClubCard(club: clubs[i]),
      ),
    );
  }
}

// ── Club card ─────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubUpdate club;
  const _ClubCard({required this.club});

  static Color _statusColor(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:     return const Color(0xFF4ADE80);
      case ClubStatus.closed:   return Colors.white38;
      case ClubStatus.vipOnly:  return const Color(0xFFE879F9);
      case ClubStatus.soldOut:  return const Color(0xFFFF6B6B);
    }
  }

  static String _statusLabel(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:     return 'OPEN';
      case ClubStatus.closed:   return 'CLOSED';
      case ClubStatus.vipOnly:  return 'VIP ONLY';
      case ClubStatus.soldOut:  return 'SOLD OUT';
    }
  }

  static Color _crowdColor(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return Colors.white38;
      case CrowdLevel.quiet:    return const Color(0xFF4ADE80);
      case CrowdLevel.moderate: return const Color(0xFFFBBF24);
      case CrowdLevel.busy:     return const Color(0xFFF97316);
      case CrowdLevel.packed:   return const Color(0xFFEF4444);
    }
  }

  static String _crowdLabel(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return 'EMPTY';
      case CrowdLevel.quiet:    return 'QUIET';
      case CrowdLevel.moderate: return 'MODERATE';
      case CrowdLevel.busy:     return 'BUSY';
      case CrowdLevel.packed:   return 'PACKED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(club.status);
    final sl = _statusLabel(club.status);
    final cc = _crowdColor(club.crowdLevel);
    final cl = _crowdLabel(club.crowdLevel);

    // Truncate DJ name so it fits
    final djText = club.tonightDj != null
        ? (club.tonightDj!.length > 12
            ? '${club.tonightDj!.substring(0, 11)}…'
            : club.tonightDj!)
        : null;

    return GestureDetector(
      onTap: () => _ClubDetailSheet.show(context, club),
      child: Container(
      width: 162,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sc.withValues(alpha: 0.12),
            const Color(0xFF0E0E1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sc.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: sc.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status badge + updated time ──────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: sc.withValues(alpha: 0.45), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: sc),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sl,
                      style: TextStyle(
                        color: sc,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                club.lastUpdated,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ── Club name ────────────────────────────────────────────────
          Text(
            club.clubName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 3),

          // ── City · Country ───────────────────────────────────────────
          Text(
            '${club.city} · ${club.country}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // ── Crowd + DJ ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: cc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cl,
                  style: TextStyle(
                    color: cc,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (djText != null) ...[
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      djText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}

// ── Club detail bottom sheet ───────────────────────────────────────────────────

class _ClubDetailSheet extends StatelessWidget {
  final ClubUpdate club;
  const _ClubDetailSheet({required this.club});

  static void show(BuildContext context, ClubUpdate club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClubDetailSheet(club: club),
    );
  }

  static Color _statusColor(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:    return const Color(0xFF4ADE80);
      case ClubStatus.closed:  return Colors.white38;
      case ClubStatus.vipOnly: return const Color(0xFFE879F9);
      case ClubStatus.soldOut: return const Color(0xFFFF6B6B);
    }
  }

  static String _statusLabel(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:    return 'OPEN';
      case ClubStatus.closed:  return 'CLOSED';
      case ClubStatus.vipOnly: return 'VIP ONLY';
      case ClubStatus.soldOut: return 'SOLD OUT';
    }
  }

  static Color _crowdColor(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return Colors.white38;
      case CrowdLevel.quiet:    return const Color(0xFF4ADE80);
      case CrowdLevel.moderate: return const Color(0xFFFBBF24);
      case CrowdLevel.busy:     return const Color(0xFFF97316);
      case CrowdLevel.packed:   return const Color(0xFFEF4444);
    }
  }

  static String _crowdLabel(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return 'Empty';
      case CrowdLevel.quiet:    return 'Quiet';
      case CrowdLevel.moderate: return 'Moderate';
      case CrowdLevel.busy:     return 'Busy';
      case CrowdLevel.packed:   return 'Packed';
    }
  }

  static String _queueLabel(QueueStatus q) {
    switch (q) {
      case QueueStatus.noQueue:  return 'No queue';
      case QueueStatus.short:    return 'Short (~10 min)';
      case QueueStatus.moderate: return 'Moderate (~30 min)';
      case QueueStatus.long:     return 'Long (45+ min)';
      case QueueStatus.closed:   return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(club.status);
    final sl = _statusLabel(club.status);
    final cc = _crowdColor(club.crowdLevel);
    final cl = _crowdLabel(club.crowdLevel);
    final ql = _queueLabel(club.queueStatus);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header: photo + gradient + name ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo
                    if (club.imageUrl.isNotEmpty)
                      Image.network(club.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: sc.withValues(alpha: 0.15))),
                    // Scrim
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Content over photo
                    Positioned(
                      left: 16, right: 16, bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: sc.withValues(alpha: 0.55)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: sc),
                                ),
                                const SizedBox(width: 5),
                                Text(sl,
                                    style: TextStyle(
                                        color: sc,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Club name
                          Text(
                            club.clubName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${club.city} · ${club.country}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Info rows ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.people_rounded,
                  label: 'Crowd',
                  value: cl,
                  valueColor: cc,
                ),
                _InfoRow(
                  icon: Icons.linear_scale_rounded,
                  label: 'Queue',
                  value: ql,
                ),
                if (club.tonightDj != null)
                  _InfoRow(
                    icon: Icons.headphones_rounded,
                    label: "Tonight's DJ",
                    value: club.tonightDj!,
                    valueColor: const Color(0xFFDD6BFF),
                  ),
                _InfoRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Tickets',
                  value: club.ticketsAvailable ? 'Available' : 'Sold Out',
                  valueColor: club.ticketsAvailable
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFF6B6B),
                ),
                _InfoRow(
                  icon: Icons.table_bar_rounded,
                  label: 'Tables',
                  value: club.tablesAvailable ? 'Available' : 'Not Available',
                  valueColor: club.tablesAvailable
                      ? const Color(0xFF4ADE80)
                      : Colors.white54,
                ),
                if (club.offer != null)
                  _InfoRow(
                    icon: Icons.local_offer_rounded,
                    label: 'Offer',
                    value: club.offer!,
                    valueColor: const Color(0xFFFFAA3E),
                  ),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Last Updated',
                  value: club.lastUpdated,
                ),
              ],
            ),
          ),

          SizedBox(height: 24 + bottomPad),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17,
                color: Colors.white.withValues(alpha: 0.55)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    style: TextStyle(
                        color: valueColor ?? Colors.white,
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
