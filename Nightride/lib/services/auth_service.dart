import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nightride/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for GoogleSignIn instance
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // serverClientId only needed on iOS/web to get an ID token for a backend.
    // On Android it triggers web-client OAuth validation, causing DEVELOPER_ERROR
    // (code 10) on real devices. Firebase Auth works with accessToken alone.
    serverClientId: defaultTargetPlatform == TargetPlatform.android
        ? null
        : '218660887469-uqtutg9a7qd7dqu6jva7qpbk8ujm358n.apps.googleusercontent.com',
  );
});

/// Stream provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(userProfileServiceProvider),
  );
});

/// Whether the signed-in user's email is verified.
///
/// Seeded from the current user (Google sign-ins are already verified, so the
/// chat gate never shows for them). A manual [User.reload] does NOT fire
/// [FirebaseAuth.authStateChanges], so this notifier — not [authStateProvider] —
/// is what drives the reactive chat gate → input swap once the user verifies.
final emailVerifiedProvider =
    NotifierProvider<EmailVerificationNotifier, bool>(EmailVerificationNotifier.new);

class EmailVerificationNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Re-seed whenever auth state changes (login/logout).
    final user = ref.watch(authStateProvider).asData?.value;
    return user?.emailVerified ?? false;
  }

  /// Reloads the user from the server, refreshes the ID-token claim if now
  /// verified, and updates state. Returns the fresh verified flag.
  Future<bool> refresh() async {
    final verified = await ref.read(authServiceProvider).reloadAndCheckVerified();
    state = verified;
    return verified;
  }

  /// (Re)sends the verification email.
  Future<void> resend() => ref.read(authServiceProvider).sendVerificationEmail();

  /// Forces the gate back on — e.g. the backend rejected a message with
  /// EMAIL_NOT_VERIFIED while the client still believed it was verified.
  void markUnverified() => state = false;
}

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserProfileService _profileService;

  AuthService(this._auth, this._googleSignIn, this._profileService);

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) await _profileService.createIfAbsent(cred.user!);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        await _profileService.createIfAbsent(cred.user!, role: 'user');
        await _flushOnboardingAnswers(cred.user!.uid);
        // Fire the verification email immediately. Best-effort: a send failure
        // (e.g. too-many-requests) must never block account creation — the user
        // can resend from the chat gate.
        try {
          await cred.user!.sendEmailVerification();
        } catch (_) {}
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reloads the current user from the server and returns the fresh
  /// [User.emailVerified]. If it flipped to true, force-refreshes the ID token
  /// so the `email_verified` claim that the backend and Firestore rules read is
  /// no longer stale (it otherwise lags by up to an hour).
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    final verified = refreshed?.emailVerified ?? false;
    if (verified) {
      await refreshed!.getIdToken(true);
    }
    return verified;
  }

  /// (Re)sends the verification email to the current user.
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// After sign-up, flush onboarding answers that were stored in SharedPreferences.
  Future<void> _flushOnboardingAnswers(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final ageRange = prefs.getString('ob_ageRange') ?? '';
    final genres   = (prefs.getString('ob_genres')   ?? '').split(',').where((s) => s.isNotEmpty).toList();
    final vibes    = (prefs.getString('ob_vibes')    ?? '').split(',').where((s) => s.isNotEmpty).toList();
    final features = (prefs.getString('ob_features') ?? '').split(',').where((s) => s.isNotEmpty).toList();
    final goOutTime= prefs.getString('ob_goOutTime') ?? '';
    final budget   = prefs.getString('ob_budget')    ?? '';

    if (ageRange.isEmpty && genres.isEmpty) return; // nothing to flush

    await UserProfileService(FirebaseFirestore.instance).saveOnboardingAnswers(
      uid: uid,
      ageRange: ageRange,
      genres: genres,
      vibes: vibes,
      features: features,
      goOutTime: goOutTime,
      budget: budget,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _profileService.createIfAbsent(cred.user!);
        // Save onboarding answers for first-time Google sign-in users
        if (cred.additionalUserInfo?.isNewUser == true) {
          await _flushOnboardingAnswers(cred.user!.uid);
        }
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
