import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Continuous-scale responsive helper — complements the form-factor-based
/// [`AppDimensions`] with a clamped scale factor so values shrink slightly on
/// foldables/tablets instead of inflating.
///
/// Use [scale] for the multiplier, or the convenience helpers [gap], [font],
/// [icon], [radius] for value × scale (with sensible clamps so things never
/// get absurdly small or large). Per-screen tokens (e.g.
/// [homeCategoryCircleSize], [eventCardHeight]) live here too so layout code
/// stays declarative.
class AppResponsive {
  AppResponsive._();

  // ── MediaQuery shortcuts ───────────────────────────────────────────────
  static Size size(BuildContext c) => MediaQuery.sizeOf(c);
  static double width(BuildContext c) => size(c).width;
  static double height(BuildContext c) => size(c).height;
  static double shortestSide(BuildContext c) => size(c).shortestSide;

  // ── Breakpoint predicates ──────────────────────────────────────────────
  static bool isSmallPhone(BuildContext c) => width(c) < 360;
  static bool isPhone(BuildContext c) => width(c) < 600;
  static bool isLargePhoneOrFoldable(BuildContext c) =>
      width(c) >= 600 && width(c) < 840;
  static bool isTabletOrExpanded(BuildContext c) => width(c) >= 840;

  /// Continuous scale: `min(widthScale, heightScale)` against a 390×844
  /// design baseline, clamped so foldables/tablets do not blow up the UI.
  static double scale(BuildContext c) {
    final w = width(c);
    final h = height(c);
    final widthScale = w / 390.0;
    final heightScale = h / 844.0;
    final raw = math.min(widthScale, heightScale);
    return raw.clamp(0.86, 1.05);
  }

  // ── Layout primitives ─────────────────────────────────────────────────
  static double pagePadding(BuildContext c) {
    final w = width(c);
    if (w < 360) return 16;
    if (w < 600) return 24;
    if (w < 840) return 28;
    return 32;
  }

  static double maxContentWidth(BuildContext c) {
    final w = width(c);
    if (w >= 840) return 720;
    if (w >= 600) return 680;
    return double.infinity;
  }

  static double bottomNavMaxWidth(BuildContext c) {
    final w = width(c);
    if (w >= 840) return 560;
    if (w >= 600) return 600;
    return double.infinity;
  }

  // ── Scaled value helpers ───────────────────────────────────────────────
  static double gap(BuildContext c, double value) => value * scale(c);

  static double font(BuildContext c, double value) {
    final s = scale(c);
    return (value * s).clamp(value * 0.86, value * 1.04);
  }

  static double icon(BuildContext c, double value) {
    final s = scale(c);
    return (value * s).clamp(value * 0.84, value);
  }

  static double radius(BuildContext c, double value) => value * scale(c);

  // ── Home: Explore Categories rail ──────────────────────────────────────
  static double homeCategoryCircleSize(BuildContext c) {
    final w = width(c);
    if (w < 360) return 68;
    if (w < 600) return 82;
    if (w < 840) return 84; // foldable (e.g. V3 unfolded)
    return 78; // tablet — slightly smaller so it doesn't dominate
  }

  static double homeCategoryItemWidth(BuildContext c) =>
      homeCategoryCircleSize(c) + 18;

  static double homeCategoryGap(BuildContext c) {
    final w = width(c);
    if (w < 360) return 18;
    if (w < 600) return 26;
    if (w < 840) return 30;
    return 34;
  }

  // ── Home: Trending event card ──────────────────────────────────────────
  // The trending card stacks: tag-pill, Spacer, title, meta row, interested
  // row. The tag-pill (with vertical padding + 1 dp border) and the title
  // (FontWeight.w900) both report taller intrinsic heights than their font
  // sizes suggest, so empirically the column needs ~146 dp of room before
  // padding. Foldable bumped to 174 dp to absorb a measured 12 dp overflow
  // plus a small buffer. Phone values are unchanged.
  static double eventCardHeight(BuildContext c) {
    final h = height(c);
    final w = width(c);
    if (h < 700) return 130;
    if (w >= 840) return 184;
    if (w >= 600) return 188;
    return 165; // bumped from 150 — S23 Ultra overflowed by 11 dp
  }

  // ── Map: top filter chips + search row ────────────────────────────────
  static double mapChipHeight(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 36;
    return 32;
  }

  static double mapSearchBarHeight(BuildContext c) {
    final w = width(c);
    if (w < 360) return 40;
    if (w < 600) return 44;
    return 48;
  }

  // ── Map: bottom event card ─────────────────────────────────────────────
  static double mapBottomCardImageSize(BuildContext c) {
    final w = width(c);
    if (w < 360) return 84;
    if (w < 600) return 96;
    if (w < 840) return 110; // V3
    return 120;
  }

  static double mapBottomCardHeight(BuildContext c) {
    final w = width(c);
    if (w < 360) return 116;
    if (w < 600) return 124;
    if (w < 840) return 124; // V3
    return 134;
  }

