import '../domain/profile_models.dart';

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
