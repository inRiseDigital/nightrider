// lib/components/search_section_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_theme.dart';

class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8.sp,
          height: 8.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.9),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 14.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
