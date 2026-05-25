import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

class OrganizerApplyPage extends StatefulWidget {
  const OrganizerApplyPage({super.key});

  @override
  State<OrganizerApplyPage> createState() => _OrganizerApplyPageState();
}

class _OrganizerApplyPageState extends State<OrganizerApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _orgNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _useAccountEmail = true;
  String _eventsPerMonth = '1–2';
  final Set<String> _selectedTypes = {};
  bool _submitting = false;

  static const _eventTypes = [
    'Club Night', 'Music Festival', 'Live Concert', 'DJ Set',
    'Sports Event', 'Corporate', 'Art & Culture', 'Food & Drink',
    'Comedy', 'Other',
  ];
  static const _eventFrequencies = ['1–2', '3–5', '5–10', '10+'];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _orgNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _instagramCtrl.dispose();
    _websiteCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      _showSnack('Please select at least one event type.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('organizer_requests')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'displayName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'orgName': _orgNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'eventTypes': _selectedTypes.toList(),
        'eventsPerMonth': _eventsPerMonth,
        'instagram': _instagramCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted! An admin will review it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      _showSnack('Could not submit. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Apply as Organizer',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppResponsive.pagePadding(context),
            20,
            AppResponsive.pagePadding(context),
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.15),
                      AppTheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AppTheme.accent, size: AppResponsive.icon(context, 28)),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become an Organizer',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppResponsive.font(context, 15),
                            ),
                          ),
                          const Gap(3),
                          Text(
                            'Fill in your details and we\'ll review your application within 24–48 hours.',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: AppResponsive.font(context, 12),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(28),

              // ── Section 1: Personal Info ──────────────────────────────────
              _SectionHeader(title: 'Personal Info', icon: Icons.person_outline_rounded),
              const Gap(14),

              _Field(
                label: 'Full Name',
                controller: _nameCtrl,
                hint: 'Your full name',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const Gap(14),

              // Email with "same as account" toggle
              _buildEmailField(),
              const Gap(14),

              _Field(
                label: 'Phone Number',
                controller: _phoneCtrl,
                hint: '+1 234 567 8900',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const Gap(28),

              // ── Section 2: Organization ───────────────────────────────────
              _SectionHeader(title: 'Organization', icon: Icons.business_outlined),
              const Gap(14),

              _Field(
                label: 'Organization / Venue Name',
                controller: _orgNameCtrl,
                hint: 'e.g. Skyline Events, Club Noir',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Organization name is required' : null,
              ),
              const Gap(14),

              _Field(
                label: 'City / Location',
                controller: _cityCtrl,
                hint: 'e.g. Colombo, London, Melbourne',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const Gap(28),

              // ── Section 3: Event Types ────────────────────────────────────
              _SectionHeader(title: 'Event Types', icon: Icons.event_rounded),
              const Gap(6),
              Text(
                'What kind of events do you organise?',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: AppResponsive.font(context, 12)),
              ),
              const Gap(14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypes.map((type) {
                  final selected = _selectedTypes.contains(type);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedTypes.remove(type);
                      } else {
                        _selectedTypes.add(type);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accent.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            Icon(Icons.check_rounded, size: 13, color: AppTheme.accent),
                            const Gap(5),
                          ],
                          Text(
                            type,
                            style: GoogleFonts.inter(
                              fontSize: AppResponsive.font(context, 12),
                              fontWeight: FontWeight.w600,
                              color: selected ? AppTheme.accent : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(28),

              // ── Section 4: Frequency ──────────────────────────────────────
              _SectionHeader(title: 'Events Per Month', icon: Icons.bar_chart_rounded),
              const Gap(14),
              Row(
                children: _eventFrequencies.map((f) {
                  final selected = _eventsPerMonth == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _eventsPerMonth = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: f == _eventFrequencies.last ? 0 : 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              f,
                              style: GoogleFonts.inter(
                                fontSize: AppResponsive.font(context, 14),
                                fontWeight: FontWeight.w800,
                                color: selected ? AppTheme.primaryLight : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(28),

              // ── Section 5: Social / Web ───────────────────────────────────
              _SectionHeader(title: 'Online Presence', icon: Icons.link_rounded),
              const Gap(6),
              Text(
                'Helps us verify your events are real.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: AppResponsive.font(context, 12)),
              ),
              const Gap(14),

              _Field(
                label: 'Instagram or Facebook link',
                controller: _instagramCtrl,
                hint: 'https://instagram.com/yourpage',
                keyboardType: TextInputType.url,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'At least one social link is required' : null,
              ),
              const Gap(14),

              _Field(
                label: 'Website (optional)',
                controller: _websiteCtrl,
                hint: 'https://yourwebsite.com',
                keyboardType: TextInputType.url,
              ),
              const Gap(28),

              // ── Section 6: About ──────────────────────────────────────────
              _SectionHeader(title: 'About You', icon: Icons.info_outline_rounded),
              const Gap(14),

              _Field(
                label: 'Tell us about your events',
                controller: _bioCtrl,
                hint: 'Describe what kind of events you run, your experience, and why you want to be an organizer on Nightride...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Please write at least 20 characters'
                    : null,
              ),
              const Gap(36),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Submit Application',
                          style: GoogleFonts.inter(
                            fontSize: AppResponsive.font(context, 15),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final accountEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: GoogleFonts.inter(
            fontSize: AppResponsive.font(context, 13),
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const Gap(7),
        TextFormField(
          controller: _emailCtrl,
          enabled: !_useAccountEmail,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: Colors.white, fontSize: AppResponsive.font(context, 14)),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: AppResponsive.font(context, 13)),
            filled: true,
            fillColor: _useAccountEmail
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            suffixIcon: _useAccountEmail
                ? Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 13),
                        const Gap(4),
                        Text(
                          'Verified',
                          style: GoogleFonts.inter(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const Gap(8),
        GestureDetector(
          onTap: () {
            setState(() {
              _useAccountEmail = !_useAccountEmail;
              if (_useAccountEmail) _emailCtrl.text = accountEmail;
            });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _useAccountEmail
                      ? AppTheme.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _useAccountEmail
                        ? AppTheme.accent
                        : Colors.white30,
                  ),
                ),
                child: _useAccountEmail
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
              const Gap(8),
              Text(
                'Use my account email ($accountEmail)',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: AppResponsive.font(context, 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable field ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint = '',
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppResponsive.font(context, 13),
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const Gap(7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: Colors.white, fontSize: AppResponsive.font(context, 14)),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: AppResponsive.font(context, 13)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppResponsive.icon(context, 16), color: AppTheme.accent),
        const Gap(8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppResponsive.font(context, 13),
            fontWeight: FontWeight.w800,
            color: AppTheme.accent,
            letterSpacing: 0.5,
          ),
        ),
        const Gap(10),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1)),
      ],
    );
  }
}
