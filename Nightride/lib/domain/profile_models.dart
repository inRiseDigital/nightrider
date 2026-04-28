import 'package:flutter/foundation.dart';

@immutable
class SocialLink {
  const SocialLink({required this.type, required this.handle});

  final SocialType type;
  final String handle;

  SocialLink copyWith({SocialType? type, String? handle}) {
    return SocialLink(type: type ?? this.type, handle: handle ?? this.handle);
  }
}

enum SocialType { instagram, facebook }

@immutable
class ProfileData {
  const ProfileData({
    required this.displayName,
    required this.username,
    required this.pronouns,
    required this.countryCode,
    required this.avatarUrl,
    required this.networkCount,
    required this.interestedCount,
    required this.bio,
    required this.interests,
    required this.socialLinks,
    required this.joinedText,
    this.partiesAttended = 0,
    this.friendsCount = 0,
    this.streakDays = 0,
    this.rank = 0,
    this.phone = '',
    this.email = '',
    this.city = '',
    this.ageRange = '',
    this.genres = const [],
    this.vibes = const [],
    this.features = const [],
    this.goOutTime = '',
    this.budget = '',
    this.role = 'user',
  });

  final String displayName;
  final String username;
  final String pronouns;
  final String countryCode;
  final String avatarUrl;
  final int networkCount;
  final int interestedCount;
  final String bio;
  final List<String> interests;
  final List<SocialLink> socialLinks;
  final String joinedText;
  final int partiesAttended;
  final int friendsCount;
  final int streakDays;
  final int rank;
  final String phone;
  final String email;
  final String city;
  final String ageRange;
  final List<String> genres;
  final List<String> vibes;
  final List<String> features;
  final String goOutTime;
  final String budget;
  final String role;

  ProfileData copyWith({
    String? displayName,
    String? username,
    String? pronouns,
    String? countryCode,
    String? avatarUrl,
    int? networkCount,
    int? interestedCount,
    String? bio,
    List<String>? interests,
    List<SocialLink>? socialLinks,
    String? joinedText,
    int? partiesAttended,
    int? friendsCount,
    int? streakDays,
    int? rank,
    String? phone,
    String? email,
    String? city,
    String? ageRange,
    List<String>? genres,
    List<String>? vibes,
    List<String>? features,
    String? goOutTime,
    String? budget,
    String? role,
  }) {
    return ProfileData(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      pronouns: pronouns ?? this.pronouns,
      countryCode: countryCode ?? this.countryCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      networkCount: networkCount ?? this.networkCount,
      interestedCount: interestedCount ?? this.interestedCount,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      socialLinks: socialLinks ?? this.socialLinks,
      joinedText: joinedText ?? this.joinedText,
      partiesAttended: partiesAttended ?? this.partiesAttended,
      friendsCount: friendsCount ?? this.friendsCount,
      streakDays: streakDays ?? this.streakDays,
      rank: rank ?? this.rank,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      ageRange: ageRange ?? this.ageRange,
      genres: genres ?? this.genres,
      vibes: vibes ?? this.vibes,
      features: features ?? this.features,
      goOutTime: goOutTime ?? this.goOutTime,
      budget: budget ?? this.budget,
      role: role ?? this.role,
    );
  }
}

enum ProfileMode { view, edit }

@immutable
class ProfileState {
  const ProfileState({
    required this.mode,
    required this.data,
    required this.draftBio,
    required this.draftInterests,
    required this.draftSocialLinks,
  });

  final ProfileMode mode;
  final ProfileData data;

  // drafts for edit
  final String draftBio;
  final List<String> draftInterests;
  final List<SocialLink> draftSocialLinks;

  bool get isEditing => mode == ProfileMode.edit;

  ProfileState copyWith({
    ProfileMode? mode,
    ProfileData? data,
    String? draftBio,
    List<String>? draftInterests,
    List<SocialLink>? draftSocialLinks,
  }) {
    return ProfileState(
      mode: mode ?? this.mode,
      data: data ?? this.data,
      draftBio: draftBio ?? this.draftBio,
      draftInterests: draftInterests ?? this.draftInterests,
      draftSocialLinks: draftSocialLinks ?? this.draftSocialLinks,
    );
  }
}
