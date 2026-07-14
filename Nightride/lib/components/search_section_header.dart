// lib/components/search_section_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _neonLime = Color(0xFFDFFF2F);
const Color _white    = Color(0xFFFAFAFA);

class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.text,
    this.onViewAll,
  });

  final String text;

  /// Optional callback for the "VIEW ALL" action. If null, the action is hidden.
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final double labelFont = AppResponsive.font(context, 12).clamp(10.5, 13.0);
    final double actionFont = AppResponsive.font(context, 11).clamp(9.5, 12.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // ── Neon lime accent bar ─────────────────────────────────────────
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _neonLime,
            borderRadius: BorderRadius.circular(2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _neonLime.withValues(alpha: 0.45),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // ── Section label ─────────────────────────────────────────────────
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.anton(
              fontSize: labelFont,
              color: _white.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
        ),

        // ── Optional "VIEW ALL" ───────────────────────────────────────────
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'VIEW ALL',
              style: GoogleFonts.anton(
                fontSize: actionFont,
                color: _neonLime,
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }
}
