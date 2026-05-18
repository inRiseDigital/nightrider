import 'package:flutter/material.dart';
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
  final List<String> selectedInterests;
  final List<String> allOptions;
  final bool Function(String label) isSelected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final labelFont = AppResponsive.font(context, 12).clamp(10.5, 13.0);

    if (!isEditing) {
      return ProfileSectionCard(
        title: 'Interests',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: selectedInterests
              .map((t) => ProfileChip(text: t, editable: false, onTap: () {}))
              .toList(),
        ),
      );
    }

    return ProfileSectionCard(
      title: 'Interests',
      trailing: const ProfileTinyHint(text: 'Tap chips to select'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Selected',
            style: TextStyle(
              fontSize: labelFont,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 10),

          if (selectedInterests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                'No interests selected yet.',
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selectedInterests.map((String t) {
                return ProfileChip(
                  text: t,
                  editable: true,
                  onTap: () => onRemove(t),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          Text(
            'Choose from all',
            style: TextStyle(
              fontSize: labelFont,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allOptions.map((String opt) {
              final bool active = isSelected(opt);

              return InkWell(
                onTap: () => onToggle(opt),
                borderRadius: BorderRadius.circular(999),
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
                    color: active
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
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
