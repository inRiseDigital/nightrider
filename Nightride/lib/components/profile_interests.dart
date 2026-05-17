import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nightride/components/profile_chip.dart';
import 'package:nightride/components/profile_section_card.dart';
import 'package:nightride/components/profile_tiny_hint.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

class ProfileInterests extends StatelessWidget {
  const ProfileInterests({
    super.key,
    required this.isEditing,
    required this.selectedInterests,
    required this.allOptions,
    required this.isSelected,
    required this.onToggle,
    required this.onRemove,
  });

  final bool isEditing;

  /// selected (view uses profile data, edit uses draft)
  final List<String> selectedInterests;

  /// master list (dummy)
  final List<String> allOptions;

  /// selection checker (uses draft state)
  final bool Function(String label) isSelected;

  /// toggle add/remove from master list
  final ValueChanged<String> onToggle;

  /// remove from selected section (quick remove)
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      // VIEW MODE (simple clean wrap)
      return ProfileSectionCard(
        title: 'Interests',
        child: Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children:
              selectedInterests
                  .map(
                    (t) => ProfileChip(text: t, editable: false, onTap: () {}),
                  )
                  .toList(),
        ),
      );
    }

    // EDIT MODE (proper UX)
    return ProfileSectionCard(
      title: 'Interests',
      trailing: const ProfileTinyHint(text: 'Tap chips to select'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Selected',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: 10.h),

          if (selectedInterests.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                'No interests selected yet.',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children:
                  selectedInterests.map((String t) {
                    return ProfileChip(
                      text: t,
                      editable: true,
                      onTap: () => onRemove(t), // quick remove
                    );
                  }).toList(),
            ),

          SizedBox(height: 16.h),

          Text(
            'Choose from all',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: 10.h),

          // master list chips with selected styling
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children:
                allOptions.map((String opt) {
                  final bool active = isSelected(opt);

                  return InkWell(
                    onTap: () => onToggle(opt),
                    borderRadius: BorderRadius.circular(999.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      constraints: BoxConstraints(
                        minHeight: AppResponsive.interestChipHeight(context),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.profileChipPaddingH(context),
                        vertical: AppResponsive.profileChipPaddingV(context),
                      ),
                      decoration: BoxDecoration(
                        color:
                            active
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color:
                              active
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (active) ...<Widget>[
                            Icon(
                              Icons.check_rounded,
                              size: AppResponsive.icon(context, 16),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            SizedBox(width: AppResponsive.gap(context, 6)),
                          ],
                          Flexible(
                            child: Text(
                              opt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppResponsive.profileChipFont(context),
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
