import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';

class VenueDetailsPage extends ConsumerWidget {
  const VenueDetailsPage({super.key, required this.data});

  final MapBottomCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(userLocationProvider).asData?.value;

    final double km = (userPos != null && data.lat != 0 && data.lng != 0)
        ? haversineKm(userPos.latitude, userPos.longitude, data.lat, data.lng)
        : 0;

    final String distLabel = formatDistance(km);
    final String travelLabel = formatTravel(km);

    final String mapToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    final String staticMapUrl = (mapToken.isNotEmpty && data.lat != 0 && data.lng != 0)
        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/'
            'pin-l+9f7aea(${data.lng},${data.lat})/'
            '${data.lng},${data.lat},14,0/600x280@2x'
            '?access_token=$mapToken'
        : '';

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 380.h,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.scaffold,
                leadingWidth: 70.w,
                leading: Padding(
                  padding: EdgeInsets.only(left: 14.w),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        height: 40.h,
                        width: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 14.w),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          height: 40.h,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'venue_image_${data.title}',
                        child: Image.network(data.imageUrl, fit: BoxFit.cover),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.7, 0.9, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              AppTheme.scaffold.withValues(alpha: 0.5),
                              AppTheme.scaffold.withValues(alpha: 0.9),
                              AppTheme.scaffold,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 120.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          data.subtitle.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Gap(16.h),

                      // Title
                      Text(
                        data.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Gap(16.h),

                      // Location & Distance card
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20.sp),
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.locationLine,
                                        style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                      ),
                                      if (data.subtitle.isNotEmpty)
                                        Text(
                                          data.subtitle,
                                          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                                        ),
                                    ],
                                  ),
                                ),
                                // Distance badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Text(
                                        distLabel,
                                        style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    if (travelLabel.isNotEmpty) ...[
                                      Gap(4.h),
                                      Text(
                                        travelLabel,
                                        style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            Gap(12.h),
                            Divider(color: Colors.white.withValues(alpha: 0.05)),
                            Gap(12.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: 20.sp),
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Text(
                                    data.openText,
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (data.priceHint.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      data.priceHint,
                                      style: TextStyle(color: AppTheme.primaryLight, fontSize: 12.sp, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Gap(24.h),

                      // ── Map preview ───────────────────────────────────────
                      Text(
                        'Location on Map',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      Gap(12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: SizedBox(
                          height: 200.h,
                          width: double.infinity,
                          child: staticMapUrl.isNotEmpty
                              ? Image.network(
                                  staticMapUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) => progress == null
                                      ? child
                                      : Container(
                                          color: AppTheme.surface,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.primary,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                  errorBuilder: (_, __, ___) => _MapPlaceholder(data: data),
                                )
                              : _MapPlaceholder(data: data),
                        ),
                      ),
                      Gap(28.h),

                      // Tags
                      Text(
                        'Features & Vibes',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      Gap(16.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: data.tags.map((tag) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note_rounded, color: AppTheme.primary, size: 14.sp),
                              Gap(8.w),
                              Text(
                                tag,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.95),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Admission', style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      Text(
                        data.priceHint.isNotEmpty ? data.priceHint : 'Free',
                        style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Gap(24.w),
                  Expanded(
                    child: Container(
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accentPurple]),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: Text(
                          'GET TICKETS',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.data});
  final MapBottomCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, color: AppTheme.primary, size: 40.sp),
          Gap(8.h),
          Text(
            data.locationLine,
            style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
