import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/rank_system.dart';
import 'package:nightride/pages/badges_collection_page.dart';

import '../../domain/profile_models.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kBlack      = Color(0xFF070707);
const _kNeonLime   = Color(0xFFDFFF2F);
const _kCream      = Color(0xFFF3EAD6);
const _kBorderGray = Color(0xFF333333);
const _kWhite      = Color(0xFFFAFAFA);
const _kCard       = Color(0xFF0F0F0F);

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.avatarBase64,
  });

  final ProfileState state;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String? avatarBase64;

  @override
  Widget build(BuildContext context) {
    final d = state.data;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // ── Avatar with neonLime ring ──
        _Avatar(url: d.avatarUrl, avatarBase64: avatarBase64),
        SizedBox(width: AppResponsive.profileHeaderGap(context)),

        // ── Name / pronouns / badge / network ──
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // USERNAME — bold Anton uppercase cream
              Text(
                d.username.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.anton(
                  color: _kCream,
                  fontSize: AppResponsive.profileUsernameFont(context),
                  letterSpacing: 1.2,
                ),
              ),

              if (d.pronouns.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  d.pronouns,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _kWhite.withValues(alpha: 0.45),
                    fontSize: AppResponsive.profilePronounsFont(context),
                    letterSpacing: 0.3,
                  ),
                ),
              ],

              SizedBox(height: AppResponsive.gap(context, 8)),

              // RANK BADGE — neonLime pill, black text, emoji
              _RankBadge(points: d.rank),

              SizedBox(height: AppResponsive.gap(context, 8)),

              // NETWORK count
              Row(
                children: [
                  Text(
                    'Network ',
                    style: TextStyle(
                      color: _kWhite.withValues(alpha: 0.45),
                      fontSize: AppResponsive.profileNetworkFont(context),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      d.networkCount.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kWhite,
                        fontSize: AppResponsive.profileNetworkFont(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Badges shortcut button ──
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BadgesCollectionPage(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorderGray, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: _kNeonLime,
                  size: AppResponsive.icon(context, 22).clamp(18.0, 26.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'BADGES',
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.font(context, 9).clamp(8.0, 10.0),
                    color: _kCream,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Avatar ─────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, this.avatarBase64});
  final String url;
  final String? avatarBase64;

  @override
  Widget build(BuildContext context) {
    final double s = AppResponsive.profileAvatarSize(context);
    final double fallbackIcon = s * 0.5;
    Widget child;

    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      child = Image.memory(base64Decode(avatarBase64!), fit: BoxFit.cover);
    } else if (url.isNotEmpty && url.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFF151515)),
        errorWidget: (_, __, ___) =>
            Icon(Icons.person_rounded, color: Colors.white38, size: fallbackIcon),
      );
    } else {
      child = Icon(Icons.person_rounded, color: Colors.white38, size: fallbackIcon);
    }

    return Container(
      width: s,
      height: s,
      // Double ring effect: outer neonLime, slight inner gap via padding
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kNeonLime, width: 3),
        boxShadow: [
          BoxShadow(
            color: _kNeonLime.withValues(alpha: 0.30),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(child: child),
    );
  }
}

// ─── Rank badge pill ─────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    final tier = RankSystem.tierFor(points);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _kNeonLime,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier.emoji,
            style: TextStyle(
              fontSize: AppResponsive.font(context, 10).clamp(9.0, 12.0),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            tier.name.toUpperCase(),
            style: GoogleFonts.anton(
              color: _kBlack,
              fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
