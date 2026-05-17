// lib/features/home/data/home_dummy_data.dart
import '../domain/home_models.dart';

const String kAppTitle = 'NightRide';
const String kCurrentCountry = 'SriLanka';

const List<FeaturedEvent> kFeaturedEvents = <FeaturedEvent>[
  FeaturedEvent(
    title: 'Summer Music Festival',
    subtitle: 'Central Park, NYC',
    badgeText: 'Free',
    dateText: 'Fri, Dec 25',
    imageUrl:
        'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=1400&q=80',
  ),
  FeaturedEvent(
    title: 'Neon Night Parade',
    subtitle: 'Downtown Lights',
    badgeText: 'Live',
    dateText: 'Sat, Jan 10',
    imageUrl:
        'https://images.unsplash.com/photo-1506157786151-b8491531f063?auto=format&fit=crop&w=1400&q=80',
  ),
  FeaturedEvent(
    title: 'After Hours Techno',
    subtitle: 'Warehouse District',
    badgeText: 'VIP',
    dateText: 'Sun, Feb 02',
    imageUrl:
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1400&q=80',
  ),
];

const List<CategoryChip> kCategories = <CategoryChip>[
  CategoryChip(
    title: 'CLUB',
    imageUrl:
        'https://images.unsplash.com/photo-1516981442399-a91139e20ff8?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'DJ',
    imageUrl:
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'TECHNO',
    imageUrl:
        'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'RAVE',
    imageUrl:
        'https://images.unsplash.com/photo-1501527459-2d5409f8cf45?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'EDM',
    imageUrl:
        'https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'HOUSE',
    imageUrl:
        'https://images.unsplash.com/photo-1521337706264-a414f153a5f5?auto=format&fit=crop&w=900&q=80',
  ),
  CategoryChip(
    title: 'LIVE',
    imageUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=900&q=80',
  ),
];

const _a1 = 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=128&q=80';
const _a2 = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=128&q=80';
const _a3 = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=128&q=80';
const _a4 = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=128&q=80';
const _a5 = 'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?auto=format&fit=crop&w=128&q=80';

const List<TrendingEvent> kTrendingEvents = <TrendingEvent>[
  // ── RAVE ──
  TrendingEvent(
    id: 'trend_1',
    title: 'Midnight Neon Party',
    locationText: 'Sky Lounge, Downtown',
    dateText: 'Tonight • 11:30 PM',
    categoryTag: 'RAVE',
    imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+12',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_8',
    title: 'Warehouse Rave AMS',
    locationText: 'DGTL, Amsterdam',
    dateText: 'Sat • 2:00 AM',
    categoryTag: 'RAVE',
    countryCode: 'NL',
    imageUrl: 'https://images.unsplash.com/photo-1501527459-2d5409f8cf45?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+156',
    avatars: [_a4, _a5, _a1],
  ),

  // ── TECHNO ──
  TrendingEvent(
    id: 'trend_2',
    title: 'Underground Techno',
    locationText: 'The Vault, Industrial Zone',
    dateText: 'Fri • 01:00 AM',
    categoryTag: 'TECHNO',
    imageUrl: 'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+45',
    avatars: [_a4, _a5, _a1],
  ),
  TrendingEvent(
    id: 'trend_7',
    title: 'Berghain Friday',
    locationText: 'Berghain, Berlin',
    dateText: 'Tonight • 12:00 AM',
    categoryTag: 'TECHNO',
    countryCode: 'DE',
    imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+580',
    avatars: [_a1, _a2, _a3],
  ),

  // ── CLUB ──
  TrendingEvent(
    id: 'trend_3',
    title: 'VIP Night at Fabric',
    locationText: 'Fabric, London',
    dateText: 'Sat • 10:00 PM',
    categoryTag: 'CLUB',
    countryCode: 'GB',
    imageUrl: 'https://images.unsplash.com/photo-1571266028243-e4733b0f0bb0?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+120',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_4',
    title: 'Zouk Saturday Night',
    locationText: 'Zouk, Singapore',
    dateText: 'Tonight • 11:00 PM',
    categoryTag: 'CLUB',
    countryCode: 'SG',
    imageUrl: 'https://images.unsplash.com/photo-1516981442399-a91139e20ff8?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+89',
    avatars: [_a4, _a5, _a1],
  ),

  // ── DJ ──
  TrendingEvent(
    id: 'trend_5',
    title: 'DJ Sunset Sessions',
    locationText: 'Pacha, Ibiza',
    dateText: 'Tonight • 9:00 PM',
    categoryTag: 'DJ',
    countryCode: 'ES',
    imageUrl: 'https://images.unsplash.com/photo-1509281373149-e957c6296406?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+210',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_6',
    title: 'Boiler Room Berlin',
    locationText: 'Tresor, Berlin',
    dateText: 'Fri • 11:00 PM',
    categoryTag: 'DJ',
    countryCode: 'DE',
    imageUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+340',
    avatars: [_a4, _a5, _a1],
  ),

  // ── EDM ──
  TrendingEvent(
    id: 'trend_9',
    title: 'Electric Storm ADE',
    locationText: 'Amsterdam, Netherlands',
    dateText: 'Fri • 8:00 PM',
    categoryTag: 'EDM',
    countryCode: 'NL',
    imageUrl: 'https://images.unsplash.com/photo-1514516873430-9ca4f4f15f39?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+890',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_10',
    title: 'Ultra Music Festival',
    locationText: 'Tokyo Dome, Japan',
    dateText: 'Sun • 6:00 PM',
    categoryTag: 'EDM',
    countryCode: 'JP',
    imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+1200',
    avatars: [_a4, _a5, _a1],
  ),

  // ── HOUSE ──
  TrendingEvent(
    id: 'trend_11',
    title: 'Deep House Sunday',
    locationText: 'Ministry of Sound, London',
    dateText: 'Sun • 4:00 PM',
    categoryTag: 'HOUSE',
    countryCode: 'GB',
    imageUrl: 'https://images.unsplash.com/photo-1521337706264-a414f153a5f5?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+67',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_12',
    title: 'Ibiza House Classics',
    locationText: 'Amnesia, Ibiza',
    dateText: 'Wed • 10:00 PM',
    categoryTag: 'HOUSE',
    countryCode: 'ES',
    imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+234',
    avatars: [_a4, _a5, _a1],
  ),

  // ── LIVE ──
  TrendingEvent(
    id: 'trend_13',
    title: 'Jazz & Soul Night',
    locationText: 'Jazz Café, London',
    dateText: 'Tonight • 8:00 PM',
    categoryTag: 'LIVE',
    countryCode: 'GB',
    imageUrl: 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+45',
    avatars: [_a1, _a2, _a3],
  ),
  TrendingEvent(
    id: 'trend_14',
    title: 'Blue Note Live',
    locationText: 'Blue Note, New York',
    dateText: 'Fri • 9:00 PM',
    categoryTag: 'LIVE',
    countryCode: 'US',
    imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+78',
    avatars: [_a4, _a5, _a1],
  ),
];
