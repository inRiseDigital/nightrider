import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/live_hub_dummy_data.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/providers/live_hub_providers.dart';

class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage>
    with SingleTickerProviderStateMixin {
  ClubStatus? _filter; // null = ALL

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clubUpdatesProvider);
    final firestoreClubs = async.asData?.value ?? [];
    final all = firestoreClubs.isNotEmpty ? firestoreClubs : kClubUpdates;

    final clubs = _filter == null
        ? all
        : all.where((c) => c.status == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          // ── Background glows ─────────────────────────────────────────────
          const Positioned.fill(child: _Background()),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                _TopBar(pulse: _pulse),
                const SizedBox(height: 16),

                // Filter chips
                _FilterRow(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 16),

                // Club list
                Expanded(
                  child: clubs.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            MediaQuery.viewPaddingOf(context).bottom + 32,
                          ),
                          itemCount: clubs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) =>
                              _ClubCard(club: clubs[i]),
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

// ── Background ────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0D1F), Color(0xFF07070F)],
            ),
          ),
        ),
        // Green top glow (clubs = live = green)
        Positioned(
          top: -120,
          left: -60,
          child: _Blob(
            size: 380,
            color: const Color(0xFF4ADE80).withValues(alpha: 0.13),
          ),
        ),
        // Purple mid glow
        Positioned(
          top: 200,
          right: -100,
          child: _Blob(
            size: 300,
            color: AppTheme.primary.withValues(alpha: 0.14),
          ),
        ),
        // Teal bottom glow
        Positioned(
          bottom: 80,
          left: -80,
          child: _Blob(
            size: 260,
            color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
          ),
        ),
        // Subtle noise overlay
        Container(color: Colors.black.withValues(alpha: 0.08)),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),

          // Pulsing green dot
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              final v = pulse.value;
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4ADE80),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80)
                          .withValues(alpha: 0.3 + 0.5 * v),
                      blurRadius: 6 + 8 * v,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Title
          const Text(
            'Clubs Right Now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),

          // LIVE badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.35)),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});
  final ClubStatus? selected;
  final ValueChanged<ClubStatus?> onSelected;

  static const _items = <(String, ClubStatus?, Color)>[
    ('ALL', null, Color(0xFFA78BFA)),
    ('OPEN', ClubStatus.open, Color(0xFF4ADE80)),
    ('VIP ONLY', ClubStatus.vipOnly, Color(0xFFE879F9)),
    ('SOLD OUT', ClubStatus.soldOut, Color(0xFFFF6B6B)),
    ('CLOSED', ClubStatus.closed, Color(0xFF94A3B8)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final (label, status, color) = _items[i];
          final active = selected == status;
          return GestureDetector(
            onTap: () => onSelected(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.10),
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? color : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Club card ─────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final ClubUpdate club;

  static Color _statusColor(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:     return const Color(0xFF4ADE80);
      case ClubStatus.closed:   return const Color(0xFF94A3B8);
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
      case CrowdLevel.empty:    return const Color(0xFF94A3B8);
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

  static String _queueLabel(QueueStatus q) {
    switch (q) {
      case QueueStatus.noQueue:  return 'No queue';
      case QueueStatus.short:    return '~10 min';
      case QueueStatus.moderate: return '~30 min';
      case QueueStatus.long:     return '45+ min';
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

    return GestureDetector(
      onTap: () => _ClubDetailSheet.show(context, club),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo background
              club.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: club.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: sc.withValues(alpha: 0.08)),
                      errorWidget: (_, __, ___) =>
                          Container(color: sc.withValues(alpha: 0.08)),
                    )
                  : Container(color: sc.withValues(alpha: 0.08)),

              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),

              // Left status accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: sc,
                    boxShadow: [
                      BoxShadow(
                        color: sc.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 16,
                right: 16,
                top: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: sc.withValues(alpha: 0.50), width: 1),
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
                              Text(sl,
                                  style: TextStyle(
                                      color: sc,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          club.lastUpdated,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Club name
                    Text(
                      club.clubName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // City · Country
                    Text(
                      '${club.city} · ${club.country}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Info pills row
                    Row(
                      children: [
                        // Crowd
                        _Pill(
                          label: cl,
                          color: cc,
                          icon: Icons.people_rounded,
                        ),
                        const SizedBox(width: 6),
                        // Queue
                        _Pill(
                          label: ql,
                          color: Colors.white54,
                          icon: Icons.linear_scale_rounded,
                        ),
                        if (club.tonightDj != null) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: _Pill(
                              label: club.tonightDj!,
                              color: const Color(0xFFDD6BFF),
                              icon: Icons.headphones_rounded,
                              expand: true,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Border overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sc.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.icon,
    this.expand = false,
  });
  final String label;
  final Color color;
  final IconData icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 4),
        expand
            ? Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: content,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nightlife_rounded,
              color: Colors.white.withValues(alpha: 0.15), size: 56),
          const SizedBox(height: 16),
          Text(
            'No clubs match this filter',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Club detail bottom sheet ──────────────────────────────────────────────────

class _ClubDetailSheet extends StatelessWidget {
  const _ClubDetailSheet({required this.club});
  final ClubUpdate club;

  static void show(BuildContext context, ClubUpdate club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClubDetailSheet(club: club),
    );
  }

  static Color _sc(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:     return const Color(0xFF4ADE80);
      case ClubStatus.closed:   return const Color(0xFF94A3B8);
      case ClubStatus.vipOnly:  return const Color(0xFFE879F9);
      case ClubStatus.soldOut:  return const Color(0xFFFF6B6B);
    }
  }

  static String _sl(ClubStatus s) {
    switch (s) {
      case ClubStatus.open:     return 'OPEN';
      case ClubStatus.closed:   return 'CLOSED';
      case ClubStatus.vipOnly:  return 'VIP ONLY';
      case ClubStatus.soldOut:  return 'SOLD OUT';
    }
  }

  static Color _cc(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return const Color(0xFF94A3B8);
      case CrowdLevel.quiet:    return const Color(0xFF4ADE80);
      case CrowdLevel.moderate: return const Color(0xFFFBBF24);
      case CrowdLevel.busy:     return const Color(0xFFF97316);
      case CrowdLevel.packed:   return const Color(0xFFEF4444);
    }
  }

  static String _cl(CrowdLevel c) {
    switch (c) {
      case CrowdLevel.empty:    return 'Empty';
      case CrowdLevel.quiet:    return 'Quiet';
      case CrowdLevel.moderate: return 'Moderate';
      case CrowdLevel.busy:     return 'Busy';
      case CrowdLevel.packed:   return 'Packed';
    }
  }

  static String _ql(QueueStatus q) {
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
    final sc = _sc(club.status);
    final sl = _sl(club.status);
    final cc = _cc(club.crowdLevel);
    final cl = _cl(club.crowdLevel);
    final ql = _ql(club.queueStatus);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF10101C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),

          // Photo header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (club.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: club.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: sc.withValues(alpha: 0.12)),
                      )
                    else
                      Container(color: sc.withValues(alpha: 0.12)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: sc.withValues(alpha: 0.55)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
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

          // Info rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.people_rounded,
                    label: 'Crowd',
                    value: cl,
                    valueColor: cc),
                _InfoRow(
                    icon: Icons.linear_scale_rounded,
                    label: 'Queue',
                    value: ql),
                if (club.tonightDj != null)
                  _InfoRow(
                      icon: Icons.headphones_rounded,
                      label: "Tonight's DJ",
                      value: club.tonightDj!,
                      valueColor: const Color(0xFFDD6BFF)),
                _InfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Tickets',
                    value: club.ticketsAvailable ? 'Available' : 'Sold Out',
                    valueColor: club.ticketsAvailable
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFFF6B6B)),
                _InfoRow(
                    icon: Icons.table_bar_rounded,
                    label: 'Tables',
                    value: club.tablesAvailable
                        ? 'Available'
                        : 'Not Available',
                    valueColor: club.tablesAvailable
                        ? const Color(0xFF4ADE80)
                        : Colors.white54),
                if (club.offer != null)
                  _InfoRow(
                      icon: Icons.local_offer_rounded,
                      label: 'Offer',
                      value: club.offer!,
                      valueColor: const Color(0xFFFFAA3E)),
                _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Last Updated',
                    value: club.lastUpdated),
              ],
            ),
          ),

          SizedBox(height: 24 + bottom),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 17,
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
