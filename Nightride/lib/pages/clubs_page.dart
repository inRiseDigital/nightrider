// lib/pages/clubs_page.dart
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/data/live_hub_dummy_data.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/providers/live_hub_providers.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
class _P {
  static const bg      = Color(0xFF070707);
  static const surface = Color(0xFF0F0F0F);
  static const card    = Color(0xFF0D0D0D);
  static const dark    = Color(0xFF111111);
  static const border  = Color(0xFF252525);
  static const cream   = Color(0xFFF3EAD6);
  static const lime    = Color(0xFFDFFF2F);
  static const pink    = Color(0xFFFF3D73);
  static const teal    = Color(0xFF62D6C8);
  static const amber   = Color(0xFFFBBF24);
  static const white   = Color(0xFFFAFAFA);
}

// ── Status / crowd helpers ───────────────────────────────────────────────────
Color _statusColor(ClubStatus s) => switch (s) {
      ClubStatus.open    => _P.lime,
      ClubStatus.closed  => const Color(0xFF444444),
      ClubStatus.vipOnly => _P.teal,
      ClubStatus.soldOut => _P.pink,
    };

String _statusLabel(ClubStatus s) => switch (s) {
      ClubStatus.open    => 'OPEN',
      ClubStatus.closed  => 'CLOSED',
      ClubStatus.vipOnly => 'VIP ONLY',
      ClubStatus.soldOut => 'SOLD OUT',
    };

Color _crowdColor(CrowdLevel c) => switch (c) {
      CrowdLevel.empty    => const Color(0xFF444444),
      CrowdLevel.quiet    => _P.teal,
      CrowdLevel.moderate => _P.amber,
      CrowdLevel.busy     => _P.lime,
      CrowdLevel.packed   => _P.pink,
    };

String _crowdLabel(CrowdLevel c) => switch (c) {
      CrowdLevel.empty    => 'EMPTY',
      CrowdLevel.quiet    => 'QUIET',
      CrowdLevel.moderate => 'MODERATE',
      CrowdLevel.busy     => 'BUSY',
      CrowdLevel.packed   => 'PACKED',
    };

String _queueLabel(QueueStatus q) => switch (q) {
      QueueStatus.noQueue  => 'No queue',
      QueueStatus.short    => '~10 min',
      QueueStatus.moderate => '~30 min',
      QueueStatus.long     => '45+ min',
      QueueStatus.closed   => 'Closed',
    };

// ════════════════════════════════════════════════════════════════════════════
// ClubsPage
// ════════════════════════════════════════════════════════════════════════════

