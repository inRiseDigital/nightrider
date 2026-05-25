import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

class VenueDetailsPage extends ConsumerWidget {
  const VenueDetailsPage({super.key, required this.data});

  final MapBottomCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favouritesStreamProvider).asData?.value ?? [];
    final bool liked = favs.any((f) => f['id'] == data.id);
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
                expandedHeight: 380,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.scaffold,
                leadingWidth: 70,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 40,
                        width: 40,
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
                    padding: const EdgeInsets.only(right: 14),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: liked ? AppTheme.accent : Colors.white,
                              size: 20,
                            ),
                            onPressed: () async {
                              final user = ref.read(authStateProvider).asData?.value;
                              if (user == null) return;
                              final svc = ref.read(favouritesServiceProvider);
                              if (liked) {
                                await svc.remove(user.uid, data.id);
                              } else {
                                await svc.add(user.uid, {
                                  'id': data.id,
                                  'name': data.title,
                                  'title': data.title,
                                  'cover_image': data.imageUrl,
                                  'city': data.locationLine,
                                  'date': data.openText,
                                  'genre': data.subtitle,
                                  'lat': data.lat,
                                  'lng': data.lng,
                                });
                              }
                            },
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          data.subtitle.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: AppResponsive.font(context, 10).clamp(8.5, 11.0),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Gap(16),

                      // Title
                      Text(
                        data.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppResponsive.font(context, 26).clamp(22.0, 28.5),
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const Gap(16),

                      // Location & Distance card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.location_on_rounded, color: AppTheme.primary, size: AppResponsive.icon(context, 20).clamp(17.0, 22.0)),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.locationLine,
                                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), fontWeight: FontWeight.bold),
                                      ),
                                      if (data.subtitle.isNotEmpty)
                                        Text(
                                          data.subtitle,
                                          style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0)),
                                        ),
                                    ],
                                  ),
                                ),
                                // Distance badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        distLabel,
                                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0), fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    if (travelLabel.isNotEmpty) ...[
                                      const Gap(4),
                                      Text(
                                        travelLabel,
                                        style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const Gap(12),
                            Divider(color: Colors.white.withValues(alpha: 0.05)),
                            const Gap(12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.access_time_filled_rounded, color: Colors.amber, size: AppResponsive.icon(context, 20).clamp(17.0, 22.0)),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    data.openText,
                                    style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (data.priceHint.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      data.priceHint,
                                      style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(24),

                      // ── Map preview ───────────────────────────────────────
                      Text(
                        'Location on Map',
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0), fontWeight: FontWeight.w900),
                      ),
                      const Gap(12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 200,
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
                      const Gap(28),

                      // Tags
                      Text(
                        'Features & Vibes',
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0), fontWeight: FontWeight.w900),
                      ),
                      const Gap(16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: data.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_note_rounded, color: AppTheme.primary, size: AppResponsive.icon(context, 14).clamp(12.0, 15.5)),
                              const Gap(8),
                              Text(
                                tag,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5), fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
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
                      Text('Admission', style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0), fontWeight: FontWeight.w600)),
                      Text(
                        data.priceHint.isNotEmpty ? data.priceHint : 'Free',
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 20).clamp(17.0, 22.0), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const Gap(24),
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accentPurple]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'GET TICKETS',
                          style: TextStyle(fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
          Icon(Icons.map_rounded, color: AppTheme.primary, size: AppResponsive.icon(context, 40).clamp(32.0, 44.0)),
          const Gap(8),
          Text(
            data.locationLine,
            style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
