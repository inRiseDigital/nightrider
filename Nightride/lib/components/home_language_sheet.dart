// lib/features/home/presentation/widgets/home_language_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/home_providers.dart';

class HomeLanguageSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final HomeLanguage current = ref.read(homeLanguageProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return _BottomSheetShell(
          title: AppLocalizations.of(context)!.selectLanguage,
          child: Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: HomeLanguage.values.length,
              separatorBuilder: (_, __) => SizedBox(
                height: AppResponsive.gap(context, 8).clamp(6.0, 10.0),
              ),
              itemBuilder: (BuildContext context, int index) {
                final lang = HomeLanguage.values[index];
                return _LangTile(
                  title: langName(lang),
                  subtitle: langLabel(lang),
                  selected: current == lang,
                  onTap: () {
                    ref.read(homeLanguageProvider.notifier).state = lang;
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxW = AppResponsive.languageModalMaxWidth(context);
    final maxH = AppResponsive.languageModalMaxHeight(context);
    final modalPad = AppResponsive.languageModalPadding(context);
    final radius = AppResponsive.radius(context, 22);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppResponsive.pagePadding(context),
          0,
          AppResponsive.pagePadding(context),
          AppResponsive.gap(context, 14),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, -12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(modalPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppResponsive.languageTitleFont(context),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(
                              AppResponsive.gap(context, 6).clamp(4.0, 8.0),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: AppResponsive.icon(context, 20).clamp(16.0, 22.0),
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.gap(context, 12)),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rowH = AppResponsive.languageRowHeight(context);
    final codeBox = AppResponsive.languageCodeBoxSize(context);
    final radius = AppResponsive.radius(context, 14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: rowH,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, 10),
          vertical: AppResponsive.gap(context, 6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.07 : 0.04),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: codeBox,
              height: codeBox,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(
                  AppResponsive.radius(context, 10),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              alignment: Alignment.center,
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.languageCodeFont(context),
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            SizedBox(width: AppResponsive.gap(context, 12)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.languageNameFont(context),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                size: AppResponsive.icon(context, 18).clamp(14.0, 20.0),
                color: AppTheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
