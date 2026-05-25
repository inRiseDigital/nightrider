import 'package:flutter/material.dart';

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
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'My Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.profilePageTitleFont(context),
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
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.75),
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
                size: AppResponsive.icon(context, 18).clamp(15.0, 20.0),
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}
