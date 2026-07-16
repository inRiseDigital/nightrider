import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

// ── Brand palette (matches chat_screen.dart) ────────────────────────────────
const _kCream = Color(0xFFF3EAD6);
const _kNeonLime = Color(0xFFDFFF2F);
const _kSurface = Color(0xFF151515);
const _kBorderGray = Color(0xFF333333);
const _kMuted = Color(0xFF9EAFA0);

/// Shown in place of the chat input when the signed-in user's email is not yet
/// verified. Polls for verification every 4s (and on app resume) so the chat
/// unlocks automatically once the user clicks the link in their inbox — no app
/// restart. Offers a resend button (60s cooldown) and a "change email" escape.
class ChatVerificationGate extends ConsumerStatefulWidget {
  const ChatVerificationGate({super.key});

  @override
  ConsumerState<ChatVerificationGate> createState() =>
      _ChatVerificationGateState();
}

class _ChatVerificationGateState extends ConsumerState<ChatVerificationGate>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);
  static const _resendCooldown = Duration(seconds: 60);

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User likely just returned from their mail app — re-check immediately.
    if (state == AppLifecycleState.resumed) _poll();
  }

  Future<void> _poll() async {
    // Notifier refreshes the user, force-refreshes the ID-token claim, and flips
    // emailVerifiedProvider to true when done — which removes this gate.
    await ref.read(emailVerifiedProvider.notifier).refresh();
  }

  void _startCooldown() {
    _cooldownRemaining = _resendCooldown.inSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) t.cancel();
      });
    });
  }

  Future<void> _resend() async {
    if (_resending || _cooldownRemaining > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(emailVerifiedProvider.notifier).resend();
      if (mounted) {
        _startCooldown();
        _snack('Verification email sent. Check your inbox.');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase throttles repeated sends — start the cooldown anyway so the
      // button reflects reality, and tell the user.
      if (mounted) {
        _startCooldown();
        _snack(e.code == 'too-many-requests'
            ? 'Too many requests. Please wait a moment and try again.'
            : 'Could not send email: ${e.message ?? e.code}');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _changeEmail() async {
    // Most reliable path for an unverified session: sign out and return to the
    // auth stack so the user can register with the correct address.
    await ref.read(authServiceProvider).signOut();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    final onCooldown = _cooldownRemaining > 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorderGray)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: _kNeonLime, size: 34),
          const SizedBox(height: 12),
          Text(
            'Verify your email to use AI chat',
            textAlign: TextAlign.center,
            style: GoogleFonts.anton(
              fontSize: 18,
              color: _kCream,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a verification link to $email. '
            'Tap it, then come back — this unlocks automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _kMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (onCooldown || _resending) ? null : _resend,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNeonLime,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _kNeonLime.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _resending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.4),
                    )
                  : Text(
                      onCooldown
                          ? 'Resend in ${_cooldownRemaining}s'
                          : 'Resend verification email',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _changeEmail,
            child: Text(
              'Wrong email? Change it',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _kMuted,
                decoration: TextDecoration.underline,
                decorationColor: _kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
