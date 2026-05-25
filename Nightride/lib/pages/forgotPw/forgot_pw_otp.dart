// lib/features/auth/presentation/pages/otp_page.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/forgotPw/create_new_password_page.dart';
import 'package:pinput/pinput.dart';
import '../../../../../core/theme/app_theme.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  late final TextEditingController _pinController;
  late final FocusNode _pinFocusNode;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _pinFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthProcessScaffold(
      title: 'Enter OTP',
      subtitle: 'Please enter the 6-digit code sent to your email',
      titleTopGap: MediaQuery.sizeOf(context).width > 600 ? 16.0 : 88.0,
      reservedBottomGap: 380,
      bottomPanel: _OtpBottomPanel(
        pinController: _pinController,
        pinFocusNode: _pinFocusNode,
        onVerify: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateNewPasswordPage()),
          );
        },
        onResend: () {},
      ),
    );
  }
}

class _OtpBottomPanel extends StatelessWidget {
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpBottomPanel({
    required this.pinController,
    required this.pinFocusNode,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.sizeOf(context).height * 0.63;

    final borderColor = AppTheme.primary.withOpacity(0.55);
    final focusedBorderColor = AppTheme.primary;

    final pinSize = AppResponsive.icon(context, 56).clamp(44.0, 62.0);
    final defaultPinTheme = PinTheme(
      width: pinSize,
      height: pinSize,
      textStyle: TextStyle(
        fontSize: AppResponsive.font(context, 18),
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.92),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        color: Colors.transparent,
      ),
    );

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
                  child: Column(
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Pinput(
                          length: 5,
                          controller: pinController,
                          focusNode: pinFocusNode,
                          defaultPinTheme: defaultPinTheme,
                          separatorBuilder: (index) => const SizedBox(width: 14),
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                          showCursor: false,
                          keyboardType: TextInputType.number,
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(color: focusedBorderColor, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          submittedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(color: focusedBorderColor, width: 1.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          errorPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(color: Colors.redAccent),
                            ),
                          ),
                          onCompleted: (pin) {},
                        ),
                      ),
                      Gap(AppResponsive.gap(context, 54).clamp(40, 64)),
                      _VerifyButton(onTap: onVerify),
                      Gap(AppResponsive.gap(context, 42).clamp(30, 52)),
                      Text(
                        "Didn't receive code?",
                        style: TextStyle(
                          fontSize: AppResponsive.font(context, 13.5),
                          color: Colors.white.withOpacity(0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Gap(AppResponsive.gap(context, 10).clamp(8, 14)),
                      GestureDetector(
                        onTap: onResend,
                        child: Text(
                          'resend',
                          style: TextStyle(
                            fontSize: AppResponsive.font(context, 14),
                            color: AppTheme.primaryLight.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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

class _VerifyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VerifyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppResponsive.gap(context, 62).clamp(52, 70),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.28),
          foregroundColor: AppTheme.primaryLight.withOpacity(0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          'Verify',
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
