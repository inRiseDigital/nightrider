// lib/components/home_trending_list.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

// ignore: unused_import
import 'package:nightride/core/responsive/app_dimensions.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

class HomeTrendingList extends ConsumerWidget {
  const HomeTrendingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendingEventsProvider);
    if (async.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2));
    }

    final allLive = async.asData?.value ?? [];
    final filtered = ref.watch(filteredTrendingProvider);
    final cat     = ref.watch(selectedCategoryProvider);
    final country = ref.watch(selectedCountryProvider);

    // No Firestore data at all → show dummy fallback
    if (allLive.isEmpty) return _buildList(kTrendingEvents);

    // Filter active but nothing in Firestore matches → fall back to dummy events
    if (filtered.isEmpty && (cat != 'ALL' || country != 'ALL')) {
      final fallback = cat == 'ALL'
          ? kTrendingEvents
          : kTrendingEvents.where((e) => e.categoryTag == cat).toList();
      return _buildList(fallback.isNotEmpty ? fallback : kTrendingEvents);
    }

    return _buildList(filtered.isNotEmpty ? filtered : allLive);
  }

  Widget _buildList(List<TrendingEvent> events) {
    return Column(
      children: List<Widget>.generate(events.length, (int i) {
        final TrendingEvent e = events[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i == events.length - 1 ? 0 : 12.h),
          child: _TrendingCard(event: e),
        );
      }),
    );
  }
}

class _TrendingCard extends ConsumerWidget {
  const _TrendingCard({required this.event});
  final TrendingEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favouritesStreamProvider).asData?.value ?? [];
    final bool liked = favs.any((f) => f['id'] == event.id);

    final cardHeight = AppResponsive.eventCardHeight(context);
    final pad = AppResponsive.gap(context, 14).clamp(12.0, 16.0);
    // Width reserved on the right side for the heart (top) and View (bottom)
    // buttons. Keeps the title/meta/interested column from running underneath
    // those buttons — this is what was causing the V3 overlap.
    final actionCol = AppResponsive.trendingActionColumnWidth(context);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
      ),
      borderRadius: BorderRadius.circular(24.r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 1. Background image
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: Colors.white.withValues(alpha: 0.06)),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.06),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              // 2. Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x1A000000),
                      Color(0x4D000000),
                      Color(0xD9000000),
                    ],
                    stops: <double>[0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // 3. Heart button — top-right (in the reserved right column).
              Positioned(
                top: pad,
                right: pad,
                child: _HeartIconButton(
                  active: liked,
                  onTap: () => _toggleFavourite(ref, liked),
                ),
              ),

              // 4. SINGLE text column (tag-pill + title + meta + interested
              //    row). Putting the tag-pill *inside* the same Column as the
              //    title makes overlap structurally impossible — they share
              //    the column's vertical layout and a Spacer between them
              //    naturally absorbs whatever extra height the card has.
              //    `right: pad + actionCol` reserves space on the right for
              //    the heart and View buttons so text doesn't run under them.
              Positioned(
                left: pad,
                top: pad,
                right: pad + actionCol,
                bottom: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: _TagPill(text: event.categoryTag),
                    ),
                    const Spacer(),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: AppResponsive.font(context, 16).clamp(13.5, 17.0),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: AppResponsive.gap(context, 6)),
                    Row(
                      children: <Widget>[
                        _Meta(
                          icon: Icons.schedule_rounded,
                          text: event.dateText,
                        ),
                        if (event.language.isNotEmpty) ...[
                          SizedBox(width: AppResponsive.gap(context, 8)),
                          _Meta(
                            icon: Icons.language_rounded,
                            text: event.language,
                          ),
                        ],
                        SizedBox(width: AppResponsive.gap(context, 8)),
                        Expanded(
                          child: _Meta(
                            icon: Icons.location_on_rounded,
                            text: event.locationText,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.gap(context, 8)),
                    _InterestedRow(
                      avatars: event.avatars,
                      countText: event.interestedCountText,
                    ),
                  ],
                ),
              ),

              // 5. View button — bottom-right (won't overlap text because
              //    the text column above reserved `actionCol` of right space).
              Positioned(
                right: pad,
                bottom: pad,
                child: _ActionPill(
                  text: AppLocalizations.of(context)!.view,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventDetailPage(id: event.id),
                    ),
                  ),
                ),
              ),

              // 7. Hairline border outline
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
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

  Future<void> _toggleFavourite(WidgetRef ref, bool isLiked) async {
    final svc = ref.read(favouritesServiceProvider);
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    if (isLiked) {
      await svc.remove(user.uid, event.id);
    } else {
      await svc.add(user.uid, {
        'id': event.id,
        'name': event.title,
        'title': event.title,
        'cover_image': event.imageUrl,
        'city': event.locationText,
        'country': event.countryCode,
        'country_code': event.countryCode,
        'date': event.rawDate,
        'genre': event.categoryTag,
      });
    }
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.expand = false});
  final IconData icon;
  final String text;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.78),
      ),
    );

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: AppResponsive.metaIconSize(context),
          color: Colors.white.withValues(alpha: 0.72),
        ),
        SizedBox(width: AppResponsive.gap(context, 5)),
        expand ? Expanded(child: label) : Flexible(child: label),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _InterestedRow extends StatelessWidget {
  const _InterestedRow({required this.avatars, required this.countText});
  final List<String> avatars;
  final String countText;

  @override
  Widget build(BuildContext context) {
    final int show = avatars.length > 3 ? 3 : avatars.length;

    return Row(
      children: <Widget>[
        SizedBox(
          height: 26.sp,
          width: (show == 0) ? 0 : (26.sp + (show - 1) * 16.w),
          child: Stack(
            children: List<Widget>.generate(show, (int i) {
              return Positioned(
                left: i * 16.w,
                child: Container(
                  width: 26.sp,
                  height: 26.sp,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.55),
                      width: 1.6,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 10.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatars[i],
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Container(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (show > 0) Gap(8.w),
        Text(
          countText,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: AppResponsive.trendingViewButtonHeight(context),
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.gap(context, 14),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.0),
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

// ── Heart button ─────────────────────────────────────────────────────────────

class _HeartIconButton extends StatelessWidget {
  const _HeartIconButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: AppResponsive.trendingFavoriteSize(context),
        height: AppResponsive.trendingFavoriteSize(context),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppResponsive.radius(context, 14)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: AppResponsive.icon(context, 18).clamp(15.0, 20.0),
          color:
              active
                  ? AppTheme.primary.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
