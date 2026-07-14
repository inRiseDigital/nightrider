import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
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
    const Color cream = Color(0xFFF3EAD6);
    const Color neonLime = Color(0xFFDFFF2F);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'MY PROFILE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anton(
              fontSize: AppResponsive.profilePageTitleFont(context),
              color: cream,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (isEditing)
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'CANCEL',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                  color: neonLime,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          )
        else
          InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.more_vert_rounded,
                size: AppResponsive.icon(context, 20).clamp(16.0, 22.0),
                color: const Color(0xFFFAFAFA),
              ),
            ),
          ),
      ],
    );
  }
}
