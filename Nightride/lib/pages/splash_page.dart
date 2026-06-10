// lib/common/widgets/splash_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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
    final logoSize = AppResponsive.icon(context, 110).clamp(88.0, 120.0);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF000000),
        child: Stack(
          children: [
            // Pink radial glow — top centre
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x33f15991), Color(0x00f15991)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Teal radial glow — bottom right
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x222ec4b6), Color(0x002ec4b6)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Center content: logo + brand name
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with pink glow ring
                  Container(
                    width: logoSize + 16,
                    height: logoSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44f15991),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0x55f15991),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.gap(context, 28).clamp(20.0, 32.0)),
                  // NIGHT RITE brand name
                  Text(
                    'NIGHT RITE',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 36).clamp(28.0, 42.0),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFf15991),
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PLAN THE RIGHT NIGHT',
                    style: GoogleFonts.poppins(
                      fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.5),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2ec4b6),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),

            // Version — bottom
            Positioned(
              bottom: AppResponsive.gap(context, 36).clamp(24.0, 44.0),
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v2.0',
                  style: GoogleFonts.poppins(
                    fontSize: AppResponsive.font(context, 11).clamp(9.0, 12.0),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2ec4b6).withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
