import 'package:flutter/widgets.dart';
import 'responsive.dart';

/// App-wide responsive dimensions, dispatched per [FormFactor].
///
/// All values are raw logical pixels (dp) — no ScreenUtil scaling, so they
/// behave consistently across phones, foldables, and tablets.
abstract class AppDimensions {
  // ── Page padding ───────────────────────────────────────────────────────
  static double pagePaddingHorizontal(BuildContext c) => c.responsive(
        compact: 14.0,
        regular: 18.0,
        foldable: 22.0,
        tablet: 32.0,
      );

  static double pagePaddingTop(BuildContext c) => c.responsive(
        compact: 10.0,
        regular: 14.0,
        foldable: 14.0,
        tablet: 18.0,
      );

  static double pagePaddingBottom(BuildContext c) => c.responsive(
        compact: 12.0,
        regular: 16.0,
        foldable: 18.0,
        tablet: 22.0,
      );

  // ── Content width caps (centred when capped) ───────────────────────────
  /// Wide cap: leaves the page largely full-width on phones and foldables,
  /// caps tablets so lists/cards don't sprawl.
  static double contentMaxWidth(BuildContext c) => c.responsive(
        compact: double.infinity,
        regular: double.infinity,
        foldable: 720.0,
        tablet: 900.0,
      );

  /// Narrow cap: for forms, dense forms, dialogs, settings rows.
  static double formMaxWidth(BuildContext c) => c.responsive(
        compact: double.infinity,
        regular: double.infinity,
        foldable: 520.0,
        tablet: 580.0,
      );

  // ── Vertical rhythm ────────────────────────────────────────────────────
  /// Gap between major sections (e.g. between the carousel and the section title).
  static double sectionGap(BuildContext c) => c.responsive(
        compact: 16.0,
        regular: 20.0,
        foldable: 18.0,
        tablet: 24.0,
      );

  /// Gap inside a section (e.g. between section title and its content).
  static double subSectionGap(BuildContext c) => c.responsive(
        compact: 8.0,
        regular: 10.0,
        foldable: 10.0,
        tablet: 12.0,
      );

  /// Generic small/medium/large gaps for ad-hoc use.
  static double gapXS(BuildContext c) =>
      c.responsive(compact: 4.0, regular: 6.0, foldable: 6.0, tablet: 8.0);
  static double gapS(BuildContext c) =>
      c.responsive(compact: 8.0, regular: 10.0, foldable: 10.0, tablet: 12.0);
  static double gapM(BuildContext c) =>
      c.responsive(compact: 12.0, regular: 14.0, foldable: 14.0, tablet: 16.0);
  static double gapL(BuildContext c) =>
      c.responsive(compact: 16.0, regular: 20.0, foldable: 18.0, tablet: 24.0);
  static double gapXL(BuildContext c) =>
      c.responsive(compact: 22.0, regular: 28.0, foldable: 24.0, tablet: 32.0);

  // ── Typography ─────────────────────────────────────────────────────────
  static double appBarTitleSize(BuildContext c) => c.responsive(
        compact: 17.0,
        regular: 19.0,
        foldable: 19.0,
        tablet: 22.0,
      );

  static double sectionTitleSize(BuildContext c) => c.responsive(
        compact: 16.0,
        regular: 18.0,
        foldable: 18.0,
        tablet: 22.0,
      );

  static double bodyTextSize(BuildContext c) => c.responsive(
        compact: 13.0,
        regular: 14.0,
        foldable: 14.0,
        tablet: 15.0,
      );

  static double captionTextSize(BuildContext c) => c.responsive(
        compact: 11.5,
        regular: 12.5,
        foldable: 12.5,
        tablet: 13.0,
      );

  // ── Iconography ────────────────────────────────────────────────────────
  static double iconS(BuildContext c) =>
      c.responsive(compact: 16.0, regular: 18.0, foldable: 18.0, tablet: 20.0);
  static double iconM(BuildContext c) =>
      c.responsive(compact: 20.0, regular: 22.0, foldable: 22.0, tablet: 24.0);
  static double iconL(BuildContext c) =>
      c.responsive(compact: 24.0, regular: 26.0, foldable: 26.0, tablet: 28.0);

  // ── Cards / surfaces ───────────────────────────────────────────────────
  static double cardRadius(BuildContext c) => c.responsive(
        compact: 16.0,
        regular: 18.0,
        foldable: 20.0,
        tablet: 22.0,
      );

