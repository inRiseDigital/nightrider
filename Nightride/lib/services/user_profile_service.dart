import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/domain/profile_models.dart';
import 'package:nightride/services/auth_service.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(FirebaseFirestore.instance);
});

/// Streams the raw Firestore document for the current user.
/// Watches authStateProvider so it rebuilds when the user signs in/out.
final userProfileDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.data());
});

/// The current user's avatar URL, or null when they have none.
///
/// This used to stream a base64 blob out of an `avatars` collection, which is
/// why profile photos were capped at 300 KB: the encoded string had to fit
/// inside a Firestore document alongside everything else. Avatars are Storage
/// objects now, and the document holds only the public URL.
final avatarUrlProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) {
    final url = s.data()?['avatarUrl'];
    return (url is String && url.isNotEmpty) ? url : null;
  });
});

class UserProfileService {
  UserProfileService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  /// Whether this account is an approved organizer.
  ///
  /// `role` is gone. It carried three values in practice (user, organizer,
  /// admin) across three writers that never agreed, and none of them was the
  /// field the security rules actually read. Organizer access is
  /// `organizerStatus == 'approved'` and nothing else; admin is `isAdmin`.
  Future<bool> isApprovedOrganizer(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.data()?['organizerStatus'] == 'approved';
  }

  /// Create a profile document if it doesn't already exist.
  Future<void> createIfAbsent(User firebaseUser) async {
    final ref = _col.doc(firebaseUser.uid);
    final snap = await ref.get(const GetOptions(source: Source.server));
    if (snap.exists) return;

    final name = firebaseUser.displayName ?? '';
    final email = firebaseUser.email ?? '';
    final photo = firebaseUser.photoURL ?? '';
    final username = email.isNotEmpty
        ? email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        : 'user${firebaseUser.uid.substring(0, 6)}';

    await ref.set({
      'uid': firebaseUser.uid,
      'email': email,
      'displayName': name,
      'username': username,
      'pronouns': '',
      'countryCode': '',
      'avatarUrl': photo,
      'bio': '',
      'city': '',
      'ageRange': '',
      'interests': <String>[],
      'genres': <String>[],
      'vibes': <String>[],
      'features': <String>[],
      'goOutTime': '',
      'budget': '',
      'instagram': '',
      'facebook': '',
      'phone': '',
      'partiesAttended': 0,
      'friendsCount': 0,
      'streakDays': 0,
      'rank': 0,
      // Admin-owned fields. The create rule requires both to be present and at
      // their starting values, and every later self-update is denied if it
      // touches either — only the Admin SDK sets isAdmin, and only an admin
      // moves organizerStatus.
      'isAdmin': false,
      'organizerStatus': 'none',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clears dummy placeholder values that may have been accidentally saved to
  /// Firestore. Checks the actual values before writing — safe to call every launch.
  static const _dummyBio = 'Shrining in chaos ✨ Indie game developer • Vinyl junkie 🎶';
  static const _dummyAvatarUrl = 'assets/images/business-man-smiling-free-photo.jpg';

  Future<void> cleanupDummyDataIfNeeded(String uid) async {
    try {
      final snap = await _col.doc(uid).get(const GetOptions(source: Source.server));
      if (!snap.exists) return;

      final d = snap.data()!;
      final updates = <String, dynamic>{};
      if ((d['bio'] as String? ?? '') == _dummyBio) updates['bio'] = '';
      if ((d['pronouns'] as String? ?? '') == 'she/her') updates['pronouns'] = '';
      if ((d['avatarUrl'] as String? ?? '') == _dummyAvatarUrl) updates['avatarUrl'] = '';

      if (updates.isNotEmpty) {
        await _col.doc(uid).set(updates, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  /// Returns true if the user has completed onboarding (ageRange is non-empty).
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final snap = await _col.doc(uid).get(const GetOptions(source: Source.server));
      if (!snap.exists) return false;
      final ageRange = snap.data()?['ageRange'] as String? ?? '';
      return ageRange.isNotEmpty;
    } catch (_) {
      // On Firestore error, send to onboarding rather than silently skipping it.
      return false;
    }
  }

  /// Save all onboarding answers at once.
  Future<void> saveOnboardingAnswers({
    required String uid,
    required String ageRange,
    required List<String> genres,
    required List<String> vibes,
    required List<String> features,
    required String goOutTime,
    required String budget,
  }) async {
    await _col.doc(uid).set({
      'ageRange': ageRange,
      'genres': genres,
      'vibes': vibes,
      'features': features,
      'goOutTime': goOutTime,
      'budget': budget,
      // also write interests = genres so profile page has something to show
      'interests': genres,
    }, SetOptions(merge: true));
  }

  /// Upload a profile photo to `avatars/{uid}.jpg` and record its URL.
  ///
  /// The 2 MB ceiling is the Storage rule's, checked here too so the user gets
  /// a real message rather than a permission error. The old 300 KB limit was an
  /// artefact of base64-encoding the image into a Firestore document.
  Future<void> saveAvatar(String uid, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw Exception('Image is too large. Please choose one under 2 MB.');
    }

    final object = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await object.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await object.getDownloadURL();

    await _col.doc(uid).set({
      'avatarUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _sanitizeText(String value, {int maxLength = 200}) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML tags
        .replaceAll(RegExp(r'[^\x20-\x7E -￿]'), '') // strip control chars
        .trim()
        .substring(0, value.trim().length.clamp(0, maxLength));
  }

  /// Update editable profile fields.
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    required String pronouns,
    required String bio,
    required List<String> interests,
    required String instagram,
    required String facebook,
    String? phone,
    String? city,
  }) async {
    await _col.doc(uid).set({
      'displayName': _sanitizeText(displayName, maxLength: 64),
      'username': _sanitizeText(username, maxLength: 32),
      'pronouns': _sanitizeText(pronouns, maxLength: 32),
      'bio': _sanitizeText(bio, maxLength: 300),
      'interests': interests.map((i) => _sanitizeText(i, maxLength: 32)).toList(),
      'instagram': _sanitizeText(instagram, maxLength: 64),
      'facebook': _sanitizeText(facebook, maxLength: 64),
      if (phone != null) 'phone': _sanitizeText(phone, maxLength: 20),
      if (city != null) 'city': _sanitizeText(city, maxLength: 64),
    }, SetOptions(merge: true));
  }

  /// Convert a Firestore map to ProfileData.
  static ProfileData fromMap(Map<String, dynamic> d) {
    final createdAt = d['createdAt'];
    String joinedText = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      joinedText = 'Joined ${months[dt.month]} ${dt.year}';
    }

    return ProfileData(
      displayName: d['displayName'] as String? ?? '',
      username: d['username'] as String? ?? '',
      pronouns: d['pronouns'] as String? ?? '',
      countryCode: d['countryCode'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      networkCount: (d['friendsCount'] as num? ?? 0).toInt(),
      interestedCount: (d['partiesAttended'] as num? ?? 0).toInt(),
      bio: d['bio'] as String? ?? '',
      interests: List<String>.from(d['interests'] as List? ?? []),
      socialLinks: [
        SocialLink(type: SocialType.instagram, handle: d['instagram'] as String? ?? ''),
        SocialLink(type: SocialType.facebook,  handle: d['facebook']  as String? ?? ''),
      ],
      joinedText: joinedText,
      partiesAttended: (d['partiesAttended'] as num? ?? 0).toInt(),
      friendsCount: (d['friendsCount'] as num? ?? 0).toInt(),
      streakDays: (d['streakDays'] as num? ?? 0).toInt(),
      rank: (d['rank'] as num? ?? 0).toInt(),
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      city: d['city'] as String? ?? '',
      ageRange: d['ageRange'] as String? ?? '',
      genres: List<String>.from(d['genres'] as List? ?? []),
      vibes: List<String>.from(d['vibes'] as List? ?? []),
      features: List<String>.from(d['features'] as List? ?? []),
      goOutTime: d['goOutTime'] as String? ?? '',
      budget: d['budget'] as String? ?? '',
      role: d['role'] as String? ?? 'user',
    );
  }

  /// Awards daily login points. Idempotent — safe to call on every app open.
  Future<void> awardDailyPoints(String uid) async {
    try {
      final docRef = _col.doc(uid);
      final snap = await docRef.get(const GetOptions(source: Source.server));
      if (!snap.exists) return;

      final d = snap.data()!;
      final lastActive = d['lastActiveDate'] as String? ?? '';
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (lastActive == today) return; // already awarded today

      final isFirstTime = (d['rank'] as int? ?? 0) == 0 && lastActive.isEmpty;
      final pts = isFirstTime ? 50 : 10;

      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      final streakContinues = lastActive == yesterday;

      await docRef.set({
        'rank': FieldValue.increment(pts),
        'lastActiveDate': today,
        'streakDays': streakContinues ? FieldValue.increment(1) : 1,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
