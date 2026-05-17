// lib/components/home_featured_carousel.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';

class HomeFeaturedCarousel extends ConsumerWidget {
  const HomeFeaturedCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int current = ref.watch(featuredCarouselIndexProvider);
    final featuredAsync = ref.watch(featuredEventsProvider);
    final carouselHeight = AppDimensions.featuredCarouselHeight(context);
    if (featuredAsync.isLoading) {
      return SizedBox(
        height: carouselHeight,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
      );
    }
    final baseEvents = featuredAsync.asData?.value ?? [];
    final filtered = ref.watch(filteredFeaturedProvider);
    final cat     = ref.watch(selectedCategoryProvider);
    final country = ref.watch(selectedCountryProvider);

    // No real data at all → show dummy fallback
    if (baseEvents.isEmpty) return _buildSlider(context, ref, current, kFeaturedEvents);

    // Filter active but nothing matches → show nothing (no dummy)
    if (filtered.isEmpty && (cat != 'ALL' || country != 'ALL')) {
      return SizedBox(
        height: carouselHeight,
        child: Center(
          child: Text(
            'No events match this filter',
            style: TextStyle(color: Colors.white38, fontSize: 14.sp),
          ),
        ),
      );
    }

    final events = filtered.isNotEmpty ? filtered : baseEvents;
    return _buildSlider(context, ref, current, events);
  }

  Widget _buildSlider(BuildContext context, WidgetRef ref, int current, List<FeaturedEvent> events) {
    final sliderHeight = AppDimensions.featuredCarouselHeight(context) - 10;
    return RepaintBoundary(
      child: Column(
        children: <Widget>[
          CarouselSlider(
            items: events
                .map((FeaturedEvent e) => GestureDetector(
                      onTap: e.id.isNotEmpty
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EventDetailPage(id: e.id),
                                ),
                              )
                          : null,
                      child: _FeaturedHeroCard(event: e),
                    ))
                .toList(),
            options: CarouselOptions(
              height: sliderHeight,
              viewportFraction: AppResponsive.featuredViewportFraction(context),
              enlargeCenterPage: true,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              onPageChanged: (int index, CarouselPageChangedReason reason) {
                ref.read(featuredCarouselIndexProvider.notifier).setIndex(index);
              },
            ),
          ),
          SizedBox(height: AppResponsive.gap(context, 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(events.length, (int i) {
              final bool selected = i == current;
              final dotH = AppResponsive.gap(context, 8).clamp(6.0, 10.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(horizontal: AppResponsive.gap(context, 4)),
                width: selected ? dotH * 2.2 : dotH,
                height: dotH,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent
                      : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHeroCard extends StatelessWidget {
  const _FeaturedHeroCard({required this.event});
  final FeaturedEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26.r,
                offset: Offset(0, 16.h),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.10),
                blurRadius: 30.r,
                offset: Offset(0, 18.h),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) =>
                        Container(color: Colors.white.withValues(alpha: 0.06)),
                errorWidget:
                    (_, __, ___) => Container(
                      color: Colors.white.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
              ),
              const _CinematicOverlay(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomFadeStrip(height: 96.h),
              ),
              Positioned(
                right: AppResponsive.gap(context, 12),
                top: AppResponsive.gap(context, 12),
                child: _ActionButton(
                  size: AppResponsive.featuredActionButtonSize(context),
                  icon: Icons.near_me_rounded,
                  onTap: () {},
                ),
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 14.h,
                child: _FeaturedBottomRow(event: event),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicOverlay extends StatelessWidget {
  const _CinematicOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.86),
          ],
          stops: const <double>[0.0, 0.48, 0.72, 1.0],
        ),
      ),
    );
  }
}

class _BottomFadeStrip extends StatelessWidget {
  const _BottomFadeStrip({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: 0.00),
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.82),
            ],
            stops: const <double>[0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

class _FeaturedBottomRow extends StatelessWidget {
  const _FeaturedBottomRow({required this.event});
  final FeaturedEvent event;

  @override
  Widget build(BuildContext context) {
    final genreMaxW = AppResponsive.featuredGenreMaxWidth(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 16).clamp(14.0, 17.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppResponsive.gap(context, 5)),
              Text(
                event.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppResponsive.gap(context, 10)),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: genreMaxW),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.gap(context, 12),
                  vertical: AppResponsive.gap(context, 6),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  event.badgeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppResponsive.gap(context, 6)),
            Text(
              event.dateText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.size, required this.icon, required this.onTap});
  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.5,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
