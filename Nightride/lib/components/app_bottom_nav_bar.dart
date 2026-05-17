import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/responsive.dart';

import '../../core/theme/app_theme.dart';

@immutable
class AppNavItem {
  const AppNavItem({required this.icon});
  final IconData icon;
}

/// Pinned bottom navigation bar.
///
/// Responsive behaviour:
/// • Item width derives from `Expanded` flex, never a hard `.w` value, so
///   four icons always distribute evenly across the available width.
/// • Bar height + icon size scale per [FormFactor].
/// • On foldables/tablets the bar is capped at [AppDimensions.bottomNavMaxWidth]
///   and centred, so it doesn't sprawl across the full ~720dp+ screen.
/// • Bottom inset uses `MediaQuery.viewPaddingOf(...).bottom` (gesture/nav-bar
///   safe), padded with a small visual margin from [AppDimensions].
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final hPad = AppDimensions.pagePaddingHorizontal(context);
    final maxWidth = AppDimensions.bottomNavMaxWidth(context);
    final height = AppDimensions.bottomNavHeight(context);
    final iconSize = AppDimensions.bottomNavIconSize(context);
    final bottomMargin = AppDimensions.bottomNavBottomMargin(context);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final radius = AppDimensions.cardRadius(context);
    final innerHPad = context.responsive(
      compact: 8.0,
      regular: 10.0,
      foldable: 12.0,
      tablet: 14.0,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomMargin + bottomSafe),
      // heightFactor:1 → Center shrinks vertically to its child instead of
      // stretching to the slot's full maxHeight. Scaffold's bottomNavigationBar
      // slot is laid out with maxHeight = screenHeight (NOT infinity), so a
      // plain Center would expand to the full screen, collapsing the body to
      // 0 dp and rendering the bar's content in the screen's vertical middle.
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: innerHPad),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(radius * 0.7),
                    child: SizedBox.expand(
                      child: Center(
                        child: Icon(
                          items[i].icon,
                          size: iconSize,
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
