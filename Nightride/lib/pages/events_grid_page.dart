import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

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
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Gap(12.w),
                  Text(
                    AppLocalizations.of(context)!.exploreCategories,
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Gap(16.h),

            // Content
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                error: (_, __) => Center(child: Text(AppLocalizations.of(context)!.couldNotLoadEvents, style: TextStyle(color: Colors.white54, fontSize: 14.sp))),
                data: (events) {
                  if (events.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.noEventsFound, style: TextStyle(color: Colors.white38, fontSize: 14.sp)));
                  }

                  // Group by category
                  final Map<String, List<dynamic>> grouped = {};
                  for (final e in events) {
                    grouped.putIfAbsent(e.categoryTag, () => []).add(e);
                  }
                  final categories = grouped.keys.toList();

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 24.h),
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
                                width: 4.w,
                                height: 16.h,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              Gap(10.w),
                              Text(
                                cat,
                                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w900),
                              ),
                              Gap(8.w),
                              Text(
                                '${catEvents.length}',
                                style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                              ),
                            ],
                          ),
                          Gap(12.h),

                          // Horizontal scroll cards
                          SizedBox(
                            height: 210.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: catEvents.length,
                              itemBuilder: (context, j) {
                                final event = catEvents[j];
                                return Padding(
                                  padding: EdgeInsets.only(right: 12.w),
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
                          Gap(28.h),
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
        width: 160.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
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
                        child: Icon(Icons.music_note_rounded, color: AppTheme.primary, size: 30.sp),
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
                      left: 10.w,
                      bottom: 10.h,
                      right: 10.w,
                      child: Text(
                        dateText,
                        style: TextStyle(color: AppTheme.accent, fontSize: 11.sp, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gap(8.h),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800, height: 1.2),
            ),
            Gap(3.h),
            Text(
              locationText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }
}
