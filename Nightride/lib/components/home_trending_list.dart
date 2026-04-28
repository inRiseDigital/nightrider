// lib/components/home_trending_list.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/home_dummy_data.dart';
import 'package:nightride/domain/home_models.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/event_detail_page.dart';
import 'package:nightride/providers/home_providers.dart';

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

    // Filter active but nothing matches
    if (filtered.isEmpty && (cat != 'ALL' || country != 'ALL')) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Text(AppLocalizations.of(context)!.noEventsMatchFilter, style: TextStyle(color: Colors.white38, fontSize: 14.sp)),
        ),
      );
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
    final bool liked = ref.watch(trendingLikeProvider(event.id));

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
      ),
      borderRadius: BorderRadius.circular(24.r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          height: 178.h,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12.w,
                right: 12.w,
                top: 12.h,
                child: Row(
                  children: <Widget>[
                    _TagPill(text: event.categoryTag),
                    const Spacer(),
                    _HeartIconButton(
                      active: liked,
                      onTap:
                          () =>
                              ref
                                  .read(trendingLikeProvider(event.id).notifier)
                                  .state = !liked,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Gap(7.h),
                    Row(
                      children: <Widget>[
                        _Meta(
                          icon: Icons.schedule_rounded,
                          text: event.dateText,
                        ),
                        if (event.language.isNotEmpty) ...[
                          Gap(10.w),
                          _Meta(icon: Icons.language_rounded, text: event.language),
                        ],
                        Gap(10.w),
                        Expanded(
                          child: _Meta(
                            icon: Icons.location_on_rounded,
                            text: event.locationText,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                    Gap(12.h),
                    Row(
                      children: <Widget>[
                        _InterestedRow(
                          avatars: event.avatars,
                          countText: event.interestedCountText,
                        ),
                        const Spacer(),
                        _ActionPill(
                          text: AppLocalizations.of(context)!.view,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EventDetailPage(id: event.id)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
        fontSize: 12.2.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.78),
      ),
    );

    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14.sp, color: Colors.white.withValues(alpha: 0.72)),
        Gap(5.w),
        expand ? Expanded(child: label) : label,
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
          height: 26.w,
          width: (show == 0) ? 0 : (26.w + (show - 1) * 16.w),
          child: Stack(
            children: List<Widget>.generate(show, (int i) {
              return Positioned(
                left: i * 16.w,
                child: Container(
                  width: 26.w,
                  height: 26.w,
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
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

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
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18.sp,
          color:
              active
                  ? AppTheme.primary.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
