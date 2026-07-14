import 'package:cached_network_image/cached_network_image.dart';
import 'package:nightride/components/nightrite_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

// ── Retro Nightlife Palette ──────────────────────────────────────────────────
const _kBg       = Color(0xFF070707);
const _kSurface  = Color(0xFF0F0F0F);
const _kDarkGray = Color(0xFF151515);
const _kBorder   = Color(0xFF2A2A2A);
const _kBorderLt = Color(0xFF3A3A3A);
const _kCream    = Color(0xFFF3EAD6);
const _kLime     = Color(0xFFDFFF2F);
const _kPink     = Color(0xFFFF3D73);
const _kTeal     = Color(0xFF62D6C8);
const _kWhite    = Color(0xFFFAFAFA);

// ── Filter tab index provider (local) ────────────────────────────────────────
final _filterProvider = StateProvider<int>((_) => 0);

class FavouritesPage extends ConsumerWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favouritesStreamProvider);
    final user     = ref.watch(authStateProvider).asData?.value;
    final tabIndex = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _Header(),

            // ── Filter pills ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  _FilterPill(label: 'PLACES', index: 0, selected: tabIndex == 0),
                  const Gap(10),
                  _FilterPill(label: 'EVENTS', index: 1, selected: tabIndex == 1),
                  const Gap(10),
                  _FilterPill(label: 'PEOPLE', index: 2, selected: tabIndex == 2),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────────
            Container(
              height: 1,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kPink.withValues(alpha: 0.0),
                    _kPink.withValues(alpha: 0.45),
                    _kLime.withValues(alpha: 0.45),
                    _kLime.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: user == null
                  ? const _GuestPrompt()
                  : tabIndex == 2
                      ? const _PeopleComingSoon()
                      : NightRiteRefresh(
                          onRefresh: () async {
                            ref.invalidate(favouritesStreamProvider);
                            await Future<void>.delayed(
                                const Duration(milliseconds: 600));
                          },
                          child: favAsync.when(
                            loading: () => const _ShimmerList(),
                            error: (_, __) => const _EmptyState(
                              message: 'COULD NOT LOAD\nFAVOURITES',
                              showExplore: false,
                            ),
                            data: (favs) {
                              final filtered = tabIndex == 0
                                  ? favs
                                      .where((f) =>
                                          (f['type'] as String?)
                                              ?.toLowerCase() ==
                                          'place')
                                      .toList()
                                  : favs
                                      .where((f) =>
                                          (f['type'] as String?)
                                              ?.toLowerCase() !=
                                          'place')
                                      .toList();

                              if (filtered.isEmpty) {
                                return const _EmptyState(
                                  message: 'YOUR NIGHT\nSTARTS HERE',
                                  showExplore: true,
                                );
                              }

                              return ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Gap(12),
                                itemBuilder: (context, i) =>
                                    _FavCard(fav: filtered[i]),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'FAVOURITES ',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 36)
                          .clamp(28.0, 42.0),
                      color: _kCream,
                      letterSpacing: 2.5,
                      height: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: '♥',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 34)
                          .clamp(26.0, 40.0),
                      color: _kPink,
                      letterSpacing: 0,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Pill ───────────────────────────────────────────────────────────────
class _FilterPill extends ConsumerWidget {
  const _FilterPill({
    required this.label,
    required this.index,
    required this.selected,
  });
  final String label;
  final int    index;
  final bool   selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(_filterProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kLime : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? _kLime : _kBorderLt,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.anton(
            fontSize: 13,
            color: selected ? Colors.black : _kWhite.withValues(alpha: 0.70),
            letterSpacing: 1.4,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

// ── Favourite Card ────────────────────────────────────────────────────────────
class _FavCard extends ConsumerWidget {
  const _FavCard({required this.fav});
  final Map<String, dynamic> fav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title    = fav['name']        as String? ?? fav['title'] as String? ?? '';
    final String image    = fav['cover_image'] as String? ?? '';
    final String city     = fav['city']        as String? ?? '';
    final String date     = fav['date']        as String? ?? '';
    final String genre    = fav['genre']       as String? ?? '';
    final String category = fav['category']    as String? ?? genre;
    final String address  = fav['address']     as String? ?? city;
    final String id       = fav['id']          as String? ?? '';
    final bool   isPlace  = (fav['type'] as String?)?.toLowerCase() == 'place';

    final daysLeft = _daysUntil(date);

    return GestureDetector(
      onTap: id.isEmpty
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventDetailPage(id: id)),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 84,
                      height: 84,
                      color: _kDarkGray,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: _kDarkGray,
                      alignment: Alignment.center,
                      child: Icon(
                        isPlace
                            ? Icons.place_rounded
                            : Icons.music_note_rounded,
                        color: _kBorderLt,
                        size: 32,
                      ),
                    ),
                  ),
                  // subtle gradient overlay on thumbnail
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(14),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.anton(
                        fontSize: 16,
                        color: _kWhite,
                        letterSpacing: 0.5,
                        height: 1.15,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const Gap(4),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: _kTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(5),
                          Flexible(
                            child: Text(
                              category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.anton(
                                fontSize: 11,
                                color: _kTeal,
                                letterSpacing: 1.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (address.isNotEmpty) ...[
                      const Gap(3),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _kWhite.withValues(alpha: 0.45),
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (!isPlace && daysLeft != null) ...[
                      const Gap(6),
                      _DaysChip(daysLeft: daysLeft),
                    ],
                  ],
                ),
              ),
            ),

            // ── Unfavourite button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.favorite_rounded, color: _kPink, size: 24),
                splashRadius: 22,
                tooltip: 'Remove from favourites',
                onPressed: () async {
                  final u = ref.read(authStateProvider).asData?.value;
                  if (u == null || id.isEmpty) return;
                  await ref.read(favouritesServiceProvider).remove(u.uid, id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _daysUntil(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return null;
    final today = DateTime.now();
    final diff = DateTime(dt.year, dt.month, dt.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return diff < 0 ? null : diff;
  }
}

// ── Days chip ─────────────────────────────────────────────────────────────────
class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final String label = daysLeft == 0
        ? 'TONIGHT'
        : daysLeft == 1
            ? 'TOMORROW'
            : '$daysLeft DAYS AWAY';
    final bool urgent = daysLeft <= 3;
    final Color col   = urgent ? _kLime : _kBorderLt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: urgent ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.50), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.anton(
          fontSize: 10,
          color: col,
          letterSpacing: 1.0,
          height: 1.1,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.message, required this.showExplore});
  final String message;
  final bool   showExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot / logo with pink glow ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withValues(alpha: 0.18),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                color: _kWhite.withValues(alpha: 0.30),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
            const Gap(28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 28,
                color: _kCream,
                letterSpacing: 2.0,
                height: 1.15,
              ),
            ),
            if (showExplore) ...[
              const Gap(10),
              Text(
                'TAP THE HEART ON ANY EVENT OR PLACE TO SAVE IT HERE',
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: 11,
                  color: _kWhite.withValues(alpha: 0.38),
                  letterSpacing: 1.2,
                  height: 1.5,
                ),
              ),
              const Gap(32),
              GestureDetector(
                onTap: () => ref.read(appNavProvider.notifier).setIndex(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'EXPLORE EVENTS',
                    style: GoogleFonts.anton(
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 2.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── People coming soon ────────────────────────────────────────────────────────
class _PeopleComingSoon extends StatelessWidget {
  const _PeopleComingSoon();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with teal glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _kTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kTeal.withValues(alpha: 0.30),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kTeal.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_rounded,
                color: _kTeal,
                size: 44,
              ),
            ),
            const Gap(28),
            Text(
              'YOUR CREW',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 30,
                color: _kCream,
                letterSpacing: 2.5,
                height: 1.0,
              ),
            ),
            const Gap(6),
            Text(
              'COMING SOON',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 16,
                color: _kLime,
                letterSpacing: 3.5,
                height: 1.1,
              ),
            ),
            const Gap(20),
            Text(
              'Friends & crew features are in the works.\nYour squad is almost here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _kWhite.withValues(alpha: 0.40),
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest sign-in prompt ──────────────────────────────────────────────────────
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pink glow heart circle
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _kPink.withValues(alpha: 0.09),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kPink.withValues(alpha: 0.38),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPink.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded, color: _kPink, size: 42),
            ),
            const Gap(26),
            Text(
              'SIGN IN TO SAVE\nYOUR NIGHTS',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 26,
                color: _kCream,
                letterSpacing: 1.8,
                height: 1.15,
              ),
            ),
            const Gap(12),
            Text(
              'Create a free account to bookmark events,\ntrack your favourites and get reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _kWhite.withValues(alpha: 0.48),
                height: 1.65,
              ),
            ),
            const Gap(34),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.30),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Text(
                    'SIGN IN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.anton(
                      fontSize: 15,
                      color: Colors.black,
                      letterSpacing: 3.0,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(16),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignInPage()),
              ),
              child: Text(
                "Don't have an account?  Sign up free",
                style: TextStyle(
                  fontSize: 12,
                  color: _kTeal,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.60)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, __) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (_, __) => Container(
          height: 84,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              // thumbnail slab
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft:    Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: Container(
                  width: 84,
                  height: 84,
                  color: _kDarkGray.withValues(alpha: _anim.value),
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: _kBorderLt.withValues(alpha: _anim.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: _kBorderLt.withValues(alpha: _anim.value * 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(6),
                    Container(
                      height: 9,
                      width: 120,
                      decoration: BoxDecoration(
                        color: _kBorderLt.withValues(alpha: _anim.value * 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // heart placeholder
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.favorite_rounded,
                  color: _kPink.withValues(alpha: _anim.value * 0.4),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
