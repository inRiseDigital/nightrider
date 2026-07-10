import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/profile_models.dart';
import 'package:nightride/domain/rank_system.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kNeonLime   = Color(0xFFDFFF2F);
const _kHotPink    = Color(0xFFFF3D73);
const _kTeal       = Color(0xFF62D6C8);
const _kBorderGray = Color(0xFF333333);
const _kWhite      = Color(0xFFFAFAFA);
const _kCard       = Color(0xFF0F0F0F);

class RankCard extends StatelessWidget {
  const RankCard({super.key, required this.data});
  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    final pts  = data.rank;
    final tier = RankSystem.tierFor(pts);
    final next = RankSystem.nextTier(pts);
    final pct  = RankSystem.progress(pts);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorderGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: emoji + name/pts + streak badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large tier emoji in a subtle glow circle
              Container(
                width: AppResponsive.icon(context, 52).clamp(44.0, 58.0),
                height: AppResponsive.icon(context, 52).clamp(44.0, 58.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kTeal.withValues(alpha: 0.40), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  tier.emoji,
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 26).clamp(20.0, 30.0),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank name in bold Anton teal
                    Text(
                      tier.name.toUpperCase(),
                      style: GoogleFonts.anton(
                        color: _kTeal,
                        fontSize: AppResponsive.font(context, 20).clamp(16.0, 22.0),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Points in white
                    Text(
                      '$pts pts total',
                      style: TextStyle(
                        color: _kWhite.withValues(alpha: 0.75),
                        fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak badge in hotPink if streak > 0
              if (data.streakDays > 0) _StreakBadge(days: data.streakDays),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar label ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESS',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 9).clamp(8.0, 10.0),
                  color: _kWhite.withValues(alpha: 0.40),
                  letterSpacing: 1.2,
                ),
              ),
              if (next != null)
                Text(
                  '${next.emoji} ${next.name.toUpperCase()}',
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.font(context, 9).clamp(8.0, 10.0),
                    color: _kTeal.withValues(alpha: 0.80),
                    letterSpacing: 0.6,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Progress bar in neonLime ──
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _kBorderGray,
              valueColor: const AlwaysStoppedAnimation<Color>(_kNeonLime),
            ),
          ),

          const SizedBox(height: 8),

          // ── Progress sub-label ──
          Text(
            next != null
                ? '${pts - tier.minPoints} / ${next.minPoints - tier.minPoints} pts to ${next.name}'
                : 'Maximum rank reached — you are a Legend!',
            style: TextStyle(
              color: _kWhite.withValues(alpha: 0.40),
              fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak badge ─────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kHotPink,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: _kHotPink.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$days DAY${days == 1 ? "" : "S"}',
            style: GoogleFonts.anton(
              color: _kWhite,
              fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
