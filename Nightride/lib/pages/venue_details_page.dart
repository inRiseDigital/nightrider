import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/core/config/maps_config.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _black      = Color(0xFF070707);
const _darkGray   = Color(0xFF151515);
const _borderGray = Color(0xFF333333);
const _cream      = Color(0xFFF3EAD6);
const _neonLime   = Color(0xFFDFFF2F);
const _hotPink    = Color(0xFFFF3D73);
const _teal       = Color(0xFF62D6C8);
const _white      = Color(0xFFFAFAFA);

// ── Page ──────────────────────────────────────────────────────────────────────

class VenueDetailsPage extends ConsumerWidget {
  const VenueDetailsPage({super.key, required this.data});

  final MapBottomCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs  = ref.watch(favouritesStreamProvider).asData?.value ?? [];
    final liked = favs.any((f) => f['id'] == data.id);
    final userPos = ref.watch(userLocationProvider).asData?.value;

    final double km = (userPos != null && data.lat != 0 && data.lng != 0)
        ? haversineKm(userPos.latitude, userPos.longitude, data.lat, data.lng)
        : 0;

    final distLabel  = formatDistance(km);
    final travelLabel = formatTravel(km);

    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: kGoogleMapsApiKey,
    );
    final staticMapUrl =
        (mapsKey.isNotEmpty &&
                mapsKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE' &&
                data.lat != 0 &&
                data.lng != 0)
            ? 'https://maps.googleapis.com/maps/api/staticmap'
                '?center=${data.lat},${data.lng}&zoom=14&size=600x280&scale=2'
                '&markers=color:0xDFFF2F%7C${data.lat},${data.lng}'
                '&style=feature:all%7Celement:geometry%7Ccolor:0x070707'
                '&style=feature:water%7Celement:geometry%7Ccolor:0x0F0F0F'
                '&style=feature:road%7Celement:geometry%7Ccolor:0x151515'
                '&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x444444'
                '&style=feature:poi%7Celement:labels%7Cvisibility:off'
                '&key=$mapsKey'
            : '';

    final screenH = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _black,
        body: Stack(
          children: [
            // ── Scrollable body ─────────────────────────────────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Hero image ──────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: screenH * 0.44,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _black,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Hero image
                        Hero(
                          tag: 'venue_image_${data.title}',
                          child: Image.network(
                            data.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: _darkGray),
                          ),
                        ),
                        // Gradient overlay — dark top + heavy bottom fade to black
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.30, 0.60, 0.82, 1.0],
                              colors: [
                                Color(0x88070707),
                                Color(0x00070707),
                                Color(0x44070707),
                                Color(0xCC070707),
                                Color(0xFF070707),
                              ],
                            ),
                          ),
                        ),
                        // Back button
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: _GlassIconButton(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: _white,
                                    size: 18),
                              ),
                            ),
                          ),
                        ),
                        // Favourite button
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16, top: 8),
                              child: _GlassIconButton(
                                onTap: () async {
                                  final user =
                                      ref.read(authStateProvider).asData?.value;
                                  if (user == null) return;
                                  final svc =
                                      ref.read(favouritesServiceProvider);
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
                                child: Icon(
                                  liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: liked ? _hotPink : _white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Retro VENUE label on hero
                        Positioned(
                          bottom: 72,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _neonLime,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VENUE',
                              style: GoogleFonts.anton(
                                color: _black,
                                fontSize: 10,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cream ticket card ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.only(top: -(screenH * 0.055)),
                    decoration: const BoxDecoration(
                      color: _cream,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Ticket notch tear-off ──────────────────────────
                        _TicketNotchRow(),
                        const Gap(4),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category pill + distance badge row
                              Row(
                                children: [
                                  _Pill(
                                    label: data.subtitle.toUpperCase(),
                                    bg: _hotPink,
                                    fg: _white,
                                  ),
                                  if (distLabel.isNotEmpty) ...[
                                    const Gap(8),
                                    _Pill(
                                      label: distLabel,
                                      bg: _teal,
                                      fg: _black,
                                      icon: Icons.near_me_rounded,
                                    ),
                                  ],
                                  if (travelLabel.isNotEmpty) ...[
                                    const Gap(8),
                                    _Pill(
                                      label: travelLabel,
                                      bg: _black.withValues(alpha: 0.08),
                                      fg: _black.withValues(alpha: 0.6),
                                      border: _borderGray.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ],
                              ),
                              const Gap(14),

                              // Venue name
                              Text(
                                data.title.toUpperCase(),
                                style: GoogleFonts.anton(
                                  color: _black,
                                  fontSize: AppResponsive.font(context, 32)
                                      .clamp(24.0, 40.0),
                                  height: 1.0,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Gap(16),

                              // Dashed separator
                              _DashedDivider(
                                  color: _black.withValues(alpha: 0.18)),
                              const Gap(16),

                              // Hours row
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded,
                                      color: _hotPink, size: 17),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      data.openText,
                                      style: TextStyle(
                                        color: _black,
                                        fontSize:
                                            AppResponsive.font(context, 13)
                                                .clamp(11.5, 14.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (data.priceHint.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _neonLime,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        data.priceHint,
                                        style: GoogleFonts.anton(
                                          color: _black,
                                          fontSize:
                                              AppResponsive.font(context, 11)
                                                  .clamp(10.0, 13.0),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(12),

                              // Address row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: _hotPink, size: 18),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      data.locationLine,
                                      style: TextStyle(
                                        color: _black.withValues(alpha: 0.72),
                                        fontSize:
                                            AppResponsive.font(context, 13)
                                                .clamp(11.5, 14.5),
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(24),

                              // ── Location section ──────────────────────────
                              _DashedDivider(
                                  color: _black.withValues(alpha: 0.18)),
                              const Gap(20),

                              Text(
                                'LOCATION',
                                style: GoogleFonts.anton(
                                  color: _black,
                                  fontSize: AppResponsive.font(context, 14)
                                      .clamp(12.0, 16.0),
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const Gap(12),

                              // Static map
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: staticMapUrl.isNotEmpty
                                      ? Image.network(
                                          staticMapUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, prog) =>
                                              prog == null
                                                  ? child
                                                  : Container(
                                                      color: _darkGray,
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: _neonLime,
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                          errorBuilder: (_, __, ___) =>
                                              _MapFallback(data: data),
                                        )
                                      : _MapFallback(data: data),
                                ),
                              ),
                              const Gap(24),

                              // ── Features & Vibes section ──────────────────
                              if (data.tags.isNotEmpty) ...[
                                _DashedDivider(
                                    color: _black.withValues(alpha: 0.18)),
                                const Gap(20),

                                Text(
                                  'FEATURES & VIBES',
                                  style: GoogleFonts.anton(
                                    color: _black,
                                    fontSize: AppResponsive.font(context, 14)
                                        .clamp(12.0, 16.0),
                                    letterSpacing: 2.5,
                                  ),
                                ),
                                const Gap(14),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: data.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 9),
                                          decoration: BoxDecoration(
                                            color: _black,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: _borderGray,
                                                width: 0.8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.music_note_rounded,
                                                  color: _neonLime,
                                                  size: 12),
                                              const Gap(6),
                                              Text(
                                                tag.toUpperCase(),
                                                style: TextStyle(
                                                  color: _white,
                                                  fontSize: AppResponsive.font(
                                                          context, 11)
                                                      .clamp(10.0, 13.0),
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const Gap(24),
                              ],

                              // Bottom padding for the action bar
                              const Gap(96),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom action bar ────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
                decoration: BoxDecoration(
                  color: _cream,
                  border: Border(
                      top: BorderSide(
                          color: _black.withValues(alpha: 0.14), width: 1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, -6)),
                  ],
                ),
                child: Row(
                  children: [
                    // Admission block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ADMISSION',
                          style: TextStyle(
                            color: _black.withValues(alpha: 0.42),
                            fontSize:
                                AppResponsive.font(context, 9).clamp(8.0, 10.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          data.priceHint.isNotEmpty ? data.priceHint : 'FREE',
                          style: GoogleFonts.anton(
                            color: _black,
                            fontSize: AppResponsive.font(context, 22)
                                .clamp(18.0, 26.0),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    // CTA button
                    Expanded(
                      child: _CtaButton(
                        label: 'GET DIRECTIONS',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.border,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border!, width: 0.8) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: 12),
            const Gap(4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _neonLime,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _neonLime.withValues(alpha: 0.38),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.anton(
              color: _black,
              fontSize: AppResponsive.font(context, 15).clamp(13.0, 17.0),
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ticket notch tear-off row ─────────────────────────────────────────────────

class _TicketNotchRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          // Left notch — black half-circle
          Container(
            width: 13,
            height: 26,
            decoration: const BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
          ),
          // Dashed perforations
          Expanded(child: _PerforationLine()),
          // Right notch — black half-circle
          Container(
            width: 13,
            height: 26,
            decoration: const BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perforation dashed line (horizontal) ──────────────────────────────────────

class _PerforationLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final count = (c.maxWidth / 9).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (_) => Container(
            width: 4,
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            color: _black.withValues(alpha: 0.25),
          ),
        ),
      );
    });
  }
}

// ── Dashed section divider ────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _black.withValues(alpha: 0.2);
    return LayoutBuilder(builder: (_, constraints) {
      final count = (constraints.maxWidth / 10).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: c,
            ),
          ),
        ),
      );
    });
  }
}

// ── Map fallback placeholder ──────────────────────────────────────────────────

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.data});
  final MapBottomCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkGray,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, color: _neonLime, size: 42),
          const Gap(10),
          Text(
            data.locationLine,
            style: TextStyle(
              color: _white.withValues(alpha: 0.55),
              fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
