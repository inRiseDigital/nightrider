import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    clientId: '218660887469-uqtutg9a7qd7dqu6jva7qpbk8ujm358n.apps.googleusercontent.com',
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
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
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
