import 'package:flutter/material.dart';

class AppTheme {
  // ── Night Rite Brand Palette ──────────────────────────────────────────────
  static const primary = Color(0xFFf15991);       // hot pink — main brand
  static const primaryDark = Color(0xFFd63b7a);   // deeper pink (light theme)
  static const primaryLight = Color(0xFF2ec4b6);  // teal — secondary/links/icons

  static const accent = Color(0xFFdbdf57);        // neon lime — highlights
  static const accentPurple = Color(0xFF2ec4b6);  // teal (secondary accent)

  static const background = Color(0xFF000000);    // pure black
  static const surface = Color(0xFF111111);       // near-black for cards/surfaces
  static const scaffold = Color(0xFF000000);      // pure black

  static const textPrimary = Color(0xFFfafafa);   // off-white
  static const textSecondary = Color(0xFF9EAFA0); // muted cool-gray
  static const textHint = Color(0xFF6B7280);      // gray

  // Dynamic color getters
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
    cardColor: surface,
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
