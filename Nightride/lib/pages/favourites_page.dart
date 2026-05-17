import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

class FavouritesPage extends ConsumerWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favouritesStreamProvider);
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
              child: Text(
                'Favourites',
                style: GoogleFonts.inter(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: favAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                ),
                error: (_, __) => _empty('Could not load favourites'),
                data: (favs) {
                  if (favs.isEmpty) {
                    return _empty(
                      user == null
                          ? 'Sign in to save your favourite events'
                          : 'No saved events yet\nTap the heart on any event to save it',
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => Gap(12.h),
                    itemBuilder: (context, i) {
                      final fav = favs[i];
                      return _FavCard(fav: fav);
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

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, color: Colors.white24, size: 56.sp),
              Gap(16.h),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  color: Colors.white38,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
}

class _FavCard extends ConsumerWidget {
  const _FavCard({required this.fav});
  final Map<String, dynamic> fav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = fav['name'] as String? ?? fav['title'] as String? ?? '';
    final String image = fav['cover_image'] as String? ?? '';
    final String city  = fav['city'] as String? ?? '';
    final String date  = fav['date'] as String? ?? '';
    final String genre = fav['genre'] as String? ?? '';
    final String id    = fav['id'] as String? ?? '';

    final daysLeft = _daysUntil(date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail — stretches to match the column height
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
              ),
              child: CachedNetworkImage(
                imageUrl: image,
                width: 100.w,
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(width: 100.w, child: Container(color: Colors.white10)),
                errorWidget: (_, __, ___) => SizedBox(
                  width: 100.w,
                  child: Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: Icon(Icons.music_note_rounded, color: Colors.white24, size: 28.sp),
                  ),
                ),
              ),
            ),
            Gap(12.w),
            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (city.isNotEmpty) ...[
                      Gap(4.h),
                      Text(
                        city,
                        style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white54),
                      ),
                    ],
                    if (genre.isNotEmpty || daysLeft != null) ...[
                      Gap(6.h),
                      Row(
                        children: [
                          if (genre.isNotEmpty) _Chip(genre),
                          if (daysLeft != null) ...[
                            Gap(6.w),
                            _Chip(
                              daysLeft == 0
                                  ? 'Today!'
                                  : daysLeft == 1
                                      ? 'Tomorrow!'
                                      : '$daysLeft days away',
                              color: daysLeft <= 3 ? AppTheme.accent : Colors.white24,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: AppTheme.accent, size: 22),
              onPressed: () async {
                final user = ref.read(authStateProvider).asData?.value;
                if (user == null) return;
                await ref.read(favouritesServiceProvider).remove(user.uid, id);
              },
            ),
          ],
        ),
      ),
    );
  }

  int? _daysUntil(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return null;
    final today = DateTime.now();
    final diff = DateTime(dt.year, dt.month, dt.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return diff < 0 ? null : diff;
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color = Colors.white24});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color == AppTheme.accent ? AppTheme.accent : Colors.white60,
        ),
      ),
    );
  }
}
