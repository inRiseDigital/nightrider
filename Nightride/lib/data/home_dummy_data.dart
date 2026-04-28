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

const List<TrendingEvent> kTrendingEvents = <TrendingEvent>[
  TrendingEvent(
    id: 'trend_1',
    title: 'Midnight Neon Party',
    locationText: 'Sky Lounge, Downtown',
    dateText: 'Tonight • 11:30 PM',
    categoryTag: 'RAVE',
    imageUrl:
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+12',
    avatars: <String>[
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=128&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=128&q=80',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=128&q=80',
    ],
  ),
  TrendingEvent(
    id: 'trend_2',
    title: 'Underground Techno',
    locationText: 'The Vault, Industrial Zone',
    dateText: 'Fri • 01:00 AM',
    categoryTag: 'TECHNO',
    imageUrl:
        'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=1400&q=80',
    interestedCountText: '+45',
    avatars: <String>[
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=128&q=80',
      'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?auto=format&fit=crop&w=128&q=80',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=128&q=80',
    ],
  ),
];
