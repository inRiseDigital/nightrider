import 'package:flutter/material.dart';
import 'package:nightride/components/profile_section_card.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

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
            padding: EdgeInsets.only(bottom: i == links.length - 1 ? 0 : 10),
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
    final IconData icon = link.type == SocialType.instagram
        ? Icons.camera_alt_rounded
        : Icons.facebook_rounded;
    final iconContainerSize = AppResponsive.gap(context, 34).clamp(30.0, 38.0);
    final textFont = AppResponsive.font(context, 13).clamp(11.5, 14.0);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: AppResponsive.icon(context, 18).clamp(15.0, 20.0),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: TextEditingController(text: link.handle)
                      ..selection = TextSelection.collapsed(
                        offset: link.handle.length,
                      ),
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: textFont,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '@username',
                      hintStyle: TextStyle(
                        fontSize: textFont,
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
                      fontSize: textFont,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: AppResponsive.icon(context, 22).clamp(18.0, 24.0),
            color: Colors.white.withValues(alpha: 0.28),
          ),
        ],
      ),
    );
  }
}
