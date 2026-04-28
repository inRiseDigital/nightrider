// lib/features/home/presentation/widgets/home_location_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_theme.dart';

class HomeLocationRow extends StatelessWidget {
  const HomeLocationRow({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          Icons.location_on_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: 16.sp,
        ),
        Gap(6.w),
        Expanded(
          child: Text(
            country,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
