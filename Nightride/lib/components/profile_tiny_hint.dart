import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

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
        fontSize: AppResponsive.font(context, 10.5).clamp(9.5, 11.5),
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}
