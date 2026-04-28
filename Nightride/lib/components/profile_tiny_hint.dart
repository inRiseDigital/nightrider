import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileTinyHint extends StatelessWidget {
  const ProfileTinyHint({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}
