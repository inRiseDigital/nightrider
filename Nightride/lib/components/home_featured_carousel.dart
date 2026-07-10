// lib/components/home_featured_carousel.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.neonLime,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final baseEvents = featuredAsync.asData?.value ?? [];
    final filtered = ref.watch(filteredFeaturedProvider);
    final cat = ref.watch(selectedCategoryProvider);
    final country = ref.watch(selectedCountryProvider);

    // No real data at all — show dummy fallback
    if (baseEvents.isEmpty) {
      return _buildSlider(context, ref, current, kFeaturedEvents);
    }

    // Filter active but nothing matches — show empty state
    if (filtered.isEmpty && (cat != 'ALL' || country != 'ALL')) {
      return SizedBox(
        height: carouselHeight,
        child: Center(
          child: Text(
            'No events match this filter',
            style: TextStyle(
              color: AppTheme.cream.withValues(alpha: 0.4),
              fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0),
            ),
          ),
        ),
      );
    }

    final events = filtered.isNotEmpty ? filtered : baseEvents;
    return _buildSlider(context, ref, current, events);
  }

  Widget _buildSlider(
    BuildContext context,
    WidgetRef ref,
    int current,
    List<FeaturedEvent> events,
  ) {
    final sliderHeight =
        AppDimensions.featuredCarouselHeight(context) - 10;
    return RepaintBoundary(
      child: Column(
        children: <Widget>[
          CarouselSlider(
            items: events
                .map(
                  (FeaturedEvent e) => GestureDetector(
                    onTap: e.id.isNotEmpty
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EventDetailPage(id: e.id),
                              ),
                            )
                        : null,
                    child: _FeaturedHeroCard(event: e),
                  ),
                )
                .toList(),
            options: CarouselOptions(
              height: sliderHeight,
              viewportFraction:
                  AppResponsive.featuredViewportFraction(context),
              enlargeCenterPage: true,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration:
                  const Duration(milliseconds: 800),
              onPageChanged: (int index, CarouselPageChangedReason reason) {
                ref
                    .read(featuredCarouselIndexProvider.notifier)
                    .setIndex(index);
              },
            ),
          ),
          SizedBox(height: AppResponsive.gap(context, 12)),
          // Retro dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(events.length, (int i) {
              final bool selected = i == current;
              final dotH =
                  AppResponsive.gap(context, 7).clamp(5.0, 9.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(
                    horizontal: AppResponsive.gap(context, 3)),
                width: selected ? dotH * 2.8 : dotH,
                height: dotH,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.neonLime
                      : AppTheme.borderGray,
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
    final cardRadius =
        AppResponsive.radius(context, 20).clamp(16.0, 24.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkGray,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: AppTheme.borderGray, width: 1),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: Color(0x22FF3D73),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Background image
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppTheme.darkGray),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.darkGray,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppTheme.borderGray,
                    size: 32,
                  ),
                ),
              ),
              // Cinematic gradient overlay
              const _CinematicOverlay(),
              // Bottom text row
              Positioned(
                left: AppResponsive.gap(context, 16),
                right: AppResponsive.gap(context, 16),
                bottom: AppResponsive.gap(context, 16),
                child: _FeaturedBottomRow(event: event),
              ),
              // Top-right action button
              Positioned(
                right: AppResponsive.gap(context, 12),
                top: AppResponsive.gap(context, 12),
                child: _ActionButton(
                  size: AppResponsive.featuredActionButtonSize(context),
                  icon: Icons.near_me_rounded,
                  onTap: () {},
                ),
              ),
              // Hairline border
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(
                        color: AppTheme.borderGray,
                        width: 1,
                      ),
                    ),
                  ),
                ),
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
            Colors.black.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.90),
          ],
          stops: const <double>[0.0, 0.42, 0.70, 1.0],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Genre pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.hotPink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.hotPink.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  event.badgeText.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
                    fontWeight: FontWeight.w900,
                    color: AppTheme.hotPink,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(height: AppResponsive.gap(context, 6)),
              // Event title in Anton
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
                  fontWeight: FontWeight.w400,
                  color: AppTheme.cream,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppResponsive.gap(context, 4)),
              // Subtitle + date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:
                            AppResponsive.font(context, 12).clamp(10.5, 13.0),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.dateText,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize:
                          AppResponsive.font(context, 11).clamp(10.0, 12.0),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.cream.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.size, required this.icon, required this.onTap});
  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.borderGray.withValues(alpha: 0.6), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.5,
          color: AppTheme.cream.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
