import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/components/auth/auth_text_field.dart';
import 'package:nightride/components/auth/password_text_field.dart';
import 'package:nightride/components/auth/social_login_row.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/pages/auth/sign_up_page.dart';
import 'package:nightride/pages/forgotPw/forgot_pw.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/user_profile_service.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithEmailPassword(
            email: email,
            password: password,
          );
      if (mounted) await _routeForUser(cred.user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) await _routeForUser(cred.user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeForUser(User? user) async {
    String role = 'user';
    bool onboardingDone = true;
    if (user != null) {
      final svc = ref.read(userProfileServiceProvider);
      await svc.createIfAbsent(user);
      role = await svc.getUserRole(user.uid);
      if (role != 'organizer') {
        onboardingDone = await svc.hasCompletedOnboarding(user.uid);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => role == 'organizer'
            ? const OrganizerShellPage()
            : onboardingDone
                ? AppShellPage()
                : const OnboardQuestionnaireTemplatePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hPad = AuthDimensions.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AuthDimensions.gapXL(context) + 8),

                  // ── Vinyl mascot logo ─────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapL(context)),

                  // ── "WELCOME BACK" heading ────────────────────────────
                  Center(
                    child: Text(
                      'WELCOME BACK',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.anton(
                        fontSize: AuthDimensions.titleFontSize(context) + 6,
                        color: AppTheme.cream,
                        letterSpacing: 2.5,
                        height: 1.1,
                      ),
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapS(context)),

                  // ── Subtext ───────────────────────────────────────────
                  Center(
                    child: Text(
                      'READY FOR TONIGHT?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.anton(
                        fontSize: AuthDimensions.subtitleFontSize(context) + 1,
                        color: AppTheme.neonLime,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapXL(context) + 4),

                  // ── Email field ───────────────────────────────────────
                  _RetroTextField(
                    child: AuthTextField(
                      controller: _emailController,
                      hint: l.email,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapM(context)),

                  // ── Password field ────────────────────────────────────
                  _RetroTextField(
                    child: PasswordTextField(
                      controller: _passwordController,
                      hint: l.password,
                      autofillHints: const [AutofillHints.password],
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapS(context)),

                  // ── Forgot password ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPwPage()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Text(
                          l.forgotPassword,
                          style: TextStyle(
                            fontSize: AuthDimensions.subtitleFontSize(context),
                            color: AppTheme.hotPink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapL(context)),

                  // ── SIGN IN button ────────────────────────────────────
                  _RetroSignInButton(
                    label: l.signIn,
                    isLoading: _isLoading,
                    onPressed: _handleSignIn,
                  ),

                  SizedBox(height: AuthDimensions.gapL(context)),

                  // ── OR divider ────────────────────────────────────────
                  _RetroDivider(),

                  SizedBox(height: AuthDimensions.gapL(context)),

                  // ── Google sign-in card ───────────────────────────────
                  _GoogleSignInCard(
                    onTap: _isLoading ? null : _handleGoogleSignIn,
                  ),

                  SizedBox(height: AuthDimensions.gapXL(context)),

                  // ── Sign up link ──────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${l.dontHaveAccount} ",
                          style: TextStyle(
                            fontSize: AuthDimensions.subtitleFontSize(context),
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          ),
                          child: Text(
                            l.signUp.toUpperCase(),
                            style: TextStyle(
                              fontSize: AuthDimensions.subtitleFontSize(context),
                              color: AppTheme.neonLime,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapM(context)),

                  // ── Continue as guest ─────────────────────────────────
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => AppShellPage()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(
                          l.continueAsGuest,
                          style: TextStyle(
                            fontSize: AuthDimensions.subtitleFontSize(context),
                            color: Colors.white.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AuthDimensions.gapL(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal design widgets ──────────────────────────────────────────────────

/// Wraps an auth text field with the retro dark-panel + neon-lime focus border style.
/// The existing AuthTextField/PasswordTextField already accept controller and hints;
/// this wrapper overrides the visual container so we don't need to rewrite the components.
class _RetroTextField extends StatelessWidget {
  const _RetroTextField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // We rely on the child's own decoration but sit it inside a dark-background
    // container that matches the retro spec (#151515 fill, #333333 border).
    // The child's built-in focused border (neonLime via AppTheme.primary) already
    // applies on focus, so no extra focus listener is needed here.
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              fillColor: AppTheme.darkGray,
            ),
      ),
      child: child,
    );
  }
}

/// Retro neon-lime "SIGN IN" button — neonLime background, bold black uppercase text.
class _RetroSignInButton extends StatelessWidget {
  const _RetroSignInButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final height = AuthDimensions.buttonHeight(context);
    final radius = AuthDimensions.buttonBorderRadius(context);
    final fontSize = AuthDimensions.buttonFontSize(context);

    final Widget content = isLoading
        ? SizedBox(
            height: height * 0.42,
            width: height * 0.42,
            child: const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2.5,
            ),
          )
        : Text(
            label.toUpperCase(),
            style: GoogleFonts.anton(
              fontSize: fontSize,
              color: Colors.black,
              letterSpacing: 2.0,
            ),
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonLime,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.neonLime.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.black54,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: content,
      ),
    );
  }
}

/// "OR" divider styled for the retro poster look.
class _RetroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.borderGray,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.anton(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 2.0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.borderGray,
          ),
        ),
      ],
    );
  }
}

/// Dark-card Google sign-in button.
class _GoogleSignInCard extends StatelessWidget {
  const _GoogleSignInCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = AuthDimensions.buttonHeight(context);
    final radius = AuthDimensions.buttonBorderRadius(context);
    final fontSize = AuthDimensions.subtitleFontSize(context) + 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppTheme.borderGray,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' icon using material icon
            Icon(
              Icons.g_mobiledata_rounded,
              size: fontSize + 14,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
