// lib/features/auth/presentation/pages/sign_in_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/pages/auth/sign_up_page.dart';
import 'package:nightride/pages/forgotPw/forgot_pw.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/user_profile_service.dart';

import 'package:nightride/l10n/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';

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

      if (mounted) {
        final user = cred.user;
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
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => role == 'organizer'
                ? const OrganizerShellPage()
                : onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage()),
          );
        }
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        final user = cred.user;
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
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => role == 'organizer'
                ? const OrganizerShellPage()
                : onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage()),
          );
        }
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
    // Keep everything visible on normal devices. Scroll only on very small screens.
    final requiredPanelPx = 560.h;
    final basePanelPx = 0.63.sh;
    final panelPx = math.min(0.78.sh, math.max(basePanelPx, requiredPanelPx));

    // AuthProcessScaffold expects design-units (it will apply `.h`)
    final reservedGapDesignUnits = panelPx / ScreenUtil().scaleHeight;

    return AuthProcessScaffold(
      title: 'Sign IN',
      subtitle: 'Create your account to get started',
      titleTopGap: 88,
      reservedBottomGap: reservedGapDesignUnits,
      bottomPanel: _SignInBottomPanel(
        panelHeightPx: panelPx,
        emailController: _emailController,
        passwordController: _passwordController,
        isLoading: _isLoading,
        onSignIn: _handleSignIn,
        onGoogleSignIn: _handleGoogleSignIn,
      ),
    );
  }
}

class _SignInBottomPanel extends StatelessWidget {
  final double panelHeightPx;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;

  const _SignInBottomPanel({
    required this.panelHeightPx,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignIn,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final requiredContentPx = 560.h;
    final needsScroll = panelHeightPx < requiredContentPx;

    return SizedBox(
      height: panelHeightPx,
      width: 1.sw,
      child: Stack(
        children: [
          // Panel body (same style)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0816),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(48.r),
                  topRight: Radius.circular(48.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.22),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 30,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48.r),
                    topRight: Radius.circular(48.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withOpacity(0.09),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Thin glowing top stroke
          Positioned(
            top: 0,
            left: 22.w,
            right: 22.w,
            child: Container(
              height: 2.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primary.withOpacity(0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            top: 44.h,
            left: 22.w,
            right: 22.w,
            bottom: 18.h,
            child:
                needsScroll
                    ? SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _PanelContent(
                        emailController: emailController,
                        passwordController: passwordController,
                        isLoading: isLoading,
                        onSignIn: onSignIn,
                        onGoogleSignIn: onGoogleSignIn,
                      ),
                    )
                    : _PanelContent(
                      emailController: emailController,
                      passwordController: passwordController,
                      isLoading: isLoading,
                      onSignIn: onSignIn,
                      onGoogleSignIn: onGoogleSignIn,
                    ),
          ),
        ],
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;

  const _PanelContent({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignIn,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InputField(
          controller: emailController,
          icon: Icons.mail_outline_rounded,
          hint: AppLocalizations.of(context)!.email,
          isPassword: false,
        ),
        Gap(18.h),
        _InputField(
          controller: passwordController,
          icon: Icons.lock_outline_rounded,
          hint: AppLocalizations.of(context)!.password,
          isPassword: true,
        ),

        Gap(14.h),

        // Forgot password? (right aligned)
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPwPage()),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.forgotPassword,
              style: TextStyle(
                fontSize: 13.5.sp,
                color: AppTheme.primaryLight.withOpacity(0.75),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),

        Gap(18.h),
        _SignInButton(onPressed: onSignIn, isLoading: isLoading),

        Gap(22.h),

        // Don't have an account? Sign up
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${AppLocalizations.of(context)!.dontHaveAccount} ",
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: () {
                // navigate to sign up
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.signUp,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: AppTheme.primaryLight.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        Gap(22.h),

        // Divider with "Or sign with"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1.h,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                'Or sign with',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1.h,
                color: Colors.white.withOpacity(0.25),
              ),
            ),
          ],
        ),

        Gap(22.h),

        // Social icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(kind: _SocialKind.google, onTap: onGoogleSignIn),
            const Gap(22),
            const _SocialIcon(kind: _SocialKind.facebook),
            const Gap(22),
            const _SocialIcon(kind: _SocialKind.apple),
          ],
        ),

        Gap(28.h),

        // Continue as guest
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AppShellPage()),
            );
          },
          child: Text(
            AppLocalizations.of(context)!.continueAsGuest,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.primaryLight.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool isPassword;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    required this.isPassword,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final obscure = widget.isPassword ? _obscure : false;

    return Container(
      height: 64.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        color: Colors.black.withOpacity(0.10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        keyboardType:
            widget.isPassword
                ? TextInputType.visiblePassword
                : TextInputType.emailAddress,
        obscureText: obscure,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: 15.sp,
        ),
        cursorColor: AppTheme.primaryLight,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 18.w, right: 10.w),
            child: Icon(
              widget.icon,
              color: AppTheme.primaryLight.withOpacity(0.85),
              size: 22.sp,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppTheme.primaryLight.withOpacity(0.45),
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            vertical: 18.h,
            horizontal: 18.w,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.r),
            borderSide: BorderSide(
              color: AppTheme.primary.withOpacity(0.55),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.r),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          suffixIcon:
              widget.isPassword
                  ? Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20.sp,
                        color: AppTheme.primaryLight.withOpacity(0.55),
                      ),
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _SignInButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62.h,
      width: 1.sw,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.28),
          foregroundColor: AppTheme.primaryLight.withOpacity(0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 24.h,
                  width: 24.h,
                  child: const CircularProgressIndicator(
                    color: AppTheme.primaryLight,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  AppLocalizations.of(context)!.signIn,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
      ),
    );
  }
}

enum _SocialKind { google, facebook, apple }

class _SocialIcon extends StatelessWidget {
  final _SocialKind kind;
  final VoidCallback? onTap;

  const _SocialIcon({required this.kind, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = 40.w;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: _Logo(kind: kind, size: 32.w)),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final _SocialKind kind;
  final double size;

  const _Logo({required this.kind, required this.size});

  @override
  Widget build(BuildContext context) {
    // Placeholder icons (layout stays exact).
    // Replace with SVG/PNG assets later for exact logos.
    switch (kind) {
      case _SocialKind.google:
        return Icon(
          Icons.g_mobiledata_rounded,
          size: size,
          color: Colors.white,
        );
      case _SocialKind.facebook:
        return Icon(Icons.facebook_rounded, size: size, color: Colors.white);
      case _SocialKind.apple:
        return Icon(Icons.apple, size: size, color: Colors.white);
    }
  }
}
