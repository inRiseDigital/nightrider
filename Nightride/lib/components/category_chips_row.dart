import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';

class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onSelected,
  });

  final List<MapCategory> items;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: items.length,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (BuildContext context, int index) {
          final MapCategory item = items[index];
          final bool selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected?.call(selected ? null : index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.85)
                    : AppTheme.surface.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.55),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: selected ? Colors.white : AppTheme.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
