// lib/components/search_section_header.dart
import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import '../core/theme/app_theme.dart';

class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.9),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: AppResponsive.font(context, 11).clamp(10.0, 12.0),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
