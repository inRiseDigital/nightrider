// lib/components/home_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/components/home_language_sheet.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeLanguage lang = ref.watch(homeLanguageProvider);
    final actionH = AppResponsive.headerActionHeight(context);
    final notifSize = AppResponsive.notificationButtonSize(context);
    final langWidth = AppResponsive.languageButtonWidth(context);

    final displayName = username.isEmpty ? 'YOU' : username.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Greeting text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HEY $displayName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 22).clamp(18.0, 26.0),
                  fontWeight: FontWeight.w400,
                  color: AppTheme.cream,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Language button
        _LanguageButton(
          label: langLabel(lang),
          height: actionH,
          width: langWidth,
          onTap: () => HomeLanguageSheet.show(context, ref),
        ),
        SizedBox(width: AppResponsive.gap(context, 8)),
        // Notification bell
        _NotificationButton(
          size: notifSize,
          onTap: () {},
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.height,
    required this.width,
    required this.onTap,
  });

  final String label;
  final double height;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppResponsive.radius(context, 10)),
      child: Container(
        height: height,
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, 10),
        ),
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          borderRadius:
              BorderRadius.circular(AppResponsive.radius(context, 10)),
          border: Border.all(color: AppTheme.borderGray, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.headerActionFontSize(context),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cream,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(width: AppResponsive.gap(context, 2)),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.cream.withValues(alpha: 0.75),
              size: AppResponsive.headerActionIconSize(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.size, required this.onTap});
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
          Icons.notifications_outlined,
          color: AppTheme.cream.withValues(alpha: 0.9),
          size: AppResponsive.headerActionIconSize(context),
        ),
      ),
    );
  }
}
