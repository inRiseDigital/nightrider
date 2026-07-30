// lib/components/home_top_bar.dart
//
// Minimal header row for the Home tab: hamburger (opens the side drawer)
// and a notification bell (opens NotificationsPage). The greeting text lives
// in the hero speech bubble instead of here.
import 'package:flutter/material.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/notifications_page.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final actionH = AppResponsive.headerActionHeight(context);
    final notifSize = AppResponsive.notificationButtonSize(context);

    return Row(
      children: [
        _IconSquareButton(
          icon: Icons.menu_rounded,
          size: actionH,
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const Spacer(),
        _IconSquareButton(
          icon: Icons.notifications_outlined,
          size: notifSize,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
      ],
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppResponsive.radius(context, 10)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          borderRadius:
              BorderRadius.circular(AppResponsive.radius(context, 10)),
          border: Border.all(color: AppTheme.borderGray, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: AppTheme.cream.withValues(alpha: 0.9),
          size: AppResponsive.headerActionIconSize(context),
        ),
      ),
    );
  }
}
