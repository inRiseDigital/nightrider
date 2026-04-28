// lib/components/home_category_rail.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';

class HomeCategoryRail extends ConsumerWidget {
  const HomeCategoryRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final chips = kCategories;

    return SizedBox(
      height: 98.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // "ALL" chip
          _CategoryItem(
            label: 'ALL',
            imageUrl: '',
            isSelected: selected == 'ALL',
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = 'ALL',
          ),
          Gap(14.w),
          ...chips.asMap().entries.map((entry) {
            final chip = entry.value;
            final isSelected = selected == chip.title;
            return Padding(
              padding: EdgeInsets.only(right: entry.key < chips.length - 1 ? 14.w : 0),
              child: _CategoryItem(
                label: chip.title,
                imageUrl: chip.imageUrl,
                isSelected: isSelected,
                onTap: () {
                  final next = isSelected ? 'ALL' : chip.title;
                  ref.read(selectedCategoryProvider.notifier).state = next;
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double size = 58.w;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.surface,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.10),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.30)
                        : Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl.isEmpty
                    ? Icon(Icons.grid_view_rounded, color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.55), size: 24.sp)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.06)),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image_rounded, color: Colors.white.withValues(alpha: 0.55), size: 18.sp),
                        ),
                      ),
              ),
            ),
            Gap(10.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isSelected ? AppTheme.primaryLight : Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