class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage>
    with TickerProviderStateMixin {
  ClubStatus? _filter;

  late final AnimationController _pulse;
  late final AnimationController _dotPulse;
  late final AnimationController _scanline;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scanline = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _dotPulse.dispose();
    _scanline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async       = ref.watch(clubUpdatesProvider);
    final firestoreClubs = async.asData?.value ?? [];
    final all         = firestoreClubs.isNotEmpty ? firestoreClubs : kClubUpdates;
    final clubs       = _filter == null
        ? all
        : all.where((c) => c.status == _filter).toList();

    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          // Background glow blobs
          const Positioned.fill(child: _Background()),

          // Scan-line overlay
          Positioned.fill(
            child: _ScanlineOverlay(controller: _scanline),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(pulse: _pulse, dotPulse: _dotPulse),
                const SizedBox(height: 16),
                _FilterRow(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: clubs.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16, 0, 16,
                            MediaQuery.viewPaddingOf(context).bottom + 40,
                          ),
                          itemCount: clubs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (ctx, i) => _ClubCard(
                            club: clubs[i],
                            pulse: _pulse,
                          ),
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

// ── Background glow blobs ─────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: _P.bg),
        Positioned(
          top: -120, left: -80,
          child: _Blob(size: 360,
              color: _P.lime.withValues(alpha: 0.05)),
        ),
        Positioned(
          top: 240, right: -100,
          child: _Blob(size: 300,
              color: _P.pink.withValues(alpha: 0.06)),
        ),
        Positioned(
          bottom: 40, left: -60,
          child: _Blob(size: 260,
              color: _P.teal.withValues(alpha: 0.04)),
        ),
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
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ── Scan-line overlay ─────────────────────────────────────────────────────

class _ScanlineOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanlineOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => IgnorePointer(
        child: CustomPaint(
          painter: _ScanlinePainter(controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFDFFF2F).withValues(alpha: 0.022),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 50, size.width, 100));
    canvas.drawRect(
        Rect.fromLTWH(0, y - 50, size.width, 100), sweepPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.010)
      ..strokeWidth = 0.5;
    for (double ly = 0; ly < size.height; ly += 4) {
      canvas.drawLine(
          Offset(0, ly), Offset(size.width, ly), linePaint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}

// ── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.pulse, required this.dotPulse});
  final Animation<double> pulse;
  final Animation<double> dotPulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _P.border, width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _P.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // Pulsing red dot (retro-nightlife feel — red not lime)
          AnimatedBuilder(
            animation: dotPulse,
            builder: (_, __) => Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.pink,
                boxShadow: [
                  BoxShadow(
                    color: _P.pink.withValues(
                        alpha: 0.25 + 0.55 * dotPulse.value),
                    blurRadius: 5 + 10 * dotPulse.value,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Text(
            'CLUBS',
            style: GoogleFonts.anton(
              color: _P.cream,
              fontSize: 28,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),

          // LIVE badge
          AnimatedBuilder(
            animation: dotPulse,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _P.pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: _P.pink.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _P.pink,
                      boxShadow: [
                        BoxShadow(
                          color: _P.pink.withValues(
                              alpha: 0.3 + 0.5 * dotPulse.value),
                          blurRadius: 4 + 5 * dotPulse.value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE',
                      style: GoogleFonts.anton(
                          color: _P.pink,
                          fontSize: 11,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter row ────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});
  final ClubStatus? selected;
  final ValueChanged<ClubStatus?> onSelected;

  static const _items = <(String, ClubStatus?, Color)>[
    ('ALL',      null,                _P.lime),
    ('PACKED',   ClubStatus.open,     _P.pink),
    ('BUSY',     ClubStatus.vipOnly,  _P.lime),
    ('QUIET',    ClubStatus.soldOut,  _P.teal),
    ('CLOSED',   ClubStatus.closed,   Color(0xFF555555)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? color.withValues(alpha: 0.12)
                    : _P.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: 0.6)
                      : _P.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.anton(
                  color: active ? color : Colors.white30,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Club card (sticker style) ─────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.pulse});
  final ClubUpdate club;
  final Animation<double> pulse;

  bool get _isLive => club.status == ClubStatus.open;

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(club.status);
    final sl = _statusLabel(club.status);
    final cc = _crowdColor(club.crowdLevel);
    final cl = _crowdLabel(club.crowdLevel);
    final ql = _queueLabel(club.queueStatus);
    final filled = club.crowdLevel.index + 1;
    final total  = CrowdLevel.values.length;

    return GestureDetector(
      onTap: () => _ClubDetailSheet.show(context, club),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, child) {
          final glowAlpha =
              _isLive ? (0.14 + 0.20 * pulse.value) : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isLive
                  ? [
                      BoxShadow(
                        color: sc.withValues(alpha: glowAlpha),
                        blurRadius: 14 + 10 * pulse.value,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    club.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: club.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: sc.withValues(alpha: 0.06)),
                            errorWidget: (_, __, ___) => Container(
                                color: sc.withValues(alpha: 0.06)),
                          )
                        : Container(
                            color: sc.withValues(alpha: 0.06)),

                    // Gradient
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0xF2070707),
                          ],
                          stops: [0.1, 1.0],
                        ),
                      ),
                    ),

                    // Left accent bar
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(width: 3, color: sc),
                    ),

                    // Status sticker (top-left)
                    Positioned(
                      top: 10, left: 14,
                      child: _StickerBadge(
                          label: sl, color: sc, dot: true),
                    ),

                    // LIVE badge + timestamp (top-right)
                    Positioned(
                      top: 10, right: 12,
                      child: Row(
                        children: [
                          _StickerBadge(
                              label: 'LIVE', color: _P.pink),
                          const SizedBox(width: 6),
                          Text(club.lastUpdated,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    // Club name + location (bottom)
                    Positioned(
                      bottom: 10, left: 14, right: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              club.clubName.toUpperCase(),
                              style: GoogleFonts.anton(
                                  color: _P.white,
                                  fontSize: 20,
                                  letterSpacing: 1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${club.city} · ${club.country}'.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        _Pill(label: cl, color: cc,
                            icon: Icons.people_rounded),
                        const SizedBox(width: 7),
                        _Pill(label: ql, color: Colors.white38,
                            icon: Icons.linear_scale_rounded),
                        if (club.tonightDj != null) ...[
                          const SizedBox(width: 7),
                          Expanded(
                            child: _Pill(
                              label: club.tonightDj!,
                              color: _P.teal,
                              icon: Icons.headphones_rounded,
                              expand: true,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.18),
                          size: 12,
                        ),
                      ],
                    ),

                    // Crowd bar
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('CROWD',
                            style: GoogleFonts.anton(
                                color: Colors.white24,
                                fontSize: 9,
                                letterSpacing: 1.2)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: List.generate(
                              total,
                              (i) => Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.only(
                                      right: 3),
                                  decoration: BoxDecoration(
                                    color: i < filled
                                        ? cc
                                        : Colors.white
                                            .withValues(alpha: 0.06),
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pill / tag helpers ────────────────────────────────────────────────────

class _StickerBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  const _StickerBadge(
      {required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: GoogleFonts.anton(
                  color: color, fontSize: 9, letterSpacing: 0.8)),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: color.withValues(alpha: 0.26), width: 0.8),
      ),
      child: Row(
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
                        fontWeight: FontWeight.w800),
                  ),
                )
              : Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nightlife_rounded,
              color: Colors.white.withValues(alpha: 0.08), size: 56),
          const SizedBox(height: 16),
          Text(
            'NO CLUBS MATCH THIS FILTER',
            style: GoogleFonts.anton(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Club detail bottom sheet ──────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final sc     = _statusColor(club.status);
    final sl     = _statusLabel(club.status);
    final cc     = _crowdColor(club.crowdLevel);
    final cl     = _crowdLabel(club.crowdLevel);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: sc.withValues(alpha: 0.4), width: 1.5),
          left: BorderSide(color: _P.border, width: 1),
          right: BorderSide(color: _P.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 36, height: 3,
            decoration: BoxDecoration(
                color: _P.border,
                borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 18),

          // Photo header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (club.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: club.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(
                                color:
                                    sc.withValues(alpha: 0.08)),
                      )
                    else
                      Container(
                          color: sc.withValues(alpha: 0.08)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(width: 3, color: sc),
                    ),
                    Positioned(
                      left: 14, right: 14, bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StickerBadge(
                              label: sl, color: sc, dot: true),
                          const SizedBox(height: 6),
                          Text(
                            club.clubName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.anton(
                              color: _P.white,
                              fontSize: 22,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${club.city} · ${club.country}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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
          const SizedBox(height: 18),

          // Info rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    value: _queueLabel(club.queueStatus)),
                if (club.tonightDj != null)
                  _InfoRow(
                      icon: Icons.headphones_rounded,
                      label: "Tonight's DJ",
                      value: club.tonightDj!,
                      valueColor: _P.teal),
                _InfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Tickets',
                    value: club.ticketsAvailable
                        ? 'Available'
                        : 'Sold Out',
                    valueColor: club.ticketsAvailable
                        ? _P.lime
                        : _P.pink),
                _InfoRow(
                    icon: Icons.table_bar_rounded,
                    label: 'Tables',
                    value: club.tablesAvailable
                        ? 'Available'
                        : 'Not Available',
                    valueColor: club.tablesAvailable
                        ? _P.lime
                        : Colors.white38),
                if (club.offer != null)
                  _InfoRow(
                      icon: Icons.local_offer_rounded,
                      label: 'Offer',
                      value: club.offer!,
                      valueColor: _P.lime),
                _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Last Updated',
                    value: club.lastUpdated),
              ],
            ),
          ),

          SizedBox(height: 20 + bottom),
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
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _P.dark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _P.border, width: 1),
            ),
            child: Icon(icon, size: 16, color: Colors.white30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: GoogleFonts.anton(
                        color: Colors.white30,
                        fontSize: 9,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: valueColor ?? _P.white,
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
