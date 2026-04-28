// lib/data/search_dummy_data.dart

import 'package:nightride/domain/search_models.dart';

const String kSearchHint = 'Search Sri Lankan events';

const List<SearchSuggestionItem> kSearchSuggestions = <SearchSuggestionItem>[
  SearchSuggestionItem(
    id: 'warp_shinjuku_01',
    title: 'WARP Shinjuku',
    subtitle: 'NightClub • Colombo',
    avatarUrl: 'https://picsum.photos/seed/warp1/120',
  ),
  SearchSuggestionItem(
    id: 'pulse_arena_02',
    title: 'Pulse Arena',
    subtitle: 'Festival • Negombo',
    avatarUrl: 'https://picsum.photos/seed/pulse2/120',
  ),
  SearchSuggestionItem(
    id: 'neon_dock_03',
    title: 'Neon Dock',
    subtitle: 'Rave • Galle',
    avatarUrl: 'https://picsum.photos/seed/neon3/120',
  ),
  SearchSuggestionItem(
    id: 'afterhours_vault_04',
    title: 'Afterhours Vault',
    subtitle: 'Techno • Colombo 07',
    avatarUrl: 'https://picsum.photos/seed/vault4/120',
  ),
  SearchSuggestionItem(
    id: 'rooftop_bass_05',
    title: 'Rooftop Bass Night',
    subtitle: 'DJ • Kandy',
    avatarUrl: 'https://picsum.photos/seed/bass5/120',
  ),
  SearchSuggestionItem(
    id: 'beachwave_06',
    title: 'Beachwave Sunset',
    subtitle: 'EDM • Mirissa',
    avatarUrl: 'https://picsum.photos/seed/beach6/120',
  ),
];
