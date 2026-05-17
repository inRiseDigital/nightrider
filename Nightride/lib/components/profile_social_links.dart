import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/components/profile_section_card.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/profile_models.dart';

class ProfileSocialLinks extends StatelessWidget {
  const ProfileSocialLinks({
    super.key,
    required this.isEditing,
    required this.links,
    required this.onChanged,
  });

  final bool isEditing;
  final List<SocialLink> links;
  final void Function(SocialType type, String handle) onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'Social',
      child: Column(
        children: List<Widget>.generate(links.length, (int i) {
          final SocialLink l = links[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == links.length - 1 ? 0 : 10.h),
            child: _SocialRow(
              link: l,
              isEditing: isEditing,
              onChanged: (v) => onChanged(l.type, v),
            ),
          );
        }),
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.link,
    required this.isEditing,
    required this.onChanged,
  });

  final SocialLink link;
  final bool isEditing;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final IconData icon =
        link.type == SocialType.instagram
            ? Icons.camera_alt_rounded
            : Icons.facebook_rounded;

    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34.sp,
            height: 34.sp,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child:
                isEditing
                    ? TextField(
                      controller: TextEditingController(text: link.handle)
                        ..selection = TextSelection.collapsed(
                          offset: link.handle.length,
                        ),
                      onChanged: onChanged,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '@username',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                    : Text(
                      link.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22.sp,
            color: Colors.white.withValues(alpha: 0.28),
          ),
        ],
      ),
    );
  }
}
