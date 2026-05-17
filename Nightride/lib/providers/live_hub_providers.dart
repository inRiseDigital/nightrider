// lib/providers/live_hub_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nightride/data/services/live_hub_service.dart';
import 'package:nightride/domain/live_hub_models.dart';

final liveHubServiceProvider =
    Provider<LiveHubService>((ref) => LiveHubService());

final liveHubCountryProvider = StateProvider<String>((ref) => 'ALL');

final clubUpdatesProvider = StreamProvider<List<ClubUpdate>>((ref) {
  final country = ref.watch(liveHubCountryProvider);
  return ref
      .watch(liveHubServiceProvider)
      .clubsStream(country: country == 'ALL' ? null : country);
});

final userReportsProvider = StreamProvider<List<UserReport>>((ref) {
  final country = ref.watch(liveHubCountryProvider);
  return ref
      .watch(liveHubServiceProvider)
      .reportsStream(country: country == 'ALL' ? null : country);
});

final socialEventsProvider = StreamProvider<List<SocialEvent>>((ref) {
  final country = ref.watch(liveHubCountryProvider);
  return ref
      .watch(liveHubServiceProvider)
      .eventsStream(country: country == 'ALL' ? null : country);
});

/// Derived from all 3 streams — no hardcoding.
final liveHubAvailableCountriesProvider = Provider<List<String>>((ref) {
  final clubs = ref.watch(clubUpdatesProvider).asData?.value ?? [];
  final reports = ref.watch(userReportsProvider).asData?.value ?? [];
  final events = ref.watch(socialEventsProvider).asData?.value ?? [];
  final seen = <String>{};
  for (final c in clubs) { seen.add(c.country); }
  for (final r in reports) { seen.add(r.country); }
  for (final e in events) { seen.add(e.country); }
  return seen.toList()..sort();
});
