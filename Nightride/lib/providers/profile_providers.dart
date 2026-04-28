import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/data/profile_dummy_data.dart';
import 'package:nightride/domain/profile_models.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/user_profile_service.dart';

final profileProvider = NotifierProvider<ProfileController, ProfileState>(
  ProfileController.new,
);

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Watch auth state directly so this provider rebuilds on every sign-in/out
    ref.watch(authStateProvider);
    // Watch live Firestore data and merge it into state
    final docAsync = ref.watch(userProfileDocProvider);
    final firestoreData = docAsync.asData?.value;

    final ProfileData data = firestoreData != null
        ? UserProfileService.fromMap(firestoreData)
        : kDummyProfile;

    return ProfileState(
      mode: ProfileMode.view,
      data: data,
      draftBio: data.bio,
      draftInterests: List<String>.from(data.interests),
      draftSocialLinks: List<SocialLink>.from(data.socialLinks),
    );
  }

  void enterEdit() {
    final d = state.data;
    state = state.copyWith(
      mode: ProfileMode.edit,
      draftBio: d.bio,
      draftInterests: List<String>.from(d.interests),
      draftSocialLinks: List<SocialLink>.from(d.socialLinks),
    );
  }

  void cancelEdit() => state = state.copyWith(mode: ProfileMode.view);

  Future<void> saveEdit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final instagram = state.draftSocialLinks
        .firstWhere((l) => l.type == SocialType.instagram,
            orElse: () => const SocialLink(type: SocialType.instagram, handle: ''))
        .handle;
    final facebook = state.draftSocialLinks
        .firstWhere((l) => l.type == SocialType.facebook,
            orElse: () => const SocialLink(type: SocialType.facebook, handle: ''))
        .handle;

    if (uid != null) {
      await ref.read(userProfileServiceProvider).updateProfile(
        uid: uid,
        displayName: state.data.displayName,
        username: state.data.username,
        pronouns: state.data.pronouns,
        bio: state.draftBio.trim(),
        interests: _normalizeInterests(state.draftInterests),
        instagram: instagram,
        facebook: facebook,
      );
    }

    // Optimistic local update while Firestore stream propagates
    final updated = state.data.copyWith(
      bio: state.draftBio.trim(),
      interests: _normalizeInterests(state.draftInterests),
      socialLinks: List<SocialLink>.from(state.draftSocialLinks),
    );
    state = state.copyWith(mode: ProfileMode.view, data: updated);
  }

  void setDraftBio(String v) => state = state.copyWith(draftBio: v);

  List<String> get allInterestOptions => kAllInterestOptions;

  bool isInterestSelected(String label) {
    final key = label.trim().toLowerCase();
    return state.draftInterests.any((e) => e.trim().toLowerCase() == key);
  }

  void toggleInterest(String label) {
    final normalized = label.trim();
    if (normalized.isEmpty) return;
    final next = List<String>.from(state.draftInterests);
    final idx = next.indexWhere((e) => e.trim().toLowerCase() == normalized.toLowerCase());
    if (idx >= 0) {
      next.removeAt(idx);
    } else {
      next.add(normalized);
    }
    state = state.copyWith(draftInterests: _normalizeInterests(next));
  }

  void removeInterest(String label) {
    final key = label.trim().toLowerCase();
    state = state.copyWith(
      draftInterests: _normalizeInterests(
        state.draftInterests.where((e) => e.trim().toLowerCase() != key).toList(),
      ),
    );
  }

  List<String> _normalizeInterests(List<String> input) {
    final out = <String>[];
    for (final raw in input) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      if (!out.any((e) => e.toLowerCase() == v.toLowerCase())) out.add(v);
    }
    return out;
  }

  void updateSocialHandle(SocialType type, String handle) {
    final links = List<SocialLink>.from(state.draftSocialLinks);
    final idx = links.indexWhere((l) => l.type == type);
    if (idx == -1) return;
    links[idx] = links[idx].copyWith(handle: handle);
    state = state.copyWith(draftSocialLinks: links);
  }
}
