import 'package:flutter/widgets.dart';
import 'responsive.dart';

/// Single source of truth for all sizes/spacing in the auth flow.
/// All values are raw logical pixels (dp) — no ScreenUtil scaling — so
/// they remain predictable across form factors.
abstract class AuthDimensions {
  // ── Typography ─────────────────────────────────────────────────────────
  static double titleFontSize(BuildContext c) => c.responsive(
        compact: 26.0,
        regular: 32.0,
        foldable: 30.0,
        tablet: 36.0,
      );

  static double subtitleFontSize(BuildContext c) => c.responsive(
        compact: 12.5,
        regular: 14.0,
        foldable: 14.0,
        tablet: 15.0,
      );

  static double brandFontSize(BuildContext c) => c.responsive(
        compact: 15.0,
        regular: 17.0,
        foldable: 17.0,
        tablet: 19.0,
      );

  static double brandLogoSize(BuildContext c) => c.responsive(
        compact: 32.0,
        regular: 36.0,
        foldable: 36.0,
        tablet: 42.0,
      );

  static double inputFontSize(BuildContext c) => c.responsive(
        compact: 14.0,
        regular: 15.0,
        foldable: 14.5,
        tablet: 16.0,
      );

  static double buttonFontSize(BuildContext c) => c.responsive(
        compact: 15.0,
        regular: 17.0,
        foldable: 17.0,
        tablet: 18.0,
      );

  // ── Component sizes ────────────────────────────────────────────────────
  static double inputHeight(BuildContext c) => c.responsive(
        compact: 52.0,
        regular: 58.0,
        foldable: 56.0,
        tablet: 62.0,
      );

  static double inputBorderRadius(BuildContext c) => c.responsive(
        compact: 18.0,
        regular: 22.0,
        foldable: 22.0,
        tablet: 24.0,
      );

  static double buttonHeight(BuildContext c) => c.responsive(
        compact: 50.0,
        regular: 56.0,
        foldable: 54.0,
        tablet: 60.0,
      );

  static double buttonBorderRadius(BuildContext c) => c.responsive(
        compact: 16.0,
        regular: 20.0,
        foldable: 20.0,
        tablet: 22.0,
      );

  static double socialIconSize(BuildContext c) => c.responsive(
        compact: 32.0,
        regular: 36.0,
        foldable: 38.0,
        tablet: 44.0,
      );

  // ── Layout ─────────────────────────────────────────────────────────────
  /// Cap the form width on wide form factors so it never stretches edge-to-edge.
  static double maxFormWidth(BuildContext c) => c.responsive(
        compact: double.infinity,
        regular: double.infinity,
        foldable: 520.0,
        tablet: 560.0,
      );

  static double horizontalPadding(BuildContext c) => c.responsive(
        compact: 18.0,
        regular: 22.0,
        foldable: 24.0,
        tablet: 32.0,
      );

  static double panelTopRadius(BuildContext c) => c.responsive(
        compact: 28.0,
        regular: 36.0,
        foldable: 40.0,
        tablet: 44.0,
      );

  static double panelInnerTopPadding(BuildContext c) => c.responsive(
        compact: 18.0,
        regular: 22.0,
        foldable: 22.0,
        tablet: 28.0,
      );

  static double panelInnerBottomPadding(BuildContext c) => c.responsive(
        compact: 12.0,
        regular: 16.0,
        foldable: 18.0,
        tablet: 22.0,
      );

  // ── Vertical rhythm (spacing scale) ────────────────────────────────────
  static double gapXS(BuildContext c) =>
      c.responsive(compact: 4.0, regular: 6.0, foldable: 6.0, tablet: 8.0);
  static double gapS(BuildContext c) =>
      c.responsive(compact: 8.0, regular: 10.0, foldable: 10.0, tablet: 12.0);
  static double gapM(BuildContext c) =>
      c.responsive(compact: 12.0, regular: 14.0, foldable: 14.0, tablet: 16.0);
  static double gapL(BuildContext c) =>
      c.responsive(compact: 16.0, regular: 20.0, foldable: 24.0, tablet: 28.0);
  static double gapXL(BuildContext c) =>
      c.responsive(compact: 22.0, regular: 28.0, foldable: 24.0, tablet: 32.0);

  // ── Header rhythm ──────────────────────────────────────────────────────
  static double headerTopPadding(BuildContext c) => c.responsive(
        compact: 12.0,
        regular: 18.0,
        foldable: 20.0,
        tablet: 24.0,
      );

  static double brandToTitleGap(BuildContext c) => c.responsive(
        compact: 24.0,
        regular: 36.0,
        foldable: 28.0,
        tablet: 32.0,
      );
}
