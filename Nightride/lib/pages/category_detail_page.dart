// lib/pages/category_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';

// ── Per-category identity ─────────────────────────────────────────────────────

const _kInfo = <String, _Info>{
  'CLUB':   _Info(Icons.nightlife_rounded,   Color(0xFFDD6BFF), Color(0xFF6B1FA8),
      'The hottest clubs tonight — live lineups, crowd levels & exclusive tables.'),
  'DJ':     _Info(Icons.headphones_rounded,  Color(0xFFFF6BAD), Color(0xFFA01060),
      'World-class DJs spinning deep house to hard techno. Find your set.'),
  'TECHNO': _Info(Icons.graphic_eq_rounded,  Color(0xFF5BB8FF), Color(0xFF1040A8),
      'Relentless kicks and hypnotic grooves. The purest form of electronic music.'),
  'RAVE':   _Info(Icons.flare_rounded,       Color(0xFF3EECD4), Color(0xFF097A67),
      'Underground raves, warehouse parties and open-air events. Pure energy.'),
  'EDM':    _Info(Icons.music_note_rounded,  Color(0xFFFFAA3E), Color(0xFFA85000),
      'Big drops, massive stages and festival vibes. The sound that moved millions.'),
  'HOUSE':  _Info(Icons.speaker_rounded,     Color(0xFF5EDF8A), Color(0xFF0E6B36),
      'Soulful grooves and four-to-the-floor beats. House music never sleeps.'),
  'LIVE':   _Info(Icons.mic_rounded,         Color(0xFFFF6B6B), Color(0xFFA01010),
      'Live bands, acoustic sets and raw performances. Real instruments, real energy.'),
};

const _kBg = <String, String>{
  'CLUB':   'https://images.unsplash.com/photo-1516981442399-a91139e20ff8?auto=format&fit=crop&w=1400&q=80',
  'DJ':     'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1400&q=80',
  'TECHNO': 'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=1400&q=80',
  'RAVE':   'https://images.unsplash.com/photo-1501527459-2d5409f8cf45?auto=format&fit=crop&w=1400&q=80',
  'EDM':    'https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?auto=format&fit=crop&w=1400&q=80',
  'HOUSE':  'https://images.unsplash.com/photo-1521337706264-a414f153a5f5?auto=format&fit=crop&w=1400&q=80',
  'LIVE':   'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1400&q=80',
};

class _Info {
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final String desc;
  const _Info(this.icon, this.colorA, this.colorB, this.desc);
}