  // ── Featured carousel (home) ───────────────────────────────────────────
  static double featuredCarouselHeight(BuildContext c) => c.responsive(
        compact: 220.0,
        regular: 270.0,
        foldable: 240.0,
        tablet: 320.0,
      );

  // ── Category rail ──────────────────────────────────────────────────────
  static double categoryCircleSize(BuildContext c) => c.responsive(
        compact: 48.0,
        regular: 58.0,
        foldable: 50.0,
        tablet: 60.0,
      );

  static double categoryItemWidth(BuildContext c) => c.responsive(
        compact: 60.0,
        regular: 70.0,
        foldable: 64.0,
        tablet: 74.0,
      );

  static double categoryGap(BuildContext c) => c.responsive(
        compact: 10.0,
        regular: 14.0,
        foldable: 12.0,
        tablet: 14.0,
      );

  static double categoryLabelSize(BuildContext c) => c.responsive(
        compact: 10.5,
        regular: 11.5,
        foldable: 11.0,
        tablet: 12.0,
      );

  // ── Filter chips ───────────────────────────────────────────────────────
  static double filterChipHeight(BuildContext c) => c.responsive(
        compact: 30.0,
        regular: 34.0,
        foldable: 32.0,
        tablet: 36.0,
      );

  static double filterChipPaddingH(BuildContext c) => c.responsive(
        compact: 12.0,
        regular: 14.0,
        foldable: 14.0,
        tablet: 16.0,
      );

  static double filterChipPaddingV(BuildContext c) => c.responsive(
        compact: 5.0,
        regular: 6.0,
        foldable: 6.0,
        tablet: 7.0,
      );

  static double filterChipFontSize(BuildContext c) => c.responsive(
        compact: 11.5,
        regular: 12.5,
        foldable: 12.0,
        tablet: 13.0,
      );

  static double filterChipGap(BuildContext c) => c.responsive(
        compact: 6.0,
        regular: 8.0,
        foldable: 8.0,
        tablet: 10.0,
      );

  // ── Trending event card ────────────────────────────────────────────────
  static double trendingCardHeight(BuildContext c) => c.responsive(
        compact: 150.0,
        regular: 175.0,
        foldable: 156.0,
        tablet: 184.0,
      );

  static double trendingCardTitleSize(BuildContext c) => c.responsive(
        compact: 15.0,
        regular: 17.0,
        foldable: 16.0,
        tablet: 19.0,
      );

  static double trendingCardMetaSize(BuildContext c) => c.responsive(
        compact: 11.5,
        regular: 12.2,
        foldable: 11.8,
        tablet: 13.0,
      );

  // ── Map venue card (PageView at the bottom of the map) ────────────────
  static double mapVenueCardHeight(BuildContext c) => c.responsive(
        compact: 108.0,
        regular: 118.0,
        foldable: 120.0,
        tablet: 132.0,
      );

  static double mapVenueImageWidth(BuildContext c) => c.responsive(
        compact: 96.0,
        regular: 110.0,
        foldable: 132.0,
        tablet: 150.0,
      );

  static double mapBottomCardHorizontalMargin(BuildContext c) => c.responsive(
        compact: 12.0,
        regular: 14.0,
        foldable: 18.0,
        tablet: 28.0,
      );

  static double mapBottomCardBottomInset(BuildContext c) => c.responsive(
        compact: 36.0,
        regular: 50.0,
        foldable: 44.0,
        tablet: 56.0,
      );

  // ── Bottom navigation ──────────────────────────────────────────────────
  static double bottomNavHeight(BuildContext c) => c.responsive(
        compact: 58.0,
        regular: 62.0,
        foldable: 64.0,
        tablet: 70.0,
      );

  static double bottomNavIconSize(BuildContext c) => c.responsive(
        compact: 22.0,
        regular: 24.0,
        foldable: 24.0,
        tablet: 26.0,
      );

  static double bottomNavMaxWidth(BuildContext c) => c.responsive(
        compact: double.infinity,
        regular: double.infinity,
        foldable: 540.0,
        tablet: 620.0,
      );

  static double bottomNavBottomMargin(BuildContext c) => c.responsive(
        compact: 8.0,
        regular: 12.0,
        foldable: 14.0,
        tablet: 16.0,
      );
}
