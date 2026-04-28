// lib/common/widgets/app_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 18.h),
      child: Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(items.length, (int index) {
            final bool isSelected = index == selectedIndex;

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                width: 62.w,
                height: 52.h,
                child: Center(
                  child: Icon(
                    items[index].icon,
                    size: 26.sp,
                    color:
                        isSelected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
