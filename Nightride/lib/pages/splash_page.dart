// lib/pages/splash_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/pages/app_shell_page.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/auth/sign_up_page.dart';
import 'package:nightride/pages/onboard_questionnaire_page.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/user_profile_service.dart';

// ── Brush stroke painter for the GET STARTED button ───────────────────────────
class _BrushMark {
  final double topFrac, height, extend;
  const _BrushMark(this.topFrac, this.height, this.extend);
}

class _BrushStrokePainter extends CustomPainter {
  final Color color;
  const _BrushStrokePainter(this.color);

  static const _marks = <_BrushMark>[
    _BrushMark(0.08, 9, 14),
    _BrushMark(0.28, 6, 18),
    _BrushMark(0.50, 11, 12),
    _BrushMark(0.70, 7, 16),
    _BrushMark(0.86, 6, 10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Main button body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(5),
      ),
      p,
    );

    // Left brush-stroke extensions
    for (final m in _marks) {
      final y = size.height * m.topFrac;
      final path = Path()
        ..moveTo(2, y)
        ..lineTo(-m.extend, y + m.height * 0.15)
        ..lineTo(-m.extend - 3, y + m.height * 0.45)
        ..lineTo(-m.extend, y + m.height * 0.80)
        ..lineTo(2, y + m.height)
        ..close();
      canvas.drawPath(path, p);
    }

    // Right brush-stroke extensions (mirrored)
    for (final m in _marks) {
      final y = size.height * m.topFrac;
      final w = size.width;
      final path = Path()
        ..moveTo(w - 2, y)
        ..lineTo(w + m.extend, y + m.height * 0.15)
        ..lineTo(w + m.extend + 3, y + m.height * 0.45)
        ..lineTo(w + m.extend, y + m.height * 0.80)
        ..lineTo(w - 2, y + m.height)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushStrokePainter old) => old.color != color;
}

// ── Main widget ────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // True when a returning user is detected — skip decorative splash
  bool _isReturningUser = false;

  @override
  void initState() {
    super.initState();

    // If a user is already signed in, skip the splash immediately
    final existingUser = FirebaseAuth.instance.currentUser;
    if (existingUser != null) {
      _isReturningUser = true;
      _navigateReturningUser(existingUser);
    } else {
      _navigateAfterDelay();
    }
  }

  // Slide-right page transition → destination
  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 380),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _goToSignUp() => _goTo(const SignUpPage());
  void _goToSignIn() => _goTo(const SignInPage());

  // Fast path for returning users — no delay, no decorative splash
  Future<void> _navigateReturningUser(User user) async {
    Widget destination;
    try {
      final svc = ref.read(userProfileServiceProvider);
      await svc.createIfAbsent(user).timeout(const Duration(seconds: 5));
      await svc.cleanupDummyDataIfNeeded(user.uid).timeout(const Duration(seconds: 5));
      final isOrganizer = await svc.isApprovedOrganizer(user.uid).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (isOrganizer) {
        destination = const OrganizerShellPage();
      } else {
        final onboardingDone =
            await svc.hasCompletedOnboarding(user.uid).timeout(const Duration(seconds: 5));
        destination = onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage();
      }
    } catch (_) {
      destination = AppShellPage();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  // Auto-advances only if a user turns out to already be authenticated
  // (missed by the synchronous check in initState). Logged-out users stay
  // on this screen indefinitely — it's a welcome screen, not a timed
  // splash, so GET STARTED / LOG IN are the only way forward for them.
  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = await ref.read(authStateProvider.future).timeout(
      const Duration(seconds: 3),
      onTimeout: () => FirebaseAuth.instance.currentUser,
    );

    if (!mounted || user == null) return;

    Widget destination;
    if (user != null) {
      try {
        final svc = ref.read(userProfileServiceProvider);
        await svc.createIfAbsent(user).timeout(const Duration(seconds: 5));
        await svc.cleanupDummyDataIfNeeded(user.uid).timeout(const Duration(seconds: 5));
        final isOrganizer = await svc.isApprovedOrganizer(user.uid).timeout(const Duration(seconds: 5));
        if (!mounted) return;
        if (isOrganizer) {
          destination = const OrganizerShellPage();
        } else {
          final onboardingDone =
              await svc.hasCompletedOnboarding(user.uid).timeout(const Duration(seconds: 5));
          destination = onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage();
        }
      } catch (_) {
        destination = AppShellPage();
      }
    } catch (_) {
      destination = AppShellPage();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Returning users skip the decorative splash — just show black while navigating
    if (_isReturningUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF070707),
        body: SizedBox.shrink(),
      );
    }

    const Color cream     = Color(0xFFF5F0E8);
    const Color pureBlack = Color(0xFF070707);
    const Color yellow    = Color(0xFFDFFF2F);
    final Color accent    = Theme.of(context).colorScheme.primary;

    final double titleFontSize  = AppResponsive.font(context, 104).clamp(80.0, 130.0);
    final double mascotSize     = AppResponsive.icon(context, 300).clamp(220.0, 340.0);
    final double taglineFontSize= AppResponsive.font(context, 11).clamp(9.0, 13.0);
    final double buttonFontSize = AppResponsive.font(context, 15).clamp(13.0, 17.0);

    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Ambient glow ───────────────────────────────────────────────
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.10),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main column ────────────────────────────────────────────────
              Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Image.asset(
                    'assets/images/vinyl_logo.png',
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: AppResponsive.gap(context, 20).clamp(12.0, 28.0)),

                  // NIGHT / RITE headline
                  Transform.rotate(
                    angle: -0.12,
                    child: Column(
                      children: [
                        Text(
                          'NIGHT',
                          style: GoogleFonts.anton(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w400,
                            color: cream,
                            height: 0.92,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          'RITE',
                          style: GoogleFonts.anton(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w400,
                            color: yellow,
                            height: 0.92,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppResponsive.gap(context, 16).clamp(10.0, 24.0)),

                  // Tagline
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'FIND YOUR VIBE.\n'),
                        const TextSpan(text: 'LIVE THE NIGHT.\n'),
                        const TextSpan(text: 'MAKE IT '),
                        TextSpan(
                          text: 'RIDE.',
                          style: TextStyle(color: accent),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: taglineFontSize,
                      fontWeight: FontWeight.w700,
                      color: cream,
                      letterSpacing: 2.0,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Brush-stroke GET STARTED button ────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.gap(context, 40).clamp(28.0, 64.0),
                    ),
                    child: GestureDetector(
                      onTap: _goToSignUp,
                      child: SizedBox(
                        height: 56,
                        child: CustomPaint(
                          painter: _BrushStrokePainter(accent),
                          child: Center(
                            child: Text(
                              'GET STARTED',
                              style: GoogleFonts.anton(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w400,
                                color: pureBlack,
                                letterSpacing: 3.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.gap(context, 18).clamp(12.0, 24.0)),

                  // LOG IN text link
                  GestureDetector(
                    onTap: _goToSignIn,
                    child: Text(
                      'LOG IN',
                      style: GoogleFonts.poppins(
                        fontSize: AppResponsive.font(context, 12).clamp(10.0, 14.0),
                        fontWeight: FontWeight.w500,
                        color: cream.withValues(alpha: 0.55),
                        letterSpacing: 2.0,
                        decoration: TextDecoration.underline,
                        decorationColor: cream.withValues(alpha: 0.35),
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.gap(context, 28).clamp(20.0, 44.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