_Info _infoFor(String cat) => _kInfo[cat] ??
    const _Info(Icons.category_rounded, AppTheme.primary, AppTheme.accent,
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
  static const _tabs = ['All', 'Tonight', 'Hot'];

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

    // If Firestore has no matching events, fall back to dummy data for this category
    if (events.isEmpty) {
      events = kTrendingEvents.where((e) => e.categoryTag == widget.category).toList();
      if (events.isEmpty) events = kTrendingEvents;
    }

    switch (_tab) {
      case 1: // Tonight
        final t = events
            .where((e) =>
                e.dateText.toLowerCase().contains('tonight') ||
                e.dateText.toLowerCase().contains('today'))
            .toList();
        return t.isEmpty ? events : t;
      case 2: // Hot — sort by interested count desc
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
    final info     = _infoFor(widget.category);
    final hPad     = AppResponsive.pagePadding(context);
    final topPad   = MediaQuery.viewPaddingOf(context).top;
    final bottomPad = AppResponsive.bottomNavHeight(context) +
        MediaQuery.viewPaddingOf(context).bottom + 32;
    final events = _events();

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        ref.read(selectedCategoryProvider.notifier).state = 'ALL';
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppTheme.scaffold,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  info: info,
                  category: widget.category,
                  topPad: topPad,
                  hPad: hPad,
                  eventCount: events.length,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: _FilterRow(
                  tabs: _tabs,
                  selected: _tab,
                  info: info,
                  hPad: hPad,
                  onTap: (i) => setState(() => _tab = i),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, bottomPad),
                sliver: SliverToBoxAdapter(
                  child: events.isEmpty
                      ? _EmptyState(info: info, category: widget.category)
                      : _EventList(events: events),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final _Info info;
  final String category;
  final double topPad;
  final double hPad;
  final int eventCount;
  final VoidCallback onBack;

  const _Hero({
    required this.info,
    required this.category,
    required this.topPad,
    required this.hPad,
    required this.eventCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bgUrl = _kBg[category] ?? '';

    return SizedBox(
      height: 370 + topPad,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo background ─────────────────────────────────────────────
          if (bgUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: bgUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: info.colorB),
              errorWidget: (_, __, ___) => Container(color: info.colorB),
            ),

          // ── Dark gradient scrim ──────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.45),
                  info.colorB.withValues(alpha: 0.92),
                  AppTheme.scaffold,
                ],
                stops: const [0.0, 0.25, 0.68, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Left radial neon glow ────────────────────────────────────────
          Positioned(
            left: -90,
            top: topPad + 80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    info.colorA.withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Giant watermark icon ─────────────────────────────────────────
          Positioned(
            right: -50,
            top: topPad - 20,
            child: Icon(info.icon, size: 300,
                color: Colors.white.withValues(alpha: 0.05)),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Positioned(
            left: hPad,
            right: hPad,
            top: topPad + 8,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),

                const Spacer(),

                // Glowing icon circle
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [info.colorA, info.colorB],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: info.colorA.withValues(alpha: 0.75),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: info.colorA.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(info.icon, color: Colors.white, size: 32),
                ),
                const Gap(14),

                // Category name
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppResponsive.font(context, 46),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.5,
                    height: 1.0,
                  ),
                ),
                const Gap(10),

                // Description
                Text(
                  info.desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: AppResponsive.font(context, 13),
                    height: 1.5,
                  ),
                ),
                const Gap(18),

                // Stats chips
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.event_rounded,
                      value: '$eventCount',
                      label: 'Events',
                      color: info.colorA,
                    ),
                    const Gap(8),
                    _StatChip(
                      icon: Icons.public_rounded,
                      value: 'Global',
                      label: 'Venues',
                      color: info.colorA,
                    ),
                    const Gap(8),
                    _StatChip(
                      icon: Icons.whatshot_rounded,
                      value: 'Live',
                      label: 'Now',
                      color: info.colorA,
                    ),
                  ],
                ),
                const Gap(22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(5),
          Text(
            '$value ',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500),
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
  final _Info info;
  final double hPad;
  final ValueChanged<int> onTap;

  const _FilterRow({
    required this.tabs,
    required this.selected,
    required this.info,
    required this.hPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
        separatorBuilder: (_, __) => const Gap(8),
        itemCount: tabs.length,
        itemBuilder: (ctx, i) {
          final sel = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: sel
                    ? LinearGradient(colors: [info.colorA, info.colorB])
                    : null,
                color: sel ? null : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: info.colorA.withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: sel
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.48),
                  fontSize: AppResponsive.font(context, 13.5),
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Event list ────────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<TrendingEvent> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final isLast = entry.key == events.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: _EventCard(event: entry.value),
        );
      }).toList(),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  final TrendingEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardH = AppResponsive.eventCardHeight(context);
    final pad   = AppResponsive.gap(context, 14).clamp(12.0, 16.0);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: cardH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background photo
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.white.withValues(alpha: 0.06)),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.06),
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),

              // Gradient scrim
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x14000000),
                      Color(0x4D000000),
                      Color(0xDE000000),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Category tag (top-left)
              Positioned(
                top: pad,
                left: pad,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    event.categoryTag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              // Text (bottom-left, reserves right space for button)
              Positioned(
                left: pad,
                right: pad + 84,
                bottom: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppResponsive.font(context, 16),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.72)),
                        const SizedBox(width: 4),
                        Text(
                          event.dateText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.72)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // "View" button (bottom-right)
              Positioned(
                right: pad,
                bottom: pad,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => EventDetailPage(id: event.id)),
                  ),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),

              // Hairline border
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Info info;
  final String category;
  const _EmptyState({required this.info, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: info.colorA.withValues(alpha: 0.1),
              border: Border.all(
                  color: info.colorA.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Icon(info.icon,
                color: info.colorA.withValues(alpha: 0.7), size: 38),
          ),
          const Gap(18),
          Text(
            'No $category events yet',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(8),
          Text(
            'Check back soon — events are added daily',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
