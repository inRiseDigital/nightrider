import 'package:flutter/material.dart';
import 'package:nightride/components/profile_section_card.dart'
    show ProfileSectionCard;
import 'package:nightride/core/responsive/app_responsive.dart';

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
    return ProfileSectionCard(
      title: 'Bio',
      child:
          isEditing
              ? _BioEditor(initial: value, onChanged: onChanged)
              : Text(
                value,
                style: TextStyle(
                  fontSize: AppResponsive.profileBodyFont(context),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
    );
  }
}

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
      maxLines: 3,
      minLines: 1,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: AppResponsive.profileBodyFont(context),
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.92),
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Write something about you…',
        hintStyle: TextStyle(
          fontSize: AppResponsive.profileBodyFont(context),
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
