import 'package:flutter/material.dart';
import 'package:nightride/components/marquee_text.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final barHeight = AppResponsive.mapSearchBarHeight(context);
    final radius = AppResponsive.radius(context, 14);
    final iconSize = AppResponsive.icon(context, 20);
    final hPad = AppResponsive.gap(context, 12);

    final TextStyle hintStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: AppResponsive.font(context, 13),
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      bottomLeft: Radius.circular(radius),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: hPad),
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.88),
                          size: iconSize,
                        ),
                        SizedBox(width: AppResponsive.gap(context, 10)),
                        Expanded(
                          child: MarqueeText(
                            text: searchHint,
                            style: hintStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: barHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.gap(context, 10),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius * 0.86),
                      bottomLeft: Radius.circular(radius * 0.86),
                      topRight: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
                  child: Row(
                    children: [
                      _TopTabIcon(
                        icon: Icons.my_location_rounded,
                        selected: selectedIndex == 0,
                        onTap: () => onChanged(0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppResponsive.gap(context, 10)),
        _SquareIconButton(
          icon: Icons.grid_view_rounded,
          size: barHeight,
          radius: radius,
          iconSize: iconSize,
          onTap: onGridTap ?? () {},
        ),
      ],
    );
  }
}

class _TopTabIcon extends StatelessWidget {
  const _TopTabIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.icon(context, 28);
    final innerIcon = AppResponsive.icon(context, 18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              size: innerIcon,
              color: Colors.white.withValues(alpha: selected ? 1.0 : 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.onTap,
  });
  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: iconSize,
            color: Colors.white.withValues(alpha: 0.90),
          ),
        ),
      ),
    );
  }
}
