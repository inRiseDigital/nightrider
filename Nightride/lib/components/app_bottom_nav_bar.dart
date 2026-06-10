import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/responsive.dart';

import '../../core/theme/app_theme.dart';

@immutable
class AppNavItem {
  const AppNavItem({required this.icon});
  final IconData icon;
}

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

    Widget navRow = Row(
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
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        );
      }),
    );

    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    Widget bar = isIOS
        ? GlassMorphismMaterial(
            blurIntensity: 24.0,
            opacity: 0.18,
            tintColor: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            enableGlassBorder: true,
            enableBackgroundDistortion: false,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: innerHPad),
                child: navRow,
              ),
            ),
          )
        : Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: innerHPad),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: navRow,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomMargin + bottomSafe),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: bar,
        ),
      ),
    );
  }
}
