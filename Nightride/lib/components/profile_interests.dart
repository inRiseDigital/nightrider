import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kBlack      = Color(0xFF070707);
const _kNeonLime   = Color(0xFFDFFF2F);
const _kBorderGray = Color(0xFF333333);
const _kWhite      = Color(0xFFFAFAFA);
const _kCard       = Color(0xFF151515);
const _kDarkBg     = Color(0xFF0D0D0D);

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorderGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Heading row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _kNeonLime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'INTERESTS',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.0),
                      color: _kNeonLime,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              if (isEditing)
                Text(
                  'Tap to select',
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
                    color: _kWhite.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── View mode ──
          if (!isEditing) ...[
            if (selectedInterests.isEmpty)
              Text(
                'No interests added yet.',
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                  fontWeight: FontWeight.w600,
                  color: _kWhite.withValues(alpha: 0.30),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedInterests
                    .map((t) => _InterestChip(text: t, selected: true, onTap: null))
                    .toList(),
              ),
          ]

          // ── Edit mode ──
          else ...[
            // Selected chips section
            _SectionLabel(label: 'SELECTED', context: context),
            const SizedBox(height: 8),

            if (selectedInterests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _kDarkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorderGray),
                ),
                child: Text(
                  'No interests selected yet.',
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 12).clamp(11.0, 13.0),
                    fontWeight: FontWeight.w600,
                    color: _kWhite.withValues(alpha: 0.30),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedInterests
                    .map((t) => _InterestChip(
                          text: t,
                          selected: true,
                          onTap: () => onRemove(t),
                          showRemove: true,
                        ))
                    .toList(),
              ),

            const SizedBox(height: 18),

            // All options section
            _SectionLabel(label: 'ALL OPTIONS', context: context),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allOptions.map((opt) {
                final bool active = isSelected(opt);
                return _InterestChip(
                  text: opt,
                  selected: active,
                  onTap: () => onToggle(opt),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-section label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.context});
  final String label;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
        fontWeight: FontWeight.w900,
        color: _kWhite.withValues(alpha: 0.45),
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── Interest chip ────────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.text,
    required this.selected,
    required this.onTap,
    this.showRemove = false,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final bool showRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
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
          color: selected ? _kNeonLime : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? _kNeonLime : _kBorderGray,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.profileChipFont(context),
                  fontWeight: FontWeight.w800,
                  color: selected ? _kBlack : _kWhite,
                ),
              ),
            ),
            if (showRemove && selected) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.close_rounded,
                size: AppResponsive.icon(context, 13).clamp(11.0, 14.0),
                color: _kBlack,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
