// lib/pages/live_hub_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/domain/live_hub_models.dart';
import 'package:nightride/providers/live_hub_providers.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
class _P {
  static const bg      = Color(0xFF070707);
  static const surface = Color(0xFF0F0F0F);
  static const dark    = Color(0xFF111111);
  static const card    = Color(0xFF0D0D0D);
  static const border  = Color(0xFF252525);
  static const cream   = Color(0xFFF3EAD6);
  static const lime    = Color(0xFFDFFF2F);
  static const pink    = Color(0xFFFF3D73);
  static const teal    = Color(0xFF62D6C8);
  static const white   = Color(0xFFFAFAFA);
  static const amber   = Color(0xFFFBBF24);
}

// ── Crowd/Status helpers (shared across tabs) ────────────────────────────────
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

Color _statusColor(ClubStatus s) => switch (s) {
      ClubStatus.open     => _P.lime,
      ClubStatus.closed   => const Color(0xFF444444),
      ClubStatus.vipOnly  => _P.teal,
      ClubStatus.soldOut  => _P.pink,
    };

String _statusLabel(ClubStatus s) => switch (s) {
      ClubStatus.open     => 'OPEN',
      ClubStatus.closed   => 'CLOSED',
      ClubStatus.vipOnly  => 'VIP ONLY',
      ClubStatus.soldOut  => 'SOLD OUT',
    };

String _queueLabel(QueueStatus q) => switch (q) {
      QueueStatus.noQueue  => 'No Queue',
      QueueStatus.short    => '~10 min',
      QueueStatus.moderate => '~30 min',
      QueueStatus.long     => '45+ min',
      QueueStatus.closed   => 'Closed',
    };

// ════════════════════════════════════════════════════════════════════════════
// LiveHubPage
// ════════════════════════════════════════════════════════════════════════════

class LiveHubPage extends ConsumerStatefulWidget {
  const LiveHubPage({super.key});

  @override
  ConsumerState<LiveHubPage> createState() => _LiveHubPageState();
}

class _LiveHubPageState extends ConsumerState<LiveHubPage>
    with TickerProviderStateMixin {
  late final TabController _tab;
  late final AnimationController _dotPulse;
  late final AnimationController _scanline;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scanline = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tab.dispose();
    _dotPulse.dispose();
    _scanline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.bg,
      body: Stack(
        children: [
          // Subtle scan-line shimmer across entire page
          _ScanlineOverlay(controller: _scanline),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Gap(10),
                _buildCountryFilter(),
                const Gap(6),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: const [
                      _ClubUpdatesTab(),
                      _UserReportsTab(),
                      _SocialTrackingTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _P.border, width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _P.white, size: 16),
            ),
          ),
          const Gap(12),

          // Pulsing red dot
          AnimatedBuilder(
            animation: _dotPulse,
            builder: (_, __) => Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _P.pink,
                boxShadow: [
                  BoxShadow(
                    color: _P.pink.withValues(
                        alpha: 0.3 + 0.6 * _dotPulse.value),
                    blurRadius: 6 + 10 * _dotPulse.value,
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),

          // Title
          Expanded(
            child: Text(
              'LIVE RIGHT NOW',
              style: GoogleFonts.anton(
                color: _P.cream,
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // LIVE badge
          AnimatedBuilder(
            animation: _dotPulse,
            builder: (_, __) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _P.pink,
                      boxShadow: [
                        BoxShadow(
                          color: _P.pink.withValues(
                              alpha: 0.3 + 0.5 * _dotPulse.value),
                          blurRadius: 4 + 5 * _dotPulse.value,
                        ),
                      ],
                    ),
                  ),
                  const Gap(6),
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

  // ── Country filter ─────────────────────────────────────────────────────────
  Widget _buildCountryFilter() {
    final countries = ref.watch(liveHubAvailableCountriesProvider);
    final selected  = ref.watch(liveHubCountryProvider);
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CountryPill(
            label: 'ALL',
            active: selected == 'ALL',
            onTap: () =>
                ref.read(liveHubCountryProvider.notifier).state = 'ALL',
          ),
          ...countries.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _CountryPill(
                  label: c,
                  active: selected == c,
                  onTap: () =>
                      ref.read(liveHubCountryProvider.notifier).state = c,
                ),
              )),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _P.border, width: 1),
        ),
        child: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: _P.dark,
            borderRadius: BorderRadius.circular(7),
            border:
                Border.all(color: _P.lime.withValues(alpha: 0.5), width: 1),
          ),
          labelColor: _P.lime,
          unselectedLabelColor: Colors.white30,
          labelStyle:
              GoogleFonts.anton(fontSize: 11, letterSpacing: 1.2),
          unselectedLabelStyle:
              GoogleFonts.anton(fontSize: 11, letterSpacing: 1.2),
          tabs: const [
            Tab(icon: Icon(Icons.nightlife_rounded, size: 14), text: 'CLUBS'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 14), text: 'REPORTS'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 14), text: 'SOCIAL'),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab 1 — Club Updates
