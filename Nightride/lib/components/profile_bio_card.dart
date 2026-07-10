import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _kNeonLime   = Color(0xFFDFFF2F);
const _kBorderGray = Color(0xFF333333);
const _kWhite      = Color(0xFFFAFAFA);
const _kCard       = Color(0xFF151515);

class ProfileBioCard extends StatelessWidget {
  const ProfileBioCard({
    super.key,
    required this.isEditing,
    required this.value,
    required this.onChanged,
  });

  final bool isEditing;
  final String value;
  final ValueChanged<String> onChanged;

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
          // ── Section heading ──
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
                'BIO',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.0),
                  color: _kNeonLime,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Body: editor or display ──
          if (isEditing)
            _BioEditor(initial: value, onChanged: onChanged)
          else
            value.trim().isEmpty
                ? Text(
                    'ADD YOUR BIO...',
                    style: TextStyle(
                      fontSize: AppResponsive.profileBodyFont(context),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: _kWhite.withValues(alpha: 0.25),
                      letterSpacing: 0.3,
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: AppResponsive.profileBodyFont(context),
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: _kWhite,
                    ),
                  ),
        ],
      ),
    );
  }
}

// ─── Bio text field ──────────────────────────────────────────────────────────

class _BioEditor extends StatefulWidget {
  const _BioEditor({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_BioEditor> createState() => _BioEditorState();
}

class _BioEditorState extends State<_BioEditor> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      maxLines: 5,
      minLines: 2,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: AppResponsive.profileBodyFont(context),
        fontWeight: FontWeight.w500,
        color: _kWhite,
        height: 1.55,
      ),
      cursorColor: _kNeonLime,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Write something about yourself...',
        hintStyle: TextStyle(
          fontSize: AppResponsive.profileBodyFont(context),
          fontWeight: FontWeight.w500,
          color: _kWhite.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
