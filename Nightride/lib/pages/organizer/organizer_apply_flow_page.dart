import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/organizer/organizer_verify_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/organizer_service.dart';

const _fieldFill = Color(0xFF17171A);

enum _Stage { signup, phone, otp }

/// Mobile counterpart of the webpanel's four-stage apply flow
/// (SignupStage/PhoneStage/OtpStage/ReviewStage) -- a self-contained entry
/// point that does not require an existing sign-in, since "Apply Here" is
/// meant for someone who has never had any Night Ride account. Phone/OTP are
/// stubbed exactly like the webpanel: no SMS is sent, any code of at least 4
/// digits passes (see lib/organizer/store.tsx's PHONE_AUTH_STUBBED comment).
class OrganizerApplyFlowPage extends ConsumerStatefulWidget {
  const OrganizerApplyFlowPage({super.key});

  @override
  ConsumerState<OrganizerApplyFlowPage> createState() => _OrganizerApplyFlowPageState();
}

class _OrganizerApplyFlowPageState extends ConsumerState<OrganizerApplyFlowPage> {
  _Stage _stage = _Stage.signup;
  bool _busy = false;
  String _error = '';
  User? _user;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Resume an in-flight application instead of restarting at signup, same
    // as the webpanel's onAuthStateChanged resume logic.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      _user = current;
      _stage = _Stage.phone;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitSignup() => _run(() async {
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text;
        if (email.isEmpty || !email.contains('@')) {
          throw 'Enter a valid email.';
        }
        if (password.length < 6) {
          throw 'Password must be at least 6 characters.';
        }
        final cred = await ref.read(authServiceProvider).signUpWithEmailPassword(
              email: email,
              password: password,
            );
        _user = cred.user;
        if (!mounted) return;
        setState(() => _stage = _Stage.phone);
      });

  Future<void> _submitPhone() => _run(() async {
        final phone = _phoneCtrl.text.trim();
        if (!RegExp(r'^\+[1-9]\d{6,15}$').hasMatch(phone.replaceAll(RegExp(r'[\s()-]'), ''))) {
          throw 'Enter the number in international format, for example +971 50 123 4567.';
        }
        // Phone auth is deliberately not wired up -- no SMS is sent. The
        // number is still saved to the profile so it stays reachable.
        setState(() => _stage = _Stage.otp);
      });

  Future<void> _submitOtp() => _run(() async {
        if (_otpCtrl.text.trim().length < 4) {
          throw 'Enter the code sent to your phone.';
        }
        final user = _user ?? FirebaseAuth.instance.currentUser;
        if (user == null) throw 'You are not signed in. Restart the application.';

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'phone': _phoneCtrl.text.trim(), 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        await ref.read(organizerServiceProvider).beginApplication(user.uid);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrganizerVerifyPage()),
        );
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'NIGHT', style: GoogleFonts.anton(color: AppTheme.neonLime)),
                        TextSpan(text: 'RIDE', style: GoogleFonts.anton(color: AppTheme.textPrimary)),
                      ]),
                      style: GoogleFonts.anton(fontSize: 26, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 28),
                  switch (_stage) {
                    _Stage.signup => _SignupForm(
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        busy: _busy,
                        error: _error,
                        onSubmit: _submitSignup,
                      ),
                    _Stage.phone => _PhoneForm(
                        phoneCtrl: _phoneCtrl,
                        busy: _busy,
                        error: _error,
                        onSubmit: _submitPhone,
                      ),
                    _Stage.otp => _OtpForm(
                        otpCtrl: _otpCtrl,
                        phone: _phoneCtrl.text.trim(),
                        busy: _busy,
                        error: _error,
                        onSubmit: _submitOtp,
                        onResend: () => setState(() => _stage = _Stage.phone),
                      ),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Stages -------------------------------------------------------------------

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool busy;
  final String error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StageTitle(
          title: 'Create your organizer account',
          detail: "We'll review your venue after a quick verification.",
        ),
        const SizedBox(height: 20),
        _Field(label: 'Email', controller: emailCtrl, hint: 'you@venue.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _Field(label: 'Password', controller: passwordCtrl, hint: String.fromCharCodes(List.filled(8, 0x2022)), obscureText: true),
        if (error.isNotEmpty) ...[const SizedBox(height: 12), _Banner(error)],
        const SizedBox(height: 18),
        _PrimaryButton(label: 'Continue', isLoading: busy, onTap: busy ? null : onSubmit),
      ],
    );
  }
}

class _PhoneForm extends StatelessWidget {
  const _PhoneForm({required this.phoneCtrl, required this.busy, required this.error, required this.onSubmit});

  final TextEditingController phoneCtrl;
  final bool busy;
  final String error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StageTitle(title: 'Verify your phone', detail: "We'll text a code to confirm it's you."),
        const SizedBox(height: 20),
        _Field(label: 'Phone number', controller: phoneCtrl, hint: '+971 50 123 4567', keyboardType: TextInputType.phone),
        if (error.isNotEmpty) ...[const SizedBox(height: 12), _Banner(error)],
        const SizedBox(height: 18),
        _PrimaryButton(label: 'Send code', isLoading: busy, onTap: busy ? null : onSubmit),
      ],
    );
  }
}

class _OtpForm extends StatelessWidget {
  const _OtpForm({
    required this.otpCtrl,
    required this.phone,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onResend,
  });

  final TextEditingController otpCtrl;
  final String phone;
  final bool busy;
  final String error;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageTitle(title: 'Enter the code', detail: 'Sent to $phone'),
        const SizedBox(height: 20),
        _Field(
          label: 'Verification code',
          controller: otpCtrl,
          hint: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        if (error.isNotEmpty) ...[const SizedBox(height: 12), _Banner(error)],
        const SizedBox(height: 18),
        _PrimaryButton(label: 'Verify', isLoading: busy, onTap: busy ? null : onSubmit),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          const Text(
            'Debug only -- no SMS is sent; any 4+ digits will pass.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onResend,
            child: const Text("Didn't get it? Resend code",
                style: TextStyle(color: AppTheme.teal, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// -- Shared bits ---------------------------------------------------------------

class _StageTitle extends StatelessWidget {
  const _StageTitle({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(detail, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          textAlign: textAlign,
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 15, color: AppTheme.textHint),
            filled: true,
            fillColor: _fieldFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.isLoading = false});
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: onTap == null ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171), height: 1.4)),
    );
  }
}
