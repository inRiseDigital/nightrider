// lib/components/home_section_title.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Retro poster section header with an optional "VIEW ALL" link on the right.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.onViewAll,
    this.accentColor,
  });

  final String title;
  final VoidCallback? onViewAll;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.cream;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anton(
              fontSize:
                  AppResponsive.font(context, 20).clamp(16.0, 24.0),
              fontWeight: FontWeight.w400,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (onViewAll != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              'VIEW ALL',
              style: TextStyle(
                fontSize: AppResponsive.font(context, 11).clamp(10.0, 12.0),
                fontWeight: FontWeight.w800,
                color: AppTheme.hotPink,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
