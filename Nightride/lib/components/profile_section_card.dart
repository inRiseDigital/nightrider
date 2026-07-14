import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  static const _bg     = Color(0xFF0F0F0F);
  static const _border = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final pad = AppResponsive.profileCardPadding(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, pad - 2, pad, pad),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.profileCardTitleFont(context),
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: AppResponsive.gap(context, 8)),
          child,
        ],
      ),
    );
  }
}
