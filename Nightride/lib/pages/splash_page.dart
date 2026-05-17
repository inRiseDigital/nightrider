// lib/common/widgets/splash_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/user_profile_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Wait for Firebase to restore the session, with a 3s safety timeout
    final user = await ref.read(authStateProvider.future).timeout(
      const Duration(seconds: 3),
      onTimeout: () => FirebaseAuth.instance.currentUser,
    );

    if (!mounted) return;

    Widget destination;
    if (user != null) {
      try {
        final svc = ref.read(userProfileServiceProvider);
        await svc.createIfAbsent(user).timeout(const Duration(seconds: 5));
        await svc.cleanupDummyDataIfNeeded(user.uid).timeout(const Duration(seconds: 5));
        final role = await svc.getUserRole(user.uid).timeout(const Duration(seconds: 5));
        if (!mounted) return;
        if (role == 'organizer') {
          destination = const OrganizerShellPage();
        } else {
          final onboardingDone = await svc.hasCompletedOnboarding(user.uid).timeout(const Duration(seconds: 5));
          destination = onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage();
        }
      } catch (_) {
        // Network/Firestore unavailable — proceed to the main shell anyway.
        destination = AppShellPage();
      }
    } else {
      destination = const SignInPage();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0F2E), Color(0xFF12091F), Color(0xFF090411)],
          ),
        ),
        child: Stack(
          children: [
            /// Center Logo
            Center(
              child: Container(
                width: 96.sp,
                height: 96.sp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            /// Bottom Text
            Positioned(
              bottom: 48.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'NightRide',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 0.6,
                    ),
                  ),
                  6.verticalSpace,
                  Text(
                    'v2.0',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D28D9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