  // ── Profile ────────────────────────────────────────────────────────────
  // Phones (w < 600) keep their existing values verbatim. Foldable / tablet
  // (w >= 600) receive a smaller, more compact set so the profile doesn't
  // sprawl on wider devices like the Honor Magic V3 unfolded.
  static bool _profileExpanded(BuildContext c) => width(c) >= 600;

  static double profileAvatarSize(BuildContext c) {
    if (_profileExpanded(c)) return 88;
    final w = width(c);
    if (w < 360) return 92;
    return 116;
  }

  static double profileSideImageSize(BuildContext c) {
    if (_profileExpanded(c)) return 68;
    final w = width(c);
    if (w < 360) return 72;
    return 92;
  }

  static double profileCardPadding(BuildContext c) {
    if (_profileExpanded(c)) return 12;
    return 14;
  }

  static double profileHeaderGap(BuildContext c) {
    if (_profileExpanded(c)) return 12;
    return 14;
  }

  static double profileSectionGap(BuildContext c) {
    if (_profileExpanded(c)) return 14;
    return 18;
  }

  static double profileUsernameFont(BuildContext c) {
    if (_profileExpanded(c)) return 16;
    return 18;
  }

  static double profilePronounsFont(BuildContext c) {
    if (_profileExpanded(c)) return 11;
    return 12;
  }

  static double profileNetworkFont(BuildContext c) {
    if (_profileExpanded(c)) return 12;
    return 13;
  }

  static double profilePageTitleFont(BuildContext c) {
    if (_profileExpanded(c)) return 16;
    return 18;
  }

  static double profileCardTitleFont(BuildContext c) {
    if (_profileExpanded(c)) return 11.5;
    return 12.5;
  }

  static double profileBodyFont(BuildContext c) {
    if (_profileExpanded(c)) return 12;
    return 13;
  }

  static double profileChipFont(BuildContext c) {
    if (_profileExpanded(c)) return 11;
    return 12;
  }

  static double profileChipPaddingH(BuildContext c) {
    if (_profileExpanded(c)) return 12;
    return 14;
  }

  static double profileChipPaddingV(BuildContext c) {
    if (_profileExpanded(c)) return 6;
    return 8;
  }

  static double profileStatGridAspectRatio(BuildContext c) {
    if (_profileExpanded(c)) return 3.0; // bumped from 3.4 — Tab overflowed by 4.5 dp
    return 2.2;
  }

  static double interestChipHeight(BuildContext c) {
    if (_profileExpanded(c)) return 34;
    return 42;
  }

  // ── Bottom-nav (used by ResponsiveBottomNav-style code) ────────────────
  static double bottomNavHeight(BuildContext c) {
    final w = width(c);
    if (w < 360) return 40;
    if (w < 600) return 42;
    if (w < 840) return 42;
    return 48;
  }

  // ── Home header (language + notification buttons) ─────────────────────
  static double headerActionHeight(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 44;
    return 48;
  }

  static double languageButtonWidth(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 78;
    return 86;
  }

  static double notificationButtonSize(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 44;
    return 48;
  }

  static double headerActionFontSize(BuildContext c) =>
      font(c, 13).clamp(11.0, 14.0);

  static double headerActionIconSize(BuildContext c) =>
      icon(c, 18).clamp(14.0, 18.0);

  // ── Language selection modal ──────────────────────────────────────────
  static double languageModalMaxWidth(BuildContext c) {
    final w = width(c);
    if (w >= 840) return 520;
    if (w >= 600) return 480;
    return w - (pagePadding(c) * 2);
  }

  static double languageModalMaxHeight(BuildContext c) =>
      height(c) * 0.72;

  static double languageModalPadding(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 18;
    return 20;
  }

  static double languageRowHeight(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 56;
    return 60;
  }

  static double languageCodeBoxSize(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 36;
    return 40;
  }

  static double languageTitleFont(BuildContext c) =>
      font(c, 17).clamp(14.0, 18.0);

  static double languageNameFont(BuildContext c) =>
      font(c, 14.5).clamp(12.5, 16.0);

  static double languageCodeFont(BuildContext c) =>
      font(c, 12.5).clamp(11.0, 14.0);

  // ── Featured carousel (top of home) ────────────────────────────────────
  static double featuredViewportFraction(BuildContext c) {
    final w = width(c);
    if (w >= 840) return 0.80;
    if (w >= 600) return 0.83;
    return 0.88;
  }

  static double featuredGenreMaxWidth(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 170;
    return 145;
  }

  static double featuredActionButtonSize(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 36;
    return 40;
  }

  // ── Trending event card internals ──────────────────────────────────────
  static double trendingActionColumnWidth(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 92;
    return 88;
  }

  static double trendingFavoriteSize(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 36;
    return 40;
  }

  static double trendingViewButtonHeight(BuildContext c) {
    final w = width(c);
    if (w >= 600) return 32;
    return 34;
  }

  static double metaIconSize(BuildContext c) =>
      icon(c, 13).clamp(11.0, 14.0);
}
