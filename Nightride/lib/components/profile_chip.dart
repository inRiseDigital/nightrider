import 'package:flutter/material.dart';

import 'package:nightride/core/responsive/app_responsive.dart';

class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.text,
    required this.editable,
    required this.onTap,
    this.isSelected = false,
  });

  final String text;
  final bool editable;
  final VoidCallback onTap;
  final bool isSelected;

  static const _neonLime = Color(0xFFDFFF2F);
  static const _border   = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final selected = isSelected;
    return InkWell(
      onTap: editable ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          minHeight: AppResponsive.interestChipHeight(context),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.profileChipPaddingH(context),
          vertical:   AppResponsive.profileChipPaddingV(context),
        ),
        decoration: BoxDecoration(
          color: selected ? _neonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _neonLime : _border,
            width: 1.5,
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
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF070707) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
