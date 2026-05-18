import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/domain/profile_models.dart';
import 'package:nightride/providers/profile_providers.dart';
import 'package:nightride/services/user_profile_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _city;

  File? _pickedImage;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileProvider).data;
    _displayName = TextEditingController(text: data.displayName);
    _username    = TextEditingController(text: data.username);
    _phone       = TextEditingController(text: data.phone);
    _city        = TextEditingController(text: data.city);
    _email       = TextEditingController(text: data.email.isNotEmpty
        ? data.email
        : FirebaseAuth.instance.currentUser?.email ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _saving = false); return; }

    try {
      final service = ref.read(userProfileServiceProvider);

      // Save avatar as base64 in Firestore if a new photo was picked
      if (_pickedImage != null) {
        await service.saveAvatarBase64(uid, _pickedImage!);
      }

      // Save profile fields to Firestore (always runs)
      final profileData = ref.read(profileProvider).data;
      final instagram = profileData.socialLinks
          .firstWhere((l) => l.type == SocialType.instagram,
              orElse: () => const SocialLink(type: SocialType.instagram, handle: ''))
          .handle;
      final facebook = profileData.socialLinks
          .firstWhere((l) => l.type == SocialType.facebook,
              orElse: () => const SocialLink(type: SocialType.facebook, handle: ''))
          .handle;

      await service.updateProfile(
        uid: uid,
        displayName: _displayName.text.trim(),
        username: _username.text.trim(),
        pronouns: profileData.pronouns,
        bio: profileData.bio,
        interests: profileData.interests,
        instagram: instagram,
        facebook: facebook,
        phone: _phone.text.trim(),
        city: _city.text.trim(),
      );

      // Try email change separately so it doesn't block profile save
      final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      final newEmail = _email.text.trim();
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        try {
          await FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(newEmail);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification email sent. Check your inbox to confirm the change.')),
            );
          }
        } catch (_) {
          // Email change requires re-login — profile fields are already saved above
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBase64 = ref.watch(avatarBase64Provider).asData?.value;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Changes', style: TextStyle(fontSize: AppResponsive.font(context, 15).clamp(12.5, 16.5), fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with upload button
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: AppResponsive.font(context, 90).clamp(76.0, 99.0),
                      height: AppResponsive.font(context, 90).clamp(76.0, 99.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2),
                      ),
                      child: ClipOval(
                        child: _pickedImage != null
                            ? Image.file(_pickedImage!, fit: BoxFit.cover)
                            : avatarBase64 != null
                                ? Image.memory(base64Decode(avatarBase64), fit: BoxFit.cover)
                                : Icon(Icons.person_rounded, color: Colors.white38, size: AppResponsive.icon(context, 44).clamp(36.0, 48.0)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: AppResponsive.font(context, 28).clamp(24.0, 31.0),
                        height: AppResponsive.font(context, 28).clamp(24.0, 31.0),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.scaffold, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: AppResponsive.icon(context, 14).clamp(12.0, 15.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(8),
            Center(
              child: Text('Tap to change photo',
                  style: TextStyle(color: Colors.white38, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0))),
            ),
            const Gap(24),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.redAccent, fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5))),
              ),
              const Gap(16),
            ],

            _SectionLabel('Basic Info'),
            const Gap(12),
            _Field(controller: _displayName, label: 'Display Name', icon: Icons.badge_outlined, hint: 'Your full name'),
            const Gap(14),
            _Field(controller: _username, label: 'Username', icon: Icons.alternate_email_rounded, hint: 'e.g. nightrider99'),
            const Gap(14),
            _Field(controller: _city, label: 'City', icon: Icons.location_city_rounded, hint: 'e.g. Tokyo, Colombo'),
            const Gap(28),

            _SectionLabel('Contact'),
            const Gap(12),
            _Field(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
              helperText: 'A verification email will be sent if you change this.',
            ),
            const Gap(14),
            _Field(
              controller: _phone,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              hint: '+1 234 567 8900',
              keyboardType: TextInputType.phone,
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: Colors.white38, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0), fontWeight: FontWeight.w900, letterSpacing: 1.2),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 12.5).clamp(10.5, 13.5), fontWeight: FontWeight.w700)),
        const Gap(6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14.5).clamp(12.5, 16.0)),
          cursorColor: AppTheme.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white24, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: AppTheme.primaryLight.withValues(alpha: 0.7), size: AppResponsive.icon(context, 20).clamp(17.0, 22.0)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5),
            ),
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.white38, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0)),
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
