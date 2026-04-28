// lib/features/home/presentation/widgets/home_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/home_providers.dart';
import 'home_language_sheet.dart';
import 'home_ui_bits.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool darkOn = ref.watch(homeDarkToggleProvider);
    final HomeLanguage lang = ref.watch(homeLanguageProvider);

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.orbitron(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Spacer(),
        TextPillButton(
          text: langLabel(lang),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18.sp,
          ),
          onTap: () => HomeLanguageSheet.show(context, ref),
        ),
        Gap(10.w),
        IconPillButton(
          onTap: () {},
          child: Icon(
            Icons.notifications_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18.sp,
          ),
        ),
      ],
    );
  }
}
