// lib/features/auth/presentation/pages/forgot_pw_page.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/forgotPw/forgot_pw_OTP.dart';

import '../../../../../core/theme/app_theme.dart';

class ForgotPwPage extends StatelessWidget {
  const ForgotPwPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return AuthProcessScaffold(
      title: 'Forgot password',
      subtitle:
          "Enter your email and we'll send you a OTP to reset your password",
      titleTopGap: screenW > 600 ? 16.0 : 88.0,
      reservedBottomGap: 380,
      bottomPanel: const _ForgotBottomPanel(),
      bottomOverlay: Positioned(
        left: 0,
        right: 0,
        bottom: AppResponsive.gap(context, 34).clamp(24, 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Back to ',
              style: TextStyle(
                fontSize: AppResponsive.font(context, 14),
                color: Colors.white.withOpacity(0.65),
                fontWeight: FontWeight.w400,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Sign in',
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 14),
                  color: AppTheme.primaryLight.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotBottomPanel extends StatelessWidget {
  const _ForgotBottomPanel();

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.sizeOf(context).height * 0.63;

    return SizedBox(
      height: panelHeight,
      width: MediaQuery.sizeOf(context).width,
      child: Stack(
        children: [
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
                    children: [_EmailField(), Gap(18), _SendButton()],
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

class _EmailField extends StatefulWidget {
  const _EmailField();

  @override
  State<_EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<_EmailField> {
  late final TextEditingController _controller;

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
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: AppResponsive.font(context, 15),
        ),
        cursorColor: AppTheme.primaryLight,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(
              Icons.mail_outline_rounded,
              color: AppTheme.primaryLight.withOpacity(0.85),
              size: AppResponsive.icon(context, 22),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          hintText: 'Email',
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
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.gap(context, 62).clamp(52, 70),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OtpPage()),
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
          'Send Code',
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
