// lib/features/auth/presentation/pages/sign_up_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/services/auth_service.dart';

import 'package:nightride/l10n/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';

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
  String _selectedRole = 'user';

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
        role: _selectedRole,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _selectedRole == 'organizer'
              ? const OrganizerShellPage()
              : const OnboardQuestionnaireTemplatePage()),
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
    final screenW = MediaQuery.sizeOf(context).width;
    final requiredPanelPx = 600.h;
    final basePanelPx = 0.63.sh;
    final panelPx = math.min(
      screenW > 600 ? 0.72.sh : 0.80.sh,
      math.max(basePanelPx, requiredPanelPx),
    );

    final reservedGapDesignUnits = panelPx / ScreenUtil().scaleHeight;
    final topGap = screenW > 600 ? 16.0 : 88.0;

    return AuthProcessScaffold(
      title: 'Sign up',
      subtitle: 'Create your account to get started',
      titleTopGap: topGap,
      reservedBottomGap: reservedGapDesignUnits,
      bottomPanel: _SignUpBottomPanel(
        panelHeightPx: panelPx,
        emailController: _emailController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        isLoading: _isLoading,
        selectedRole: _selectedRole,
        onRoleChanged: (role) => setState(() => _selectedRole = role),
        onSignUp: _handleSignUp,
        onGoogleSignUp: _handleGoogleSignUp,
      ),
    );
  }
}

class _SignUpBottomPanel extends StatelessWidget {
  final double panelHeightPx;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSignUp;
  final VoidCallback onGoogleSignUp;

  const _SignUpBottomPanel({
    required this.panelHeightPx,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSignUp,
    required this.onGoogleSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: panelHeightPx,
      width: 1.sw,
      child: Stack(
        children: [
          // Panel body
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

          // Content — centered with max width for wide screens
          Positioned(
            top: 20.h,
            left: 0,
            right: 0,
            bottom: 18.h,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width > 600
                      ? (MediaQuery.sizeOf(context).width * 0.88).clamp(480.0, 640.0)
                      : 480.0,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width > 600 ? 16.0 : 22.w.clamp(0.0, 32.0),
                  ),
                  child: _PanelContent(
                    emailController: emailController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    isLoading: isLoading,
                    selectedRole: selectedRole,
                    onRoleChanged: onRoleChanged,
                    onSignUp: onSignUp,
                    onGoogleSignUp: onGoogleSignUp,
                  ),
                ),
              ),
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
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSignUp;
  final VoidCallback onGoogleSignUp;

  const _PanelContent({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSignUp,
    required this.onGoogleSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Role selector
        Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _RoleTab(label: 'Party Goer', value: 'user', selectedRole: selectedRole, onTap: onRoleChanged),
              _RoleTab(label: 'Organizer', value: 'organizer', selectedRole: selectedRole, onTap: onRoleChanged),
            ],
          ),
        ),
        Gap(14.h),
        _InputField(
          controller: emailController,
          icon: Icons.mail_outline_rounded,
          hint: AppLocalizations.of(context)!.email,
          isPassword: false,
        ),
        Gap(14.h),
        _InputField(
          controller: passwordController,
          icon: Icons.lock_outline_rounded,
          hint: 'Enter New Password',
          isPassword: true,
        ),
        Gap(14.h),
        _InputField(
          controller: confirmPasswordController,
          icon: Icons.lock_outline_rounded,
          hint: 'Confirm Password',
          isPassword: true,
        ),
        Gap(18.h),
        _SignUpButton(onPressed: onSignUp, isLoading: isLoading),
        Gap(14.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${AppLocalizations.of(context)!.alreadyHaveAccount} ",
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.signIn,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: AppTheme.primaryLight.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        Gap(14.h),

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

        Gap(14.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(kind: _SocialKind.google, onTap: onGoogleSignUp),
            const Gap(22),
            const _SocialIcon(kind: _SocialKind.facebook),
            const Gap(22),
            const _SocialIcon(kind: _SocialKind.apple),
          ],
        ),

        Gap(16.h),

        GestureDetector(
          onTap: () {},
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

class _RoleTab extends StatelessWidget {
  const _RoleTab({required this.label, required this.value, required this.selectedRole, required this.onTap});
  final String label;
  final String value;
  final String selectedRole;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: selected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.6)) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
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

class _SignUpButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _SignUpButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62.h,
      width: double.infinity,
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
                  AppLocalizations.of(context)!.signUp,
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
    final size = 40.sp;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: _Logo(kind: kind, size: 32.sp)),
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
    // Replace with SVG/PNG assets later if you want exact logos.
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
