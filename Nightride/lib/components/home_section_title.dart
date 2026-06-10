// lib/features/home/presentation/widgets/home_section_title.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.anton(
        fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
        fontWeight: FontWeight.w400,
        color: AppTheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
