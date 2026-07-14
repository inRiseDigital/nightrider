// lib/components/search_empty_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _cream      = Color(0xFFF3EAD6);
const Color _neonLime   = Color(0xFFDFFF2F);
const Color _hotPink    = Color(0xFFFF3D73);
const Color _white      = Color(0xFFFAFAFA);
const Color _darkGray   = Color(0xFF151515);
const Color _borderGray = Color(0xFF2A2A2A);

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ── Mascot / logo ──────────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Outer glow ring
                Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: _hotPink.withValues(alpha: 0.18),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
                // Dark circle background
                Container(
                  width: 108.r,
                  height: 108.r,
                  decoration: BoxDecoration(
                    color: _darkGray,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _borderGray,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  // Try app logo first; fall back to emoji mascot
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 72.r,
                      height: 72.r,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        '🎧',
                        style: TextStyle(fontSize: 44.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            // ── "NO VIBES HERE YET" ────────────────────────────────────────
            Text(
              'NO VIBES\nHERE YET',
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                fontSize: 30.sp,
                color: _cream,
                letterSpacing: 2.0,
                height: 1.05,
              ),
            ),
            SizedBox(height: 4.h),

            // ── Neon underline accent ──────────────────────────────────────
            Container(
              width: 48.w,
              height: 3,
              decoration: BoxDecoration(
                color: _neonLime,
                borderRadius: BorderRadius.circular(2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _neonLime.withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // ── Subtext ────────────────────────────────────────────────────
            Text(
              query.isNotEmpty
                  ? 'Nothing matching\n"$query" found.\nTry a different keyword.'
                  : 'Search for clubs, bars, and events\nhappening near you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSans3(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: _white.withValues(alpha: 0.40),
                height: 1.6,
              ),
            ),
            SizedBox(height: 32.h),

            // ── Clear / retry button ───────────────────────────────────────
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 28.w,
                  vertical: 13.h,
                ),
                decoration: BoxDecoration(
                  color: _neonLime.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(
                    color: _neonLime.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _neonLime.withValues(alpha: 0.10),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.refresh_rounded,
                      size: 16.sp,
                      color: _neonLime,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'CLEAR SEARCH',
                      style: GoogleFonts.anton(
                        fontSize: 13.sp,
                        color: _neonLime,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
