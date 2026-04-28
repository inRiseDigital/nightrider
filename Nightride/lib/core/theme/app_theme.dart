import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Dark / Neon vibe
  static const primary = Color(0xFF9F7AEA);
  static const primaryDark = Color(0xFF805AD5);
  static const primaryLight = Color(0xFFB794F4);

  static const accent = Color(0xFFED64A6); // neon pink
  static const accentPurple = Color(0xFFBB86FC);

  static const background = Color(0xFF0F0B1A);
  static const surface = Color(0xFF1A1428);
  static const scaffold = Color(0xFF0A0712);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0A8C0);
  static const textHint = Color(0xFF6B7280);

  // Dynamic color getters
  static Color getPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? primary : primaryDark;
  static Color getSurface(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? surface : Colors.white;
  static Color getScaffold(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? scaffold : const Color(0xFFF8F5FF);
  static Color getTextPrimary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827);
  static Color getTextSecondary(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? textSecondary : const Color(0xFF4B5563);
  static Color getCardBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

  // ── Dark Theme ───────────────────────────────────────
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffold,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      error: Colors.redAccent,
    ),
    cardColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    textTheme: TextTheme(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      hintStyle: TextStyle(color: textHint),
    ),
  );

  // ── Light Theme (matching dark style) ─────────────────
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F5FF),
    colorScheme: ColorScheme.light(
      primary: primaryDark,
      onPrimary: Colors.white,
      secondary: accentPurple,
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
      error: Colors.redAccent,
    ),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Color(0xFF111827)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111827)),
      bodyMedium: TextStyle(color: Color(0xFF4B5563)),
      titleLarge: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3E8FF),
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
