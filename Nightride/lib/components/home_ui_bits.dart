// lib/features/home/presentation/widgets/home_ui_bits.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_theme.dart';

class HomeSmoothScrollBehavior extends ScrollBehavior {
  const HomeSmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class GapH extends StatelessWidget {
  const GapH(this.h, {super.key});
  final double h;

  @override
  Widget build(BuildContext context) => Gap(h.h);
}

class MiniIconButton extends StatelessWidget {
  const MiniIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 38.sp,
        height: 38.sp,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18.sp,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class IconPillButton extends StatelessWidget {
  const IconPillButton({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 36.sp,
        height: 36.sp,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class TextPillButton extends StatelessWidget {
  const TextPillButton({
    super.key,
    required this.text,
    required this.trailing,
    required this.onTap,
  });

  final String text;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 36.sp,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Gap(2.w),
            trailing,
          ],
        ),
      ),
    );
  }
}
