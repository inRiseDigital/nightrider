import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/profile_models.dart';

class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({
    super.key,
    required this.data,
    required this.isEditing,
    required this.onMenu,
    required this.onCancel,
  });

  final ProfileData data;
  final bool isEditing;
  final VoidCallback onMenu;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        if (isEditing)
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          )
        else
          InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.more_vert_rounded,
                size: 18.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}