// ════════════════════════════════════════════════════════════════════════════

class _ClubUpdatesTab extends ConsumerWidget {
  const _ClubUpdatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clubUpdatesProvider);
    return async.when(
      loading: () => const _RetroLoader(),
      error: (e, _) => _RetroError(message: '$e'),
      data: (items) {
        if (items.isEmpty) {
          return const _RetroEmpty(
              label: 'NO CLUB UPDATES YET',
              icon: Icons.nightlife_rounded);
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const Gap(14),
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return const _SectionHeader(
                  label: 'CLUB UPDATES', color: _P.lime);
            }
            return _ClubStickerCard(club: items[i - 1]);
          },
        );
      },
    );
  }
}

// ── Club sticker card ──────────────────────────────────────────────────────

class _ClubStickerCard extends StatelessWidget {
  final ClubUpdate club;
  const _ClubStickerCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final sc  = _statusColor(club.status);
    final sl  = _statusLabel(club.status);
    final cc  = _crowdColor(club.crowdLevel);
    final cl  = _crowdLabel(club.crowdLevel);
    final filled = club.crowdLevel.index + 1;
    final total  = CrowdLevel.values.length;

    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: sc.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with sticker overlays
          SizedBox(
            height: 136,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                club.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: club.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: sc.withValues(alpha: 0.06)),
                        errorWidget: (_, __, ___) =>
                            Container(color: sc.withValues(alpha: 0.06)),
                      )
                    : Container(color: sc.withValues(alpha: 0.06)),

                // Dark gradient
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Color(0xF0070707),
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

                // Top-left: status sticker
                Positioned(
                  top: 10, left: 14,
                  child: _StickerBadge(label: sl, color: sc, dot: true),
                ),

                // Top-right: LIVE + time
                Positioned(
                  top: 10, right: 12,
                  child: Row(
                    children: [
                      _StickerBadge(label: 'LIVE', color: _P.pink),
                      const Gap(6),
                      Text(club.lastUpdated,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

                // Bottom: club name + location
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
                              fontSize: 19,
                              letterSpacing: 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '${club.city}, ${club.country}'.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge row
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _RetroTag(label: cl, color: cc),
                    _RetroTag(
                        label: _queueLabel(club.queueStatus),
                        color: Colors.white38),
                    _RetroTag(
                        label: club.ticketsAvailable
                            ? 'TICKETS AVL'
                            : 'SOLD OUT',
                        color: club.ticketsAvailable ? _P.teal : _P.pink),
                  ],
                ),

                // DJ row
                if (club.tonightDj != null) ...[
                  const Gap(10),
                  Row(
                    children: [
                      const Icon(Icons.headphones_rounded,
                          color: _P.teal, size: 12),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          'TONIGHT: ${club.tonightDj!.toUpperCase()}',
                          style: GoogleFonts.anton(
                              color: _P.teal,
                              fontSize: 12,
                              letterSpacing: 0.8),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Offer row
                if (club.offer != null) ...[
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _P.lime.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _P.lime.withValues(alpha: 0.25),
                          width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer_rounded,
                            color: _P.lime, size: 11),
                        const Gap(6),
                        Flexible(
                          child: Text(club.offer!,
                              style: const TextStyle(
                                  color: _P.lime,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],

                const Gap(12),

                // Crowd bar
                Row(
                  children: [
                    Text('CROWD',
                        style: GoogleFonts.anton(
                            color: Colors.white24,
                            fontSize: 9,
                            letterSpacing: 1.2)),
                    const Gap(10),
                    Expanded(
                      child: Row(
                        children: List.generate(total, (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: i < filled
                                  ? cc
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                      ),
                    ),
                    const Gap(8),
                    Text(cl,
                        style: TextStyle(
                            color: cc,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab 2 — User Reports
// ════════════════════════════════════════════════════════════════════════════

class _UserReportsTab extends ConsumerStatefulWidget {
  const _UserReportsTab();

  @override
  ConsumerState<_UserReportsTab> createState() => _UserReportsTabState();
}

class _UserReportsTabState extends ConsumerState<_UserReportsTab> {
  static const _tags = [
    '🔥 Fire', '😤 Packed', '😎 Chill',
    '🎵 Music Good', '🚨 Avoid',
  ];

  String? _selectedTag;
  int _vibeRating = 0;
  bool _submitting = false;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTag == null || _vibeRating == 0) return;
    setState(() => _submitting = true);
    try {
      await ref.read(liveHubServiceProvider).submitReport(
            clubName: 'Your Club',
            city: 'Your City',
            country: 'Sri Lanka',
            username: 'You',
            avatarUrl: 'https://i.pravatar.cc/150?img=70',
            tag: _selectedTag!,
            vibeRating: _vibeRating,
            comment: _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          );
      setState(() {
        _selectedTag = null;
        _vibeRating  = 0;
        _commentCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('REPORT SUBMITTED!',
              style: GoogleFonts.anton(
                  color: _P.bg, fontSize: 13, letterSpacing: 1)),
          backgroundColor: _P.lime,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(userReportsProvider);
    return Column(
      children: [
        // Submit panel
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _P.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3, height: 14,
                    color: _P.lime,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text('SUBMIT A LIVE REPORT',
                      style: GoogleFonts.anton(
                          color: _P.lime,
                          fontSize: 13,
                          letterSpacing: 1.2)),
                ],
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  final active = _selectedTag == tag;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTag = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? _P.lime.withValues(alpha: 0.10)
                            : _P.dark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? _P.lime.withValues(alpha: 0.55)
                              : _P.border,
                        ),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                              color: active ? _P.lime : Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
              const Gap(10),
              Row(
                children: [
                  Text('VIBE:',
                      style: GoogleFonts.anton(
                          color: Colors.white30,
                          fontSize: 10,
                          letterSpacing: 1.2)),
                  const Gap(8),
                  ...List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => _vibeRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            i < _vibeRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color:
                                i < _vibeRating ? _P.lime : Colors.white.withValues(alpha: 0.18),
                            size: 22,
                          ),
                        ),
                      )),
                ],
              ),
              const Gap(10),
              TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: _P.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.18), fontSize: 13),
                  filled: true,
                  fillColor: _P.dark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _P.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _P.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: _P.lime.withValues(alpha: 0.5))),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const Gap(10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedTag != null &&
                          _vibeRating > 0 &&
                          !_submitting)
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.lime,
                    disabledBackgroundColor:
                        _P.lime.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: _P.bg, strokeWidth: 2))
                      : Text('SUBMIT REPORT',
                          style: GoogleFonts.anton(
                              color: _P.bg,
                              fontSize: 13,
                              letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
        const Gap(6),
        Expanded(
          child: async.when(
            loading: () => const _RetroLoader(),
            error: (e, _) => _RetroError(message: '$e'),
            data: (reports) {
              if (reports.isEmpty) {
                return const _RetroEmpty(
                    label: 'NO REPORTS YET. BE FIRST!',
                    icon: Icons.people_alt_rounded);
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: reports.length + 1,
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return const _SectionHeader(
                        label: 'COMMUNITY REPORTS',
                        color: _P.teal);
                  }
                  return _ReportStickerCard(
                      report: reports[i - 1]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Report sticker card ────────────────────────────────────────────────────

class _ReportStickerCard extends ConsumerStatefulWidget {
  final UserReport report;
  const _ReportStickerCard({required this.report});

  @override
  ConsumerState<_ReportStickerCard> createState() =>
      _ReportStickerCardState();
}

class _ReportStickerCardState
    extends ConsumerState<_ReportStickerCard> {
  bool _upvoted = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(r.avatarUrl),
                backgroundColor: _P.dark,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.username.toUpperCase(),
                        style: GoogleFonts.anton(
                            color: _P.white,
                            fontSize: 13,
                            letterSpacing: 0.8)),
                    Text(
                      '${r.clubName} · ${r.city} · ${r.timeAgo}',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Upvote button
              GestureDetector(
                onTap: () {
                  if (!_upvoted) {
                    ref
                        .read(liveHubServiceProvider)
                        .upvoteReport(r.id);
                  }
                  setState(() => _upvoted = !_upvoted);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _upvoted
                        ? _P.lime.withValues(alpha: 0.10)
                        : _P.dark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _upvoted
                            ? _P.lime.withValues(alpha: 0.45)
                            : _P.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _upvoted
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        color: _upvoted
                            ? _P.lime
                            : Colors.white30,
                        size: 13,
                      ),
                      const Gap(4),
                      Text(
                        '${r.upvotes + (_upvoted ? 1 : 0)}',
                        style: TextStyle(
                            color: _upvoted
                                ? _P.lime
                                : Colors.white30,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),

          // Tag + stars
          Row(
            children: [
              _RetroTag(label: r.tag, color: _P.teal),
              const Gap(8),
              Row(
                children: List.generate(5, (i) => Icon(
                      i < r.vibeRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < r.vibeRating
                          ? _P.lime
                          : Colors.white.withValues(alpha: 0.12),
                      size: 14,
                    )),
              ),
            ],
          ),

          // Comment
          if (r.comment != null) ...[
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _P.border, width: 0.6),
              ),
              child: Text(r.comment!,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.45)),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Tab 3 — Social Events
// ════════════════════════════════════════════════════════════════════════════

class _SocialTrackingTab extends ConsumerWidget {
  const _SocialTrackingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(socialEventsProvider);
    return async.when(
      loading: () => const _RetroLoader(),
      error: (e, _) => _RetroError(message: '$e'),
      data: (items) {
        if (items.isEmpty) {
          return const _RetroEmpty(
              label: 'NO SOCIAL EVENTS YET',
              icon: Icons.auto_awesome_rounded);
        }
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const Gap(14),
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return const _SectionHeader(
                  label: 'SOCIAL EVENTS', color: _P.pink);
            }
            return _SocialEventCard(event: items[i - 1]);
          },
        );
      },
    );
  }
}

class _SocialEventCard extends StatelessWidget {
  final SocialEvent event;
  const _SocialEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: _P.dark),
                    errorWidget: (_, __, ___) =>
                        Container(color: _P.dark),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22000000),
                          Color(0xF0070707),
                        ],
                      ),
                    ),
                  ),
                  if (event.isTrending)
                    Positioned(
                      top: 10, left: 12,
                      child: _StickerBadge(
                        label: 'TRENDING',
                        color: _P.pink,
                        leadingIcon:
                            Icons.local_fire_department_rounded,
                      ),
                    ),
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(event.source,
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title.toUpperCase(),
                    style: GoogleFonts.anton(
                        color: _P.white,
                        fontSize: 17,
                        letterSpacing: 0.8)),
                const Gap(3),
                Text(
                  '${event.clubName} · ${event.city}, ${event.country}',
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
                const Gap(10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _RetroTag(
                        label: event.date,
                        color: _P.lime,
                        icon: Icons.calendar_today_rounded),
                    _RetroTag(
                        label: event.time,
                        color: Colors.white38,
                        icon: Icons.access_time_rounded),
                    if (event.djName != null)
                      _RetroTag(
                          label: event.djName!.toUpperCase(),
                          color: _P.teal,
                          icon: Icons.headphones_rounded),
                  ],
                ),
                const Gap(12),

                // Popularity bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('POPULARITY',
                              style: GoogleFonts.anton(
                                  color: Colors.white24,
                                  fontSize: 9,
                                  letterSpacing: 1.2)),
                          const Gap(5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: event.popularityScore / 100,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.06),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                event.popularityScore > 85
                                    ? _P.pink
                                    : _P.lime,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Text(
                      '${event.popularityScore}%',
                      style: TextStyle(
                          color: event.popularityScore > 85
                              ? _P.pink
                              : _P.lime,
                          fontSize: 15,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3, height: 16, color: color,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(label,
              style: GoogleFonts.anton(
                  color: color,
                  fontSize: 13,
                  letterSpacing: 1.5)),
          const Gap(8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticker-style badge with optional dot indicator or leading icon.
class _StickerBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  final IconData? leadingIcon;
  const _StickerBadge({
    required this.label,
    required this.color,
    this.dot = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5, height: 5,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const Gap(5),
          ],
          if (leadingIcon != null) ...[
            Icon(leadingIcon!, color: color, size: 10),
            const Gap(4),
          ],
          Text(label,
              style: GoogleFonts.anton(
                  color: color, fontSize: 9, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

/// Small retro tag / pill for metadata badges.
class _RetroTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _RetroTag(
      {required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, color: color, size: 10),
            const Gap(4),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CountryPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CountryPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? _P.lime.withValues(alpha: 0.10)
              : _P.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? _P.lime.withValues(alpha: 0.55)
                : _P.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? _P.lime : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
      ),
    );
  }
}

class _RetroLoader extends StatelessWidget {
  const _RetroLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
          color: _P.lime, strokeWidth: 2),
    );
  }
}

class _RetroError extends StatelessWidget {
  final String message;
  const _RetroError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $message',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center),
      ),
    );
  }
}

class _RetroEmpty extends StatelessWidget {
  final String label;
  final IconData icon;
  const _RetroEmpty({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white10, size: 52),
          const Gap(16),
          Text(label,
              style: GoogleFonts.anton(
                  color: Colors.white.withValues(alpha: 0.20),
                  fontSize: 13,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

// ── Subtle scan-line overlay ──────────────────────────────────────────────

class _ScanlineOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanlineOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  _ScanlinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal scan band that sweeps top to bottom
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFDFFF2F).withValues(alpha: 0.025),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));
    canvas.drawRect(
        Rect.fromLTWH(0, y - 40, size.width, 80), paint);

    // Very faint repeating horizontal lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.012)
      ..strokeWidth = 0.5;
    for (double ly = 0; ly < size.height; ly += 3) {
      canvas.drawLine(Offset(0, ly), Offset(size.width, ly), linePaint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;

  bool get isComplex => false;

}
