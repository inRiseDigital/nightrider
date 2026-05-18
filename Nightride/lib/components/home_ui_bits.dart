// lib/features/home/presentation/widgets/home_ui_bits.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

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
  Widget build(BuildContext context) => Gap(h);
}

class MiniIconButton extends StatelessWidget {
  const MiniIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.gap(context, 38).clamp(34.0, 44.0);
    final radius = AppResponsive.radius(context, 14).clamp(12.0, 16.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: AppResponsive.icon(context, 18).clamp(15.0, 20.0),
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
    final size = AppResponsive.gap(context, 36).clamp(32.0, 42.0);
    final radius = AppResponsive.radius(context, 14).clamp(12.0, 16.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(radius),
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
    final h = AppResponsive.gap(context, 36).clamp(32.0, 42.0);
    final radius = AppResponsive.radius(context, 14).clamp(12.0, 16.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, 10).clamp(8.0, 14.0),
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(
                fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 14.0),
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const Gap(2),
            trailing,
          ],
        ),
      ),
    );
  }
}
