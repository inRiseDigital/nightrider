import 'package:flutter/material.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import '../../../../../core/theme/app_theme.dart';

class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.text,
    required this.editable,
    required this.onTap,
  });

  final String text;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: editable ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: BoxConstraints(
          minHeight: AppResponsive.interestChipHeight(context),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.profileChipPaddingH(context),
          vertical: AppResponsive.profileChipPaddingV(context),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: editable
                ? AppTheme.primary.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Center(
          widthFactor: 1.0,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppResponsive.profileChipFont(context),
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ),
      ),
    );
  }
}
