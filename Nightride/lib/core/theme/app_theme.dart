import 'package:flutter/material.dart';

class AppTheme {
  // ── Night Rite Retro Poster Palette ──────────────────────────────────────
  static const primary = Color(0xFFFF3D73);       // hot pink — main brand
  static const primaryDark = Color(0xFFd63b7a);   // deeper pink (light theme)
  static const primaryLight = Color(0xFF62D6C8);  // teal — secondary/links/icons

  static const accent = Color(0xFFDFFF2F);        // neon lime — highlights
  static const accentPurple = Color(0xFF62D6C8);  // teal (secondary accent)

  static const background = Color(0xFF070707);    // near-black brand black
  static const surface = Color(0xFF0F0F0F);       // card surface
  static const scaffold = Color(0xFF070707);      // near-black brand black

  static const textPrimary = Color(0xFFfafafa);   // off-white
  static const textSecondary = Color(0xFF9EAFA0); // muted cool-gray
  static const textHint = Color(0xFF6B7280);      // gray

  // ── Extended Palette ─────────────────────────────────────────────────────
  static const cream = Color(0xFFF3EAD6);
  static const neonLime = Color(0xFFDFFF2F);
  static const hotPink = Color(0xFFFF3D73);
  static const teal = Color(0xFF62D6C8);
  static const darkGray = Color(0xFF151515);
  static const borderGray = Color(0xFF333333);
  static const cardSurface = Color(0xFF0F0F0F);

  // ── Accent color swatches (settings page picker) ─────────────────────────
  static const List<Color> kAccentColors = [
    Color(0xFFDFFF2F), // neon lime (brand default)
    Color(0xFFFF3D73), // hot pink
    Color(0xFF62D6C8), // teal
    Color(0xFF448AFF), // electric blue
    Color(0xFFFFD700), // gold
  ];

  // ── Dynamic color getters ─────────────────────────────────────────────────
  static Color getPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primary : primaryDark;
  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surface
          : const Color(0xFFf5f5f5);
  static Color getScaffold(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? scaffold
          : const Color(0xFFfafafa);
  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimary
          : const Color(0xFF111111);
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : const Color(0xFF4B5563);
  static Color getCardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffold,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.black,
      surface: surface,
      onSurface: textPrimary,
      error: Colors.redAccent,
    ),
    cardColor: cardSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFFfafafa),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      hintStyle: const TextStyle(color: textHint),
    ),
  );

  // ── Light Theme ──────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFfafafa),
    colorScheme: ColorScheme.light(
      primary: primaryDark,
      onPrimary: Colors.white,
      secondary: primaryLight,
      surface: Colors.white,
      onSurface: const Color(0xFF111111),
      error: Colors.redAccent,
    ),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF111111),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF111111)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111111)),
      bodyMedium: TextStyle(color: Color(0xFF4B5563)),
      titleLarge: TextStyle(
        color: Color(0xFF111111),
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFf5f5f5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
  );
}
