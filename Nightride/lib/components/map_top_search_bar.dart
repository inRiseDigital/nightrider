import 'package:flutter/material.dart';
import 'package:nightride/components/marquee_text.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

/// Dark neon-retro search bar used at the top of the Map/Live screen.
///
/// Layout: [Search field] [Location button] [Grid button]
/// Colors follow the Night Rite retro poster palette.
class MapTopSearchBar extends StatelessWidget {
  const MapTopSearchBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.onGridTap,
    this.onSearchTap,
    this.searchHint = 'Search events',
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onGridTap;
  final VoidCallback? onSearchTap;
  final String searchHint;

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const _border     = Color(0xFF2A2A2A);
  static const _neonLime   = Color(0xFFDFFF2F);
  static const _hotPink    = Color(0xFFFF3D73);

  @override
  Widget build(BuildContext context) {
    final barHeight = AppResponsive.mapSearchBarHeight(context);
    final radius    = AppResponsive.radius(context, 14);
    final iconSize  = AppResponsive.icon(context, 18);
    final hPad      = AppResponsive.gap(context, 12);
    final gap       = AppResponsive.gap(context, 8);

    final TextStyle hintStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.40),
      fontSize: AppResponsive.font(context, 13),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    return Row(
      children: [
        // ── Search field ────────────────────────────────────────────────────
        Expanded(
          child: _NeonContainer(
            height: barHeight,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(radius),
              splashColor: _neonLime.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              child: Row(
                children: [
                  SizedBox(width: hPad),
                  Icon(
                    Icons.search_rounded,
                    color: _neonLime,
                    size: iconSize + 2,
                  ),
                  SizedBox(width: AppResponsive.gap(context, 9)),
                  Expanded(
                    child: MarqueeText(
                      text: searchHint,
                      style: hintStyle,
                    ),
                  ),
                  // Subtle neon-lime divider + mic icon at right
                  Container(
                    width: 1,
                    height: barHeight * 0.5,
                    color: _border,
                  ),
                  SizedBox(width: AppResponsive.gap(context, 10)),
                  Icon(
                    Icons.mic_none_rounded,
                    color: Colors.white.withValues(alpha: 0.30),
                    size: iconSize,
                  ),
                  SizedBox(width: hPad),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: gap),

        // ── My-location button ──────────────────────────────────────────────
        _NeonIconButton(
          icon: Icons.my_location_rounded,
          size: barHeight,
          radius: radius,
          iconSize: iconSize,
          isActive: selectedIndex == 0,
          activeColor: _neonLime,
          onTap: () => onChanged(0),
        ),

        SizedBox(width: gap),

        // ── Grid / list button ──────────────────────────────────────────────
        _NeonIconButton(
          icon: Icons.grid_view_rounded,
          size: barHeight,
          radius: radius,
          iconSize: iconSize,
          isActive: false,
          activeColor: _hotPink,
          onTap: onGridTap ?? () {},
        ),
      ],
    );
  }
}

// ── Shared dark container with neon border ──────────────────────────────────
class _NeonContainer extends StatelessWidget {
  const _NeonContainer({
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  final double height;
  final BorderRadius borderRadius;
  final Widget child;

  static const _surface = Color(0xFF0F0F0F);
  static const _border  = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: borderRadius,
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Square icon button with optional neon active glow ──────────────────────
class _NeonIconButton extends StatelessWidget {
  const _NeonIconButton({
    required this.icon,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData  icon;
  final double    size;
  final double    radius;
  final double    iconSize;
  final bool      isActive;
  final Color     activeColor;
  final VoidCallback onTap;

  static const _surface = Color(0xFF0F0F0F);
  static const _border  = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: activeColor.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.12)
                : _surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isActive ? activeColor.withValues(alpha: 0.70) : _border,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? activeColor.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.45),
                blurRadius: isActive ? 14 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: iconSize,
            color: isActive ? activeColor : Colors.white.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}
