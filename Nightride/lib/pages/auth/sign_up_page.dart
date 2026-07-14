// lib/features/auth/presentation/pages/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/services/auth_service.dart';

import 'package:nightride/l10n/app_localizations.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kBlack = Color(0xFF070707);
const _kCream = Color(0xFFF3EAD6);
const _kNeonLime = Color(0xFFDFFF2F);
const _kDarkGray = Color(0xFF151515);
const _kBorderGray = Color(0xFF333333);

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).signUpWithEmailPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardQuestionnaireTemplatePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardQuestionnaireTemplatePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  64,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Vinyl mascot ────────────────────────────────────────
                  Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),

                  const Gap(20),

                  // ── JOIN THE RIDE heading ────────────────────────────────
                  Text(
                    'JOIN THE RIDE',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 38),
                      color: _kCream,
                      letterSpacing: 2.5,
                      height: 1.05,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Gap(6),

                  // ── CREATE YOUR ACCOUNT subtext ──────────────────────────
                  Text(
                    'CREATE YOUR ACCOUNT',
                    style: GoogleFonts.inter(
                      fontSize: AppResponsive.font(context, 12),
                      color: _kNeonLime,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Gap(32),

                  // ── Input fields ─────────────────────────────────────────
                  _RetroInputField(
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    hint: AppLocalizations.of(context)!.email,
                    isPassword: false,
                  ),
                  const Gap(14),
                  _RetroInputField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Enter New Password',
                    isPassword: true,
                  ),
                  const Gap(14),
                  _RetroInputField(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Confirm Password',
                    isPassword: true,
                  ),

                  const Gap(24),

                  // ── GET STARTED button ───────────────────────────────────
                  _GetStartedButton(
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                  ),

                  const Gap(20),

                  // ── Divider ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: _kBorderGray),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR SIGN WITH',
                          style: GoogleFonts.inter(
                            fontSize: AppResponsive.font(context, 10),
                            color: _kBorderGray,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: _kBorderGray),
                      ),
                    ],
                  ),

                  const Gap(18),

                  // ── Social icons ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RetroSocialIcon(
                        kind: _SocialKind.google,
                        onTap: _handleGoogleSignUp,
                      ),
                      const Gap(22),
                      const _RetroSocialIcon(kind: _SocialKind.facebook),
                      const Gap(22),
                      const _RetroSocialIcon(kind: _SocialKind.apple),
                    ],
                  ),

                  const Spacer(),

                  const Gap(28),

                  // ── Already have an account ──────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account?  ',
                            style: GoogleFonts.inter(
                              fontSize: AppResponsive.font(context, 13.5),
                              color: Colors.white.withValues(alpha: 0.50),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'LOG IN',
                            style: GoogleFonts.inter(
                              fontSize: AppResponsive.font(context, 13.5),
                              color: _kNeonLime,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Gap(16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Retro Input Field ─────────────────────────────────────────────────────────

class _RetroInputField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool isPassword;

  const _RetroInputField({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.isPassword,
  });

  @override
  State<_RetroInputField> createState() => _RetroInputFieldState();
}

class _RetroInputFieldState extends State<_RetroInputField> {
  bool _obscure = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final obscure = widget.isPassword ? _obscure : false;

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: Container(
        height: AppResponsive.gap(context, 58).clamp(52, 68),
        decoration: BoxDecoration(
          color: _kDarkGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? _kNeonLime : _kBorderGray,
            width: _focused ? 1.8 : 1.2,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: _kNeonLime.withOpacity(0.12),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.isPassword
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress,
          obscureText: obscure,
          style: GoogleFonts.inter(
            color: _kCream,
            fontSize: AppResponsive.font(context, 15),
            fontWeight: FontWeight.w400,
          ),
          cursorColor: _kNeonLime,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(
                widget.icon,
                color: _focused ? _kNeonLime : _kBorderGray,
                size: AppResponsive.icon(context, 20),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: AppResponsive.font(context, 14),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.symmetric(
              vertical: AppResponsive.gap(context, 16).clamp(13, 20),
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: widget.isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: AppResponsive.icon(context, 18),
                        color: _focused
                            ? _kNeonLime.withOpacity(0.70)
                            : Colors.white.withOpacity(0.30),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// ── GET STARTED Button ────────────────────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _GetStartedButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.gap(context, 58).clamp(52, 68),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kNeonLime,
          foregroundColor: _kBlack,
          disabledBackgroundColor: _kNeonLime.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: _kBlack,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'GET STARTED',
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 17),
                  color: _kBlack,
                  letterSpacing: 2.5,
                ),
              ),
      ),
    );
  }
}

// ── Social Icons ──────────────────────────────────────────────────────────────

enum _SocialKind { google, facebook, apple }

class _RetroSocialIcon extends StatelessWidget {
  final _SocialKind kind;
  final VoidCallback? onTap;

  const _RetroSocialIcon({required this.kind, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.icon(context, 48);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _kDarkGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorderGray, width: 1.2),
        ),
        child: Center(
          child: _SocialLogo(kind: kind, size: AppResponsive.icon(context, 24)),
        ),
      ),
    );
  }
}

class _SocialLogo extends StatelessWidget {
  final _SocialKind kind;
  final double size;

  const _SocialLogo({required this.kind, required this.size});

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _SocialKind.google:
        return Icon(Icons.g_mobiledata_rounded, size: size, color: _kCream);
      case _SocialKind.facebook:
        return Icon(Icons.facebook_rounded, size: size, color: _kCream);
      case _SocialKind.apple:
        return Icon(Icons.apple, size: size, color: _kCream);
    }
  }
}
