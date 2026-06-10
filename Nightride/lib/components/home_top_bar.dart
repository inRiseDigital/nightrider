// lib/features/home/presentation/widgets/home_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';
import 'home_language_sheet.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable — kept for potential title-styling use later
    final bool darkOn = ref.watch(homeDarkToggleProvider);
    final HomeLanguage lang = ref.watch(homeLanguageProvider);

    final actionH = AppResponsive.headerActionHeight(context);
    final notifSize = AppResponsive.notificationButtonSize(context);
    final langWidth = AppResponsive.languageButtonWidth(context);

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anton(
              fontSize: AppResponsive.font(context, 20).clamp(16.0, 22.0),
              fontWeight: FontWeight.w400,
              color: AppTheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Spacer(),
        _LanguageButton(
          label: langLabel(lang),
          height: actionH,
          width: langWidth,
          onTap: () => HomeLanguageSheet.show(context, ref),
        ),
        SizedBox(width: AppResponsive.gap(context, 10)),
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
      borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
      child: Container(
        height: height,
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, 10),
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            SizedBox(width: AppResponsive.gap(context, 2)),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.9),
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
      borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.notifications_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: AppResponsive.headerActionIconSize(context),
        ),
      ),
    );
  }
}
