// lib/pages/badges_collection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/badge_claim_page.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlack   = Color(0xFF070707);
const _kDark    = Color(0xFF151515);
const _kBorder  = Color(0xFF2A2A2A);
const _kLime    = Color(0xFFDFFF2F);
const _kCream   = Color(0xFFF3EAD6);
const _kWhite   = Color(0xFFFAFAFA);

// ── Badge data ────────────────────────────────────────────────────────────────

class _BadgeData {
  final String emoji;
  final String name;
  final String desc;
  const _BadgeData(this.emoji, this.name, this.desc);
}

const _kBadges = <_BadgeData>[
  _BadgeData('🏆', 'NIGHTRIDE ELITE',    'Attend 10+ parties in a month'),
  _BadgeData('🔥', 'WEEKEND WARRIOR',    '3 parties in one weekend'),
  _BadgeData('⚡', 'EARLY BIRD',         'Check in before 10 PM'),
  _BadgeData('🌀', 'RAVE BEAST',         'Attend 5 underground raves'),
  _BadgeData('🎧', 'DJ HUNTER',         'Discover 10 new DJs'),
  _BadgeData('💎', 'VIP STATUS',         'Access VIP section at any event'),
  _BadgeData('🌙', 'NIGHT OWL',          'Stay till 4 AM at any event'),
  _BadgeData('🎤', 'LIVE LEGEND',        'Attend 5 live music events'),
  _BadgeData('🚀', 'PARTY ROCKET',       'RSVP to 20 events'),
];

// First 4 are unlocked
const _kUnlockedCount = 4;

// ── Page ──────────────────────────────────────────────────────────────────────

class BadgesCollectionPage extends StatelessWidget {
  const BadgesCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad    = MediaQuery.viewPaddingOf(context).top;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBlack,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _Header(topPad: topPad),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(24),

                    // Progress banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ProgressBanner(
                        unlocked: _kUnlockedCount,
                        total: _kBadges.length,
                      ),
                    ),
                    const Gap(28),

                    // Featured unlocked badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionLabel('FEATURED BADGE'),
                    ),
                    const Gap(12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _FeaturedBadge(badge: _kBadges[0]),
                    ),
                    const Gap(28),

                    // All badges grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionLabel('ALL BADGES'),
                    ),
                    const Gap(14),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _kBadges.length,
                        itemBuilder: (context, index) => _BadgeCard(
                          badge: _kBadges[index],
                          unlocked: index < _kUnlockedCount,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────────────────────
            Container(
              color: _kBlack,
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BadgeClaimPage()),
                ),
                child: Container(
                  width: double.infinity,
                  height: AppResponsive.gap(context, 56).clamp(48.0, 62.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CLAIM NEW BADGES',
                        style: GoogleFonts.anton(
                          color: _kBlack,
                          fontSize: AppResponsive.font(context, 16),
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Gap(10),
                      const Icon(Icons.arrow_forward_rounded,
                          color: _kBlack, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _kLime,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: _kLime.withValues(alpha: 0.60),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const Gap(10),
        Text(
          text,
          style: GoogleFonts.anton(
            color: _kCream.withValues(alpha: 0.55),
            fontSize: 11,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ── Progress banner ───────────────────────────────────────────────────────────

class _ProgressBanner extends StatelessWidget {
  final int unlocked;
  final int total;
  const _ProgressBanner({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = unlocked / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 4,
                  backgroundColor: _kBorder,
                  valueColor: const AlwaysStoppedAnimation(_kLime),
                ),
                Text(
                  '$unlocked',
                  style: GoogleFonts.anton(
                    color: _kLime,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked OF $total UNLOCKED',
                  style: GoogleFonts.anton(
                    color: _kCream,
                    fontSize: AppResponsive.font(context, 14),
                    letterSpacing: 1.0,
                  ),
                ),
                const Gap(6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: _kBorder,
                    valueColor: const AlwaysStoppedAnimation(_kLime),
                    minHeight: 4,
                  ),
                ),
                const Gap(6),
                Text(
                  '${total - unlocked} more to unlock',
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.35),
                    fontSize: 11,
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBlack,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          Expanded(
            child: Text(
              'YOUR BADGES',
              style: GoogleFonts.anton(
                color: _kCream,
                fontSize: AppResponsive.font(context, 28),
                letterSpacing: 2.0,
              ),
            ),
          ),

          // Mascot
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _kDark,
              shape: BoxShape.circle,
              border: Border.all(color: _kLime.withValues(alpha: 0.40)),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Text('🎉', style: TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured badge card ────────────────────────────────────────────────────────

class _FeaturedBadge extends StatelessWidget {
  final _BadgeData badge;
  const _FeaturedBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLime, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kLime.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing badge icon circle
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kLime.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _kLime.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
          ),
          const Gap(20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FEATURED pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _kLime.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    'FEATURED',
                    style: GoogleFonts.anton(
                      color: _kLime,
                      fontSize: 9,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const Gap(10),

                Text(
                  badge.name,
                  style: GoogleFonts.anton(
                    color: _kCream,
                    fontSize: AppResponsive.font(context, 18),
                    letterSpacing: 0.8,
                    height: 1.1,
                  ),
                ),
                const Gap(6),
                Text(
                  badge.desc,
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.42),
                    fontSize: AppResponsive.font(context, 12),
                    height: 1.4,
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

// ── Badge card ────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final _BadgeData badge;
  final bool unlocked;
  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? _kLime : _kBorder,
          width: unlocked ? 1.5 : 1.0,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji / icon with optional glow
          unlocked
              ? Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kLime.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kLime.withValues(alpha: 0.20),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(badge.emoji,
                      style: const TextStyle(fontSize: 28)),
                )
              : Opacity(
                  opacity: 0.20,
                  child: Text(badge.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
          const Gap(10),

          // Badge name
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anton(
              color: unlocked ? _kCream : _kWhite.withValues(alpha: 0.22),
              fontSize: AppResponsive.font(context, 10),
              letterSpacing: 0.6,
              height: 1.2,
            ),
          ),
          const Gap(8),

          // Status indicator
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kLime.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _kLime.withValues(alpha: 0.40)),
              ),
              child: Text(
                'UNLOCKED',
                style: GoogleFonts.anton(
                  color: _kLime,
                  fontSize: 8,
                  letterSpacing: 1.4,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded,
                    size: 9, color: _kWhite.withValues(alpha: 0.22)),
                const Gap(3),
                Text(
                  'LOCKED',
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.22),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
