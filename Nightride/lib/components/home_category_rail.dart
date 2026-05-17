// lib/components/home_category_rail.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';

const _kMeta = <String, _Meta>{
  'ALL':    _Meta(Icons.auto_awesome_rounded,   Color(0xFF7C3AED), Color(0xFF4C1D95)),
  'CLUB':   _Meta(Icons.nightlife_rounded,       Color(0xFFBE185D), Color(0xFF831843)),
  'DJ':     _Meta(Icons.headphones_rounded,      Color(0xFF0E7490), Color(0xFF164E63)),
  'TECHNO': _Meta(Icons.graphic_eq_rounded,      Color(0xFF1D4ED8), Color(0xFF1E3A8A)),
  'RAVE':   _Meta(Icons.flare_rounded,           Color(0xFF047857), Color(0xFF064E3B)),
  'EDM':    _Meta(Icons.music_note_rounded,      Color(0xFFB45309), Color(0xFF78350F)),
  'HOUSE':  _Meta(Icons.speaker_rounded,         Color(0xFF0F766E), Color(0xFF134E4A)),
  'LIVE':   _Meta(Icons.mic_rounded,             Color(0xFFB91C1C), Color(0xFF7F1D1D)),
};

const _kAccent = <String, Color>{
  'ALL':    Color(0xFFA78BFA),
  'CLUB':   Color(0xFFF472B6),
  'DJ':     Color(0xFF67E8F9),
  'TECHNO': Color(0xFF93C5FD),
  'RAVE':   Color(0xFF6EE7B7),
  'EDM':    Color(0xFFFCD34D),
  'HOUSE':  Color(0xFF5EEAD4),
  'LIVE':   Color(0xFFFCA5A5),
};

class _Meta {
  final IconData icon;
  final Color bg1;
  final Color bg2;
  const _Meta(this.icon, this.bg1, this.bg2);
}

_Meta _metaFor(String t) =>
    _kMeta[t] ?? const _Meta(Icons.category_rounded, AppTheme.primary, AppTheme.accent);

Color _accentFor(String t) => _kAccent[t] ?? Colors.white;

// ── Rail ──────────────────────────────────────────────────────────────────────

class HomeCategoryRail extends ConsumerWidget {
  const HomeCategoryRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final chips = kCategories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _Tile(
              label: 'ALL',
              isSelected: selected == 'ALL',
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = 'ALL',
            ),
            const SizedBox(width: 10),
            ...chips.asMap().entries.map((entry) {
              final chip = entry.value;
              final isSel = selected == chip.title;
              return Padding(
                padding: EdgeInsets.only(
                    right: entry.key == chips.length - 1 ? 0 : 10),
                child: _Tile(
                  label: chip.title,
                  isSelected: isSel,
                  onTap: () {
                    final next = isSel ? 'ALL' : chip.title;
                    ref.read(selectedCategoryProvider.notifier).state = next;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Spotify-style tile ────────────────────────────────────────────────────────

class _Tile extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tile({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final meta   = _metaFor(widget.label);
    final accent = _accentFor(widget.label);
    const w = 148.0;
    const h = 82.0;

    return GestureDetector(
      onTapDown:  (_) => setState(() => _down = true),
      onTapUp:    (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.95 : (widget.isSelected ? 1.03 : 1.0),
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: widget.isSelected
                  ? [meta.bg1, meta.bg2]
                  : [
                      meta.bg1.withValues(alpha: 0.75),
                      meta.bg2.withValues(alpha: 0.75),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: meta.bg1.withValues(alpha: 0.55),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Large rotated icon watermark — bottom-right
              Positioned(
                right: -12,
                bottom: -10,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Icon(
                    meta.icon,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),

              // Top-right accent dot (selected indicator)
              if (widget.isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

              // Label — bottom-left
              Positioned(
                left: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppResponsive.font(context, 15),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
