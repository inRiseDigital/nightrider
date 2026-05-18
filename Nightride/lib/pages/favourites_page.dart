import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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
              padding: EdgeInsets.fromLTRB(
                AppResponsive.gap(context, 20).clamp(16.0, 24.0),
                AppResponsive.gap(context, 20).clamp(16.0, 24.0),
                AppResponsive.gap(context, 20).clamp(16.0, 24.0),
                8,
              ),
              child: Text(
                'Favourites',
                style: GoogleFonts.inter(
                  fontSize: AppResponsive.font(context, 26).clamp(22.0, 28.0),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.gap(context, 16).clamp(12.0, 20.0),
                      vertical: 8,
                    ),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const Gap(12),
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
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) => Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white24,
                  size: AppResponsive.icon(context, 56).clamp(40.0, 56.0),
                ),
              ),
              const Gap(16),
              Builder(
                builder: (context) => Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: AppResponsive.font(context, 15).clamp(13.0, 16.0),
                    color: Colors.white38,
                    height: 1.6,
                  ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail — stretches to match the column height
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: image,
                width: AppResponsive.gap(context, 100).clamp(80.0, 110.0),
                fit: BoxFit.cover,
                placeholder: (_, __) => SizedBox(
                  width: AppResponsive.gap(context, 100).clamp(80.0, 110.0),
                  child: Container(color: Colors.white10),
                ),
                errorWidget: (_, __, ___) => SizedBox(
                  width: AppResponsive.gap(context, 100).clamp(80.0, 110.0),
                  child: Container(
                    color: Colors.white10,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: Colors.white24,
                      size: AppResponsive.icon(context, 28).clamp(22.0, 28.0),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                        fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (city.isNotEmpty) ...[
                      const Gap(4),
                      Text(
                        city,
                        style: GoogleFonts.inter(
                          fontSize: AppResponsive.font(context, 12).clamp(10.0, 13.0),
                          color: Colors.white54,
                        ),
                      ),
                    ],
                    if (genre.isNotEmpty || daysLeft != null) ...[
                      const Gap(6),
                      Row(
                        children: [
                          if (genre.isNotEmpty) _Chip(genre),
                          if (daysLeft != null) ...[
                            const Gap(6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: AppResponsive.font(context, 10).clamp(8.0, 11.0),
          fontWeight: FontWeight.w600,
          color: color == AppTheme.accent ? AppTheme.accent : Colors.white60,
        ),
      ),
    );
  }
}
