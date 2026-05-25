import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';

class EventsGridPage extends ConsumerWidget {
  const EventsGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingEventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: AppResponsive.icon(context, 20).clamp(16.0, 20.0),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Gap(12),
                  Text(
                    AppLocalizations.of(context)!.exploreCategories,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Content
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                error: (_, __) => Center(
                  child: Text(
                    AppLocalizations.of(context)!.couldNotLoadEvents,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0),
                    ),
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.noEventsFound,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0),
                        ),
                      ),
                    );
                  }

                  // Group by category
                  final Map<String, List<dynamic>> grouped = {};
                  for (final e in events) {
                    grouped.putIfAbsent(e.categoryTag, () => []).add(e);
                  }
                  final categories = grouped.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final catEvents = grouped[cat]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Gap(10),
                              Text(
                                cat,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppResponsive.font(context, 15).clamp(13.0, 16.0),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                '${catEvents.length}',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.0),
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),

                          // Horizontal scroll cards
                          SizedBox(
                            height: AppResponsive.gap(context, 210).clamp(180.0, 230.0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: catEvents.length,
                              itemBuilder: (context, j) {
                                final event = catEvents[j];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _EventCard(
                                    id: event.id,
                                    title: event.title,
                                    dateText: event.dateText,
                                    locationText: event.locationText,
                                    imageUrl: event.imageUrl,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Gap(28),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.id,
    required this.title,
    required this.dateText,
    required this.locationText,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String dateText;
  final String locationText;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: id)),
      ),
      child: SizedBox(
        width: AppResponsive.gap(context, 160).clamp(130.0, 180.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.surface),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surface,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.primary,
                          size: AppResponsive.icon(context, 30).clamp(24.0, 30.0),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.70)],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      right: 10,
                      child: Text(
                        dateText,
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: AppResponsive.font(context, 11).clamp(9.0, 12.0),
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.0),
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const Gap(3),
            Text(
              locationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white54,
                fontSize: AppResponsive.font(context, 11).clamp(9.0, 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
