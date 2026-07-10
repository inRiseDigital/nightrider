// lib/components/home_category_rail.dart
//
// Retro nightlife poster style — vertical list of category items for the
// EXPLORE section. Each row uses a dark card with a coloured left-border
// accent and bold uppercase Anton label. Tapping navigates to
// CategoryDetailPage with the correct tag.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/category_detail_page.dart';

// ── Category metadata ─────────────────────────────────────────────────────────

class _CatMeta {
  final String label;
  final String emoji;
  final Color accentColor;
  const _CatMeta({
    required this.label,
    required this.emoji,
    required this.accentColor,
  });
}

const _kCategories = <_CatMeta>[
  _CatMeta(label: 'CLUB',   emoji: '🏛️', accentColor: AppTheme.hotPink),
  _CatMeta(label: 'DJ',     emoji: '🎧', accentColor: AppTheme.neonLime),
  _CatMeta(label: 'TECHNO', emoji: '⚡', accentColor: AppTheme.teal),
  _CatMeta(label: 'RAVE',   emoji: '🌀', accentColor: AppTheme.hotPink),
  _CatMeta(label: 'EDM',    emoji: '🔊', accentColor: AppTheme.neonLime),
  _CatMeta(label: 'HOUSE',  emoji: '🎵', accentColor: AppTheme.teal),
  _CatMeta(label: 'LIVE',   emoji: '🎸', accentColor: AppTheme.cream),
];

// ── Widget ────────────────────────────────────────────────────────────────────

class HomeCategoryRail extends ConsumerWidget {
  const HomeCategoryRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: _kCategories.map((meta) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CategoryRow(
            meta: meta,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryDetailPage(category: meta.label),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Single row ────────────────────────────────────────────────────────────────

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({required this.meta, required this.onTap});

  final _CatMeta meta;
  final VoidCallback onTap;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _pressed = false;

  static const _bgColor     = Color(0xFF0F0F0F);
  static const _borderColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final meta       = widget.meta;
    final isSelected = false; // stateless selection — driven by navigation
    final labelColor = isSelected ? meta.accentColor : Colors.white;
    final leftBorder = isSelected ? meta.accentColor : _borderColor;

    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve:    Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left:   BorderSide(color: meta.accentColor, width: 3),
              top:    BorderSide(color: _borderColor, width: 1),
              right:  BorderSide(color: _borderColor, width: 1),
              bottom: BorderSide(color: _borderColor, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.gap(context, 16),
            vertical:   AppResponsive.gap(context, 14),
          ),
          child: Row(
            children: [
              // Emoji icon
              Text(
                meta.emoji,
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 22).clamp(18.0, 26.0),
                ),
              ),
              SizedBox(width: AppResponsive.gap(context, 14)),
              // Category label
              Expanded(
                child: Text(
                  meta.label,
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.font(context, 16).clamp(14.0, 20.0),
                    color: labelColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Accent chevron
              Icon(
                Icons.chevron_right_rounded,
                color: meta.accentColor.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
