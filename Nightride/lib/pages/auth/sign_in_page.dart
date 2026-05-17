import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/components/auth/auth_footer_links.dart';
import 'package:nightride/components/auth/auth_screen_layout.dart';
import 'package:nightride/components/auth/auth_text_field.dart';
import 'package:nightride/components/auth/guest_button.dart';
import 'package:nightride/components/auth/password_text_field.dart';
import 'package:nightride/components/auth/primary_auth_button.dart';
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

    return AuthScreenLayout(
      title: 'Sign IN',
      subtitle: 'Create your account to get started',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            hint: l.email,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          SizedBox(height: AuthDimensions.gapM(context)),
          PasswordTextField(
            controller: _passwordController,
            hint: l.password,
            autofillHints: const [AutofillHints.password],
          ),
          SizedBox(height: AuthDimensions.gapS(context)),
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
                    color: AppTheme.primaryLight.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AuthDimensions.gapM(context)),
          PrimaryAuthButton(
            label: l.signIn,
            isLoading: _isLoading,
            onPressed: _handleSignIn,
          ),
          SizedBox(height: AuthDimensions.gapM(context)),
          AuthFooterLinks(
            prompt: l.dontHaveAccount,
            linkText: l.signUp,
            onLinkTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            ),
          ),
          SizedBox(height: AuthDimensions.gapL(context)),
          SocialLoginRow(
            dividerLabel: 'Or sign with',
            onGoogle: _handleGoogleSignIn,
          ),
          SizedBox(height: AuthDimensions.gapM(context)),
          Center(
            child: GuestButton(
              label: l.continueAsGuest,
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => AppShellPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
