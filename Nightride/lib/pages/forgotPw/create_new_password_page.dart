// lib/features/auth/presentation/pages/create_new_password_page.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import '../../../../../core/theme/app_theme.dart';

class CreateNewPasswordPage extends StatelessWidget {
  const CreateNewPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return AuthProcessScaffold(
      title: "Create New Password",
      subtitle: "Set a strong password that you haven't used before.",
      titleTopGap: screenW > 600 ? 16.0 : 88.0,
      reservedBottomGap: 380,
      bottomPanel: const _NewPasswordBottomPanel(),
    );
  }
}

class _NewPasswordBottomPanel extends StatelessWidget {
  const _NewPasswordBottomPanel();

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.sizeOf(context).height * 0.63;

    return SizedBox(
      height: panelHeight,
      width: MediaQuery.sizeOf(context).width,
      child: Stack(
        children: [
          // Panel body
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0816),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(48),
                  topRight: Radius.circular(48),
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
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48),
                    topRight: Radius.circular(48),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x17B45BFF), // AppTheme.primary ~9% opacity
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.25, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Thin glowing top stroke
          Positioned(
            top: 0,
            left: 22,
            right: 22,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
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
            top: 20,
            left: 0,
            right: 0,
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
                    horizontal: MediaQuery.sizeOf(context).width > 600 ? 16.0 : 22.0.clamp(0.0, 32.0),
                  ),
                  child: const Column(
                    children: [
                      _PasswordField(hint: 'Password'),
                      Gap(18),
                      _PasswordField(hint: 'Confirm Password'),
                      Gap(34),
                      _ResetPasswordButton(),
                    ],
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

class _PasswordField extends StatefulWidget {
  final String hint;

  const _PasswordField({required this.hint});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppResponsive.gap(context, 64).clamp(54, 72),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
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
        controller: _controller,
        obscureText: _obscure,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: AppResponsive.font(context, 15),
        ),
        cursorColor: AppTheme.primaryLight,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryLight.withOpacity(0.85),
              size: AppResponsive.icon(context, 22),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppTheme.primaryLight.withOpacity(0.45),
            fontSize: AppResponsive.font(context, 15),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppResponsive.gap(context, 18).clamp(14, 22),
            horizontal: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(
              color: AppTheme.primary.withOpacity(0.55),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: AppResponsive.icon(context, 20),
                color: AppTheme.primaryLight.withOpacity(0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordButton extends StatelessWidget {
  const _ResetPasswordButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.gap(context, 62).clamp(52, 70),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Go back to Sign In page and clear the navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.28),
          foregroundColor: AppTheme.primaryLight.withOpacity(0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          'Reset Password',
          style: TextStyle(
            fontSize: AppResponsive.font(context, 18),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
