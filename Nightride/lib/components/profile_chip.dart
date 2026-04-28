import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_theme.dart';

class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.text,
    required this.editable,
    required this.onTap,
  });

  final String text;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: editable ? onTap : null,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color:
                editable
                    ? AppTheme.primary.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.86),
          ),
        ),
      ),
    );
  }
}
