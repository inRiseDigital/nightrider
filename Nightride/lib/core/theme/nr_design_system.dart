// lib/core/theme/nr_design_system.dart
//
// NightRide shared design system — colours, text styles, and reusable widgets.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart'; // ignore: unused_import — re-exported for convenience

// ── Colours ───────────────────────────────────────────────────────────────────

class NRColors {
  const NRColors._();

  static const black       = Color(0xFF070707);
  static const cardSurface = Color(0xFF0F0F0F);
  static const darkGray    = Color(0xFF151515);
  static const borderGray  = Color(0xFF333333);
  static const cream       = Color(0xFFF3EAD6);
  static const neonLime    = Color(0xFFDFFF2F);
  static const hotPink     = Color(0xFFFF3D73);
  static const teal        = Color(0xFF62D6C8);
}

// ── Text styles ───────────────────────────────────────────────────────────────

class NRTextStyles {
  const NRTextStyles._();

  static TextStyle displayLarge(BuildContext context) => GoogleFonts.anton(
        fontSize: 64,
        color: NRColors.cream,
        height: 0.92,
        letterSpacing: 2.0,
      );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.anton(
        fontSize: 48,
        color: NRColors.cream,
        letterSpacing: 1.5,
      );

  static TextStyle headingLarge(BuildContext context) => GoogleFonts.anton(
        fontSize: 32,
        color: Colors.white,
        letterSpacing: 1.0,
      );

  static TextStyle headingMedium(BuildContext context) => GoogleFonts.anton(
        fontSize: 24,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  static TextStyle headingSmall(BuildContext context) => GoogleFonts.anton(
        fontSize: 18,
        color: Colors.white,
      );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const label = TextStyle(
    fontSize: 12,
    color: Colors.white54,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
  );
}

// ── NRRadii ───────────────────────────────────────────────────────────────────

class NRRadius {
  const NRRadius._();

  static const double sm   = 8.0;
  static const double md   = 14.0;
  static const double lg   = 20.0;
  static const double xl   = 28.0;
  static const double pill = 99.0;
}

// ── NRDecoration ──────────────────────────────────────────────────────────────

class NRDecoration {
  const NRDecoration._();

  static BoxDecoration darkCard({double radius = NRRadius.md}) => BoxDecoration(
        color: NRColors.cardSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: NRColors.borderGray, width: 1),
      );

  static BoxDecoration neonBorder({double radius = NRRadius.md, double width = 1.5}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: NRColors.neonLime, width: width),
      );

  static BoxDecoration limeGlow({double radius = NRRadius.md}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: NRColors.neonLime.withValues(alpha: 0.40),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      );
}

// ── NRButton ──────────────────────────────────────────────────────────────────

class NRButton extends StatelessWidget {
  const NRButton({
    super.key,
    required this.label,
    this.onTap,
    this.bgColor = const Color(0xFFDFFF2F),
    this.textColor = const Color(0xFF070707),
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color textColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.anton(
              fontSize: 15,
              color: textColor,
              letterSpacing: 2.5,
            ),
          ),
        ),
      );
}

// ── NRPill ────────────────────────────────────────────────────────────────────

class NRPill extends StatelessWidget {
  const NRPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDFFF2F) : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected ? const Color(0xFFDFFF2F) : Colors.white38,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF070707) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
}

// ── NRSectionHeader ───────────────────────────────────────────────────────────

class NRSectionHeader extends StatelessWidget {
  const NRSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.anton(
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Color(0xFFDFFF2F),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      );
}
