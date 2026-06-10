import '../domain/profile_models.dart';

/// Builds a guest profile. Uses the last 4 alphanum chars of the Firebase UID
/// as the guest ID so it stays consistent within the same device session.
ProfileData guestProfile(String? uid) {
  String tag = '----';
  if (uid != null && uid.isNotEmpty) {
    final chars = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    tag = chars.length >= 4
        ? chars.substring(chars.length - 4).toUpperCase()
        : chars.padLeft(4, '0').toUpperCase();
  }
  return ProfileData(
    displayName: 'Guest #$tag',
    username: '@guest',
    pronouns: '',
    countryCode: '',
    avatarUrl: '',
    networkCount: 0,
    interestedCount: 0,
    bio: 'Sign in to unlock your full Night Rite profile.',
    interests: const [],
    socialLinks: const [],
    joinedText: 'GUEST ACCOUNT',
  );
}

/// Master list user can choose from (dummy)
const List<String> kAllInterestOptions = <String>[
  'DJ',
  'EDM',
  'Techno',
  'Hip-Hop',
  'J-Pop',
  'House',
  'Trance',
  'Drum & Bass',
  'Afrobeat',
  'K-Pop',
  'Live',
  'Rock',
  'Indie',
  'Jazz',
  'Reggae',
];

const ProfileData kDummyProfile = ProfileData(
  displayName: 'KalharaD',
  username: '@KalharaD',
  pronouns: 'she/her',
  countryCode: 'LK',
  avatarUrl: 'assets/images/business-man-smiling-free-photo.jpg',
  networkCount: 1215,
  interestedCount: 1215,
  bio: 'Shrining in chaos ✨ Indie game developer • Vinyl junkie 🎶',
  interests: <String>['DJ', 'EDM', 'Techno', 'Hip-Hop', 'J-Pop'],
  socialLinks: <SocialLink>[
    SocialLink(type: SocialType.instagram, handle: '@KalharaD'),
    SocialLink(type: SocialType.facebook, handle: '@KalharaD'),
  ],
  joinedText: 'JOINED  MAY 18, 2001',
);
