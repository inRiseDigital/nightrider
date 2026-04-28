// lib/features/auth/presentation/pages/otp_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/auth_process_scaffold.dart';
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
      titleTopGap: 88,
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
    final panelHeight = 0.63.sh;

    final borderColor = AppTheme.primary.withOpacity(0.55);
    final focusedBorderColor = AppTheme.primary;

    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 56.w,
      textStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.92),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
        color: Colors.transparent,
      ),
    );

    return SizedBox(
      height: panelHeight,
      width: 1.sw,
      child: Stack(
        children: [
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
          Positioned(
            top: 54.h,
            left: 22.w,
            right: 22.w,
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Pinput(
                    length: 5,
                    controller: pinController,
                    focusNode: pinFocusNode,
                    defaultPinTheme: defaultPinTheme,
                    separatorBuilder: (index) => SizedBox(width: 14.w),
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    showCursor: false,
                    keyboardType: TextInputType.number,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: focusedBorderColor, width: 2),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                          color: focusedBorderColor,
                          width: 1.6,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
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
                Gap(54.h),
                _VerifyButton(onTap: onVerify),
                Gap(42.h),
                Text(
                  "Didn't receive code?",
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Gap(10.h),
                GestureDetector(
                  onTap: onResend,
                  child: Text(
                    'resend',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.primaryLight.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
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
      height: 62.h,
      width: 1.sw,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.28),
          foregroundColor: AppTheme.primaryLight.withOpacity(0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
        ),
        child: Text(
          'Verify',
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
