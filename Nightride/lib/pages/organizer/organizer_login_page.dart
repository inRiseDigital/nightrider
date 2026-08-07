import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/forgotPw/forgot_pw.dart';
import 'package:nightride/pages/organizer/organizer_shell_page.dart';
import 'package:nightride/pages/organizer_apply_page.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/organizer_service.dart';

/// Input fill from the organizer app design — one notch lighter than
/// [AppTheme.darkGray] so the fields read as raised against the page black.
const _fieldFill = Color(0xFF17171A);

/// Organizer-side sign-in. Reached from "Do you own a club?" on the main
/// sign-in page; routes an approved organizer into [OrganizerShellPage] and
/// anyone else into the application form or a status message.
class OrganizerLoginPage extends ConsumerStatefulWidget {
  const OrganizerLoginPage({super.key});

  @override
  ConsumerState<OrganizerLoginPage> createState() => _OrganizerLoginPageState();
}

class _OrganizerLoginPageState extends ConsumerState<OrganizerLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _biometricsAvailable = false;
  String _error = '';
  String _notice = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final auth = LocalAuthentication();
      final supported =
          await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      if (mounted) setState(() => _biometricsAvailable = supported);
    } catch (_) {
      // No biometric hardware, or the platform channel is unavailable
      // (desktop/web) — the button simply stays hidden.
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Enter both email and password.';
        _notice = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _notice = '';
    });

    try {
      final cred = await ref.read(authServiceProvider).signInWithEmailPassword(
            email: email,
            password: password,
          );
      await _routeForOrganizer(cred.user);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Biometrics unlock the Firebase session that is already persisted on this
  /// device — it is not a second set of credentials. Without a prior
  /// email/password sign-in there is nothing to unlock.
  Future<void> _handleFaceId() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      setState(() {
        _error = '';
        _notice = 'Sign in with your email once to enable Face ID on this device.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _notice = '';
    });

    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Unlock your Night Ride organizer account',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok) await _routeForOrganizer(user);
    } catch (e) {
      if (mounted) setState(() => _error = 'Biometric sign-in failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _routeForOrganizer(User? user) async {
    if (user == null) return;

    final service = ref.read(organizerServiceProvider);
    final access = await service.accessFor(user.uid);
    if (!mounted) return;

    switch (access) {
      case OrganizerAccess.approved:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrganizerShellPage()),
        );

      case OrganizerAccess.pending:
        setState(() {
          _error = '';
          _notice = 'Your application is under review. '
              "We'll email you as soon as it's approved.";
        });

      case OrganizerAccess.rejected:
        final reason = await service.rejectionReasonFor(user.uid);
        if (!mounted) return;
        setState(() {
          _notice = '';
          _error = reason.isEmpty
              ? 'Your organizer application was not approved.'
              : 'Your organizer application was not approved: $reason';
        });

      case OrganizerAccess.none:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OrganizerApplyPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── NIGHT/RIDE wordmark ───────────────────────────────
                  Center(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'NIGHT',
                          style: GoogleFonts.anton(color: AppTheme.neonLime),
                        ),
                        TextSpan(
                          text: 'RIDE',
                          style: GoogleFonts.anton(color: AppTheme.textPrimary),
                        ),
                      ]),
                      style: GoogleFonts.anton(fontSize: 26, letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── ORGANIZER LOGIN label ─────────────────────────────
                  Center(
                    child: Text(
                      l.organizerLogin.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 1.65,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _OrganizerField(
                    label: l.email,
                    controller: _emailController,
                    hint: 'you@venue.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),

                  _OrganizerField(
                    label: l.password,
                    controller: _passwordController,
                    hint: '••••••••',
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _handleLogin(),
                  ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Banner(
                      message: _error,
                      color: const Color(0xFFF87171),
                      tint: const Color(0xFFEF4444),
                    ),
                  ],
                  if (_notice.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Banner(
                      message: _notice,
                      color: AppTheme.teal,
                      tint: AppTheme.teal,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Log In ────────────────────────────────────────────
                  _PrimaryButton(
                    label: l.signIn,
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _handleLogin,
                  ),

                  if (_biometricsAvailable) ...[
                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: l.logInWithFaceId,
                      onTap: _isLoading ? null : _handleFaceId,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Forgot password ───────────────────────────────────
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPwPage()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l.forgotPassword,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Apply link, for organizers without an account yet ──
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OrganizerApplyPage()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: '${l.ownAClub} ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            TextSpan(
                              text: l.applyHere.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.neonLime,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ]),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal design widgets ──────────────────────────────────────────────────

/// Labelled dark field: 12px muted label above a #17171A input that switches
/// its border to neon lime on focus.
class _OrganizerField extends StatelessWidget {
  const _OrganizerField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          textInputAction:
              onSubmitted == null ? TextInputAction.next : TextInputAction.done,
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 15, color: AppTheme.textHint),
            filled: true,
            fillColor: _fieldFill,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: _border(AppTheme.borderGray),
            enabledBorder: _border(AppTheme.borderGray),
            focusedBorder: _border(AppTheme.neonLime),
          ),
        ),
      ],
    );
  }
}

/// Neon-lime primary action.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: onTap == null
              ? AppTheme.neonLime.withValues(alpha: 0.5)
              : AppTheme.neonLime,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  color: AppTheme.background,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.background,
                ),
              ),
      ),
    );
  }
}

/// Dark bordered action with the teal glyph from the design.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppTheme.teal, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tinted inline message — the design's error box, reused for status notices.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    required this.tint,
  });

  final String message;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12, color: color, height: 1.4),
      ),
    );
  }
}
