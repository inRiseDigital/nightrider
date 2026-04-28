import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/marquee_text.dart';
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
    final TextStyle hintStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14.r),
                      bottomLeft: Radius.circular(14.r),
                    ),
                    child: Row(
                      children: <Widget>[
                        Gap(12.w),
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.88),
                          size: 20.sp,
                        ),
                        Gap(10.w),
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
                  height: 44.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                      topRight: Radius.circular(14.r),
                      bottomRight: Radius.circular(14.r),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
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
        Gap(10.w),
        _SquareIconButton(
          icon: Icons.grid_view_rounded,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color:
                selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18.sp,
              color: Colors.white.withValues(alpha: selected ? 1.0 : 0.92),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20.sp,
            color: Colors.white.withValues(alpha: 0.90),
          ),
        ),
      ),
    );
  }
}
