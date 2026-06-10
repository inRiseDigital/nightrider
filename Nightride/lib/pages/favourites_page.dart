import 'package:cached_network_image/cached_network_image.dart';
import 'package:nightride/components/nightrite_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/event_detail_page.dart';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAVED',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 32).clamp(26.0, 36.0),
                      fontWeight: FontWeight.w400,
                      color: AppTheme.primary,
                      letterSpacing: 2.0,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'EVENTS',
                    style: GoogleFonts.anton(
                      fontSize: AppResponsive.font(context, 32).clamp(26.0, 36.0),
                      fontWeight: FontWeight.w400,
                      color: AppTheme.accent,
                      letterSpacing: 2.0,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: user == null
                  ? _guestSignInPrompt(context)
                  : NightRiteRefresh(
                      onRefresh: () async {
                        ref.invalidate(favouritesStreamProvider);
                        await Future<void>.delayed(const Duration(milliseconds: 600));
                      },
                      child: favAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                        ),
                        error: (_, __) => _emptyScrollable('Could not load favourites'),
                        data: (favs) {
                          if (favs.isEmpty) {
                            return _emptyScrollable(
                              'No saved events yet\nTap the heart on any event to save it',
                            );
                          }
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyScrollable(String msg) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) => Icon(
                      Icons.local_activity_rounded,
                      color: AppTheme.primary.withValues(alpha: 0.55),
                      size: AppResponsive.icon(context, 64).clamp(48.0, 64.0),
                    ),
                  ),
                  const Gap(16),
                  Builder(
                    builder: (context) => Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: AppResponsive.font(context, 15).clamp(13.0, 16.0),
                        color: AppTheme.primaryLight.withValues(alpha: 0.70),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _guestSignInPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
              const Gap(24),
              Text(
                'SIGN IN TO SAVE EVENTS',
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: AppResponsive.font(context, 20).clamp(17.0, 22.0),
                  color: Colors.white,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
              ),
              const Gap(10),
              Text(
                'Create a free account to bookmark events,\ntrack your favourites and get reminders.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: AppResponsive.font(context, 13).clamp(12.0, 14.0),
                  color: Colors.white.withValues(alpha: 0.50),
                  height: 1.6,
                ),
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'SIGN IN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.anton(
                        fontSize: AppResponsive.font(context, 15).clamp(13.0, 16.0),
                        color: Colors.black,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignInPage(),
                  ),
                ),
                child: Text(
                  "Don't have an account? Sign up",
                  style: GoogleFonts.poppins(
                    fontSize: AppResponsive.font(context, 12).clamp(11.0, 13.0),
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
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

    final double imgSize = AppResponsive.gap(context, 96).clamp(84.0, 108.0);
    final String daysLabel = daysLeft == null
        ? ''
        : daysLeft == 0
            ? 'Today!'
            : daysLeft == 1
                ? 'Tomorrow!'
                : '$daysLeft days';

    const double deleteWidth = 48;
    return GestureDetector(
      onTap: id.isEmpty ? null : () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(id: id)),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(color: Color(0x1Af15991), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              (constraints.maxWidth - imgSize - 12 - deleteWidth).clamp(60.0, double.infinity);
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lime left accent stripe
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // Thumbnail — stretches to match content height
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: CachedNetworkImage(
                    imageUrl: image,
                    width: imgSize,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        SizedBox(width: imgSize, height: imgSize, child: Container(color: Colors.white10)),
                    errorWidget: (_, __, ___) => SizedBox(
                      width: imgSize,
                      height: imgSize,
                      child: Container(
                        color: AppTheme.surface,
                        alignment: Alignment.center,
                        child: Icon(Icons.music_note_rounded,
                            color: AppTheme.primary.withValues(alpha: 0.40),
                            size: AppResponsive.icon(context, 28).clamp(22.0, 28.0)),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                // Info — fixed width so IntrinsicHeight measures text correctly
                SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: AppResponsive.font(context, 13.5).clamp(12.0, 15.0),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (city.isNotEmpty) ...[
                          const Gap(3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 11, color: AppTheme.primaryLight),
                              const Gap(3),
                              Flexible(
                                child: Text(
                                  city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: AppResponsive.font(context, 11.5).clamp(10.0, 13.0),
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (genre.isNotEmpty || daysLeft != null) ...[
                          const Gap(6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (genre.isNotEmpty)
                                Flexible(child: _Chip(genre, color: AppTheme.primary)),
                              if (genre.isNotEmpty && daysLeft != null)
                                const Gap(6),
                              if (daysLeft != null)
                                _Chip(
                                  daysLabel,
                                  color: daysLeft <= 3
                                      ? AppTheme.accent
                                      : Colors.white24,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Remove button centered in the card height
                SizedBox(
                  width: deleteWidth,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.favorite_rounded,
                          color: AppTheme.primary.withValues(alpha: 0.90), size: 22),
                      onPressed: () async {
                        final user = ref.read(authStateProvider).asData?.value;
                        if (user == null) return;
                        await ref.read(favouritesServiceProvider).remove(user.uid, id);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: AppResponsive.font(context, 10).clamp(8.0, 11.0),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
