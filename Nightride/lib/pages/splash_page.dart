// lib/pages/splash_page.dart
import 'dart:math' as math;

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

// ── Sparkle config ─────────────────────────────────────────────────────────────
class _SparkDef {
  final double leftFrac, topFrac, size;
  final Color color;
  final double delay; // fraction of animation cycle to offset
  const _SparkDef(this.leftFrac, this.topFrac, this.size, this.color, this.delay);
}

const _kSparks = <_SparkDef>[
  _SparkDef(0.10, 0.11, 18, Color(0xFFFF3D73), 0.0),
  _SparkDef(0.82, 0.09, 13, Color(0xFFDFFF2F), 0.3),
  _SparkDef(0.88, 0.36, 20, Color(0xFF62D6C8), 0.5),
  _SparkDef(0.05, 0.38, 14, Color(0xFFFAFAFA), 0.7),
  _SparkDef(0.78, 0.60, 12, Color(0xFFFF3D73), 0.2),
  _SparkDef(0.13, 0.62, 17, Color(0xFFDFFF2F), 0.8),
  _SparkDef(0.50, 0.07, 11, Color(0xFF62D6C8), 0.4),
  _SparkDef(0.92, 0.72, 15, Color(0xFFFAFAFA), 0.6),
];

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

// ── Sparkle widget ─────────────────────────────────────────────────────────────
class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;
  final Animation<double> anim;

  const _Sparkle({required this.size, required this.color, required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = (math.sin(anim.value * math.pi)).abs();
        return Opacity(
          opacity: 0.35 + v * 0.65,
          child: Transform.scale(
            scale: 0.6 + v * 0.55,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: color,
              size: size,
            ),
          ),
        );
      },
    );
  }
}

// ── Main widget ────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _sparkCtrl;
  late final AnimationController _arrowCtrl;

  late final Animation<double> _floatAnim;
  late final Animation<double> _arrowAnim;

  // True when a returning user is detected — skip decorative splash
  bool _isReturningUser = false;

  @override
  void initState() {
    super.initState();

    // Init controllers without starting them yet
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _arrowAnim = Tween<double>(begin: 0.0, end: 14.0).animate(
      CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut),
    );

    // If a user is already signed in, skip the splash immediately
    final existingUser = FirebaseAuth.instance.currentUser;
    if (existingUser != null) {
      _isReturningUser = true;
      _navigateReturningUser(existingUser);
    } else {
      // New / logged-out user — show full splash with animations
      _floatCtrl.repeat(reverse: true);
      _sparkCtrl.repeat();
      _arrowCtrl.repeat(reverse: true);
      _navigateAfterDelay();
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _sparkCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  // Slide-right page transition → SignIn
  void _goToSignIn() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignInPage(),
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

  // Fast path for returning users — no delay, no decorative splash
  Future<void> _navigateReturningUser(User user) async {
    Widget destination;
    try {
      final svc = ref.read(userProfileServiceProvider);
      await svc.createIfAbsent(user).timeout(const Duration(seconds: 5));
      await svc.cleanupDummyDataIfNeeded(user.uid).timeout(const Duration(seconds: 5));
      final role = await svc.getUserRole(user.uid).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (role == 'organizer') {
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

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

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
          final onboardingDone =
              await svc.hasCompletedOnboarding(user.uid).timeout(const Duration(seconds: 5));
          destination = onboardingDone ? AppShellPage() : const OnboardQuestionnaireTemplatePage();
        }
      } catch (_) {
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
    // Returning users skip the decorative splash — just show black while navigating
    if (_isReturningUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF070707),
        body: SizedBox.shrink(),
      );
    }

    const Color cream     = Color(0xFFF5F0E8);
    const Color pureBlack = Color(0xFF070707);
    final Color accent    = Theme.of(context).colorScheme.primary;

    final double titleFontSize  = AppResponsive.font(context, 88).clamp(68.0, 110.0);
    final double mascotSize     = AppResponsive.icon(context, 160).clamp(120.0, 190.0);
    final double taglineFontSize= AppResponsive.font(context, 11).clamp(9.0, 13.0);
    final double buttonFontSize = AppResponsive.font(context, 15).clamp(13.0, 17.0);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

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

              // ── Sparkles ───────────────────────────────────────────────────
              for (final spark in _kSparks)
                Positioned(
                  left: screenW * spark.leftFrac,
                  top: screenH * spark.topFrac,
                  child: _Sparkle(
                    size: spark.size,
                    color: spark.color,
                    anim: Tween<double>(
                      begin: spark.delay,
                      end: spark.delay + 1.0,
                    ).animate(_sparkCtrl),
                  ),
                ),

              // ── Main column ────────────────────────────────────────────────
              Column(
                children: [
                  const Spacer(flex: 2),

                  // NIGHT / RIDE headline
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
                    'RIDE',
                    style: GoogleFonts.anton(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w400,
                      color: cream,
                      height: 0.92,
                      letterSpacing: 2.0,
                    ),
                  ),

                  SizedBox(height: AppResponsive.gap(context, 20).clamp(12.0, 28.0)),

                  // Floating mascot
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -1,  0,  0, 0, 255,
                         0, -1,  0, 0, 255,
                         0,  0, -1, 0, 255,
                         0,  0,  0, 1,   0,
                      ]),
                      child: Image.asset(
                        'assets/images/vinyl_mascot.png',
                        width: mascotSize,
                        height: mascotSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: AppResponsive.gap(context, 16).clamp(10.0, 24.0)),

                  // Tagline
                  Text(
                    'FIND. PLAN. RIDE. REPEAT.',
                    style: GoogleFonts.poppins(
                      fontSize: taglineFontSize,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 2.8,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Brush-stroke GET STARTED button ────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.gap(context, 40).clamp(28.0, 64.0),
                    ),
                    child: GestureDetector(
                      onTap: _goToSignIn,
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

                  SizedBox(height: AppResponsive.gap(context, 12).clamp(8.0, 16.0)),

                  // Animated swipe-right indicator
                  AnimatedBuilder(
                    animation: _arrowAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(_arrowAnim.value, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chevron_right_rounded,
                              color: cream.withValues(alpha: 0.18), size: 18),
                          Icon(Icons.chevron_right_rounded,
                              color: cream.withValues(alpha: 0.34), size: 18),
                          Icon(Icons.chevron_right_rounded,
                              color: cream.withValues(alpha: 0.55), size: 18),
                        ],
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
