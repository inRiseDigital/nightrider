import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/services/places_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _black      = Color(0xFF070707);
const _darkGray   = Color(0xFF151515);
const _cream      = Color(0xFFF3EAD6);
const _neonLime   = Color(0xFFDFFF2F);
const _hotPink    = Color(0xFFFF3D73);
const _teal       = Color(0xFF62D6C8);
const _white      = Color(0xFFFAFAFA);
const _starAmber  = Color(0xFFFFA726);

// ── Page ──────────────────────────────────────────────────────────────────────

class PlaceDetailsPage extends StatefulWidget {
  final String placeId;
  final String? initialName;

  const PlaceDetailsPage({
    super.key,
    required this.placeId,
    this.initialName,
  });

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  PlaceDetails? _details;
  bool _loading = true;
  String? _error;
  int  _carouselIndex = 0;
  bool _hoursExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final d = await PlacesService.getDetails(widget.placeId);
    if (!mounted) return;
    if (d == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load place details.';
      });
    } else {
      setState(() {
        _loading = false;
        _details = d;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _black,
        body: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _neonLime, strokeWidth: 2),
          const Gap(20),
          Text(
            (widget.initialName ?? 'Loading…').toUpperCase(),
            style: GoogleFonts.anton(
              color: _white.withValues(alpha: 0.5),
              fontSize: 15,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: _hotPink, size: 52),
              const Gap(16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _white.withValues(alpha: 0.5), fontSize: 15),
              ),
              const Gap(24),
              _NeonButton(
                label: 'TRY AGAIN',
                onTap: _load,
              ),
              const Gap(12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'GO BACK',
                  style: GoogleFonts.poppins(
                    color: _white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent() {
    final d = _details!;
    final screenH = MediaQuery.of(context).size.height;
    final hasPhotos = d.photoUrls.isNotEmpty;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero / photo carousel app bar ────────────────────────────
            SliverAppBar(
              expandedHeight: hasPhotos ? screenH * 0.44 : screenH * 0.20,
              pinned: true,
              stretch: true,
              backgroundColor: _black,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: hasPhotos
                    ? _PhotoCarousel(
                        urls: d.photoUrls,
                        currentIndex: _carouselIndex,
                        onPageChanged: (i) =>
                            setState(() => _carouselIndex = i),
                        onPhotoTap: (i) => _openGallery(d.photoUrls, i),
                      )
                    : _NoPhotoBanner(),
              ),
            ),

            // ── Cream ticket card ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(top: -(screenH * 0.06)),
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
                    // Back button row inside cream — overlaps hero
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 12, bottom: 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _GlassIconButton(
                          dark: false,
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: _black, size: 17),
                        ),
                      ),
                    ),

                    // Ticket notch tear-off
                    _TicketNotchRow(),
                    const Gap(4),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Type badge + open badge row ─────────────────
                          Row(
                            children: [
                              if (d.openNow != null)
                                _OpenBadge(openNow: d.openNow!),
                              if (d.openNow != null) const Gap(8),
                              // Photo count badge
                              if (hasPhotos)
                                _Pill(
                                  label:
                                      '${d.photoUrls.length} PHOTOS',
                                  bg: _teal,
                                  fg: _black,
                                  icon: Icons.photo_library_rounded,
                                ),
                            ],
                          ),
                          const Gap(14),

                          // Place name
                          Text(
                            d.name.toUpperCase(),
                            style: GoogleFonts.anton(
                              color: _black,
                              fontSize: AppResponsive.font(context, 30)
                                  .clamp(22.0, 38.0),
                              height: 1.0,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Gap(12),

                          // Rating row
                          if (d.rating != null)
                            _RatingRow(
                              rating: d.rating!,
                              total: d.userRatingsTotal,
                            ),

                          const Gap(18),

                          // Dashed separator
                          _DashedDivider(
                              color: _black.withValues(alpha: 0.18)),
                          const Gap(16),

                          // ── Info tiles ──────────────────────────────────
                          if (d.address.isNotEmpty) ...[
                            _InfoTile(
                              icon: Icons.location_on_rounded,
                              iconColor: _hotPink,
                              text: d.address,
                              trailingIcon: Icons.copy_rounded,
                              trailingColor: _black.withValues(alpha: 0.4),
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: d.address));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: _darkGray,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    content: Text('Address copied',
                                        style:
                                            TextStyle(color: _white)),
                                  ),
                                );
                              },
                            ),
                            const Gap(10),
                          ],

                          if (d.phoneNumber != null) ...[
                            _InfoTile(
                              icon: Icons.phone_rounded,
                              iconColor: _teal,
                              text: d.phoneNumber!,
                              trailingIcon: Icons.call_rounded,
                              trailingColor: _teal,
                              onTap: () =>
                                  _openUrl('tel:${d.phoneNumber}'),
                            ),
                            const Gap(10),
                          ],

                          if (d.website != null) ...[
                            _InfoTile(
                              icon: Icons.language_rounded,
                              iconColor: _black.withValues(alpha: 0.5),
                              text: _shortenUrl(d.website!),
                              trailingIcon: Icons.open_in_new_rounded,
                              trailingColor: _hotPink,
                              onTap: () => _openUrl(d.website!),
                            ),
                            const Gap(10),
                          ],

                          // ── Opening hours ───────────────────────────────
                          if (d.weekdayText != null &&
                              d.weekdayText!.isNotEmpty) ...[
                            const Gap(14),
                            _DashedDivider(
                                color: _black.withValues(alpha: 0.18)),
                            const Gap(16),
                            _HoursSection(
                              weekdayText: d.weekdayText!,
                              expanded: _hoursExpanded,
                              onToggle: () => setState(
                                  () => _hoursExpanded = !_hoursExpanded),
                            ),
                          ],

                          // ── Photo strip ─────────────────────────────────
                          if (d.photoUrls.isNotEmpty) ...[
                            const Gap(20),
                            _DashedDivider(
                                color: _black.withValues(alpha: 0.18)),
                            const Gap(16),
                            _PhotoStrip(
                              urls: d.photoUrls,
                              onTap: (i) => _openGallery(d.photoUrls, i),
                            ),
                          ],

                          // ── Reviews ─────────────────────────────────────
                          if (d.reviews.isNotEmpty) ...[
                            const Gap(20),
                            _DashedDivider(
                                color: _black.withValues(alpha: 0.18)),
                            const Gap(16),
                            _ReviewsSection(reviews: d.reviews),
                          ],

                          const Gap(110),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Bottom CTA bar ─────────────────────────────────────────────────
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
                // Rating recap
                if (_details?.rating != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RATING',
                        style: TextStyle(
                          color: _black.withValues(alpha: 0.42),
                          fontSize: AppResponsive.font(context, 9)
                              .clamp(8.0, 10.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Gap(2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: _starAmber, size: 18),
                          const Gap(4),
                          Text(
                            _details!.rating!.toStringAsFixed(1),
                            style: GoogleFonts.anton(
                              color: _black,
                              fontSize: AppResponsive.font(context, 22)
                                  .clamp(18.0, 26.0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(16),
                ],
                Expanded(
                  child: _NeonButton(
                    label: 'EXPLORE',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  void _openGallery(List<String> urls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenGallery(urls: urls, initialIndex: index),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.length > 28
          ? '${uri.path.substring(0, 28)}…'
          : uri.path;
      return uri.host + (path == '/' ? '' : path);
    } catch (_) {
      return url.length > 40 ? '${url.substring(0, 40)}…' : url;
    }
  }
}

// ── Photo carousel (hero area) ────────────────────────────────────────────────

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({
    required this.urls,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onPhotoTap,
  });
  final List<String> urls;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Page view
        PageView.builder(
          itemCount: urls.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => onPhotoTap(i),
            child: CachedNetworkImage(
              imageUrl: urls[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF151515)),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF151515),
                child: const Icon(Icons.image_not_supported_rounded,
                    color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        // Bottom fade to cream
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF070707), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Dot indicators
        if (urls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == currentIndex ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? _neonLime
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ── No-photo fallback banner ──────────────────────────────────────────────────

class _NoPhotoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F0F), Color(0xFF151515)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.place_rounded, size: 58, color: Colors.white10),
      ),
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, this.total});
  final double rating;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            if (i < rating.floor()) {
              return const Icon(Icons.star_rounded,
                  color: _starAmber, size: 17);
            } else if (i < rating) {
              return const Icon(Icons.star_half_rounded,
                  color: _starAmber, size: 17);
            } else {
              return Icon(Icons.star_outline_rounded,
                  color: _black.withValues(alpha: 0.22), size: 17);
            }
          }),
        ),
        const Gap(8),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.anton(
            color: _black,
            fontSize: 15,
          ),
        ),
        if (total != null) ...[
          const Gap(6),
          Text(
            '(${_fmtCount(total!)} reviews)',
            style: TextStyle(
              color: _black.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  static String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ── Open/Closed badge ─────────────────────────────────────────────────────────

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.openNow});
  final bool openNow;

  @override
  Widget build(BuildContext context) {
    final color = openNow ? const Color(0xFF2ECC71) : _hotPink;
    final label = openNow ? 'OPEN NOW' : 'CLOSED';
    final icon  = openNow
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const Gap(5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile (address / phone / website) ─────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.trailingIcon,
    this.trailingColor,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String text;
  final IconData? trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _black.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _black.withValues(alpha: 0.12), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 19),
            const Gap(12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: _black,
                  fontSize: AppResponsive.font(context, 13)
                      .clamp(11.5, 14.5),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null) ...[
              const Gap(10),
              Icon(trailingIcon, color: trailingColor ?? iconColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Opening hours section ─────────────────────────────────────────────────────

class _HoursSection extends StatelessWidget {
  const _HoursSection({
    required this.weekdayText,
    required this.expanded,
    required this.onToggle,
  });
  final List<String> weekdayText;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final today = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ][DateTime.now().weekday - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(Icons.access_time_filled_rounded,
                  color: _hotPink, size: 18),
              const Gap(10),
              Text(
                'OPENING HOURS',
                style: GoogleFonts.anton(
                  color: _black,
                  fontSize: AppResponsive.font(context, 14)
                      .clamp(12.0, 16.0),
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _black.withValues(alpha: 0.45),
                size: 24,
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _black.withValues(alpha: 0.12), width: 0.8),
            ),
            child: Column(
              children: weekdayText.map((line) {
                final colon = line.indexOf(':');
                final day   = colon > 0 ? line.substring(0, colon) : line;
                final hrs   =
                    colon > 0 ? line.substring(colon + 1).trim() : '';
                final isToday =
                    day.trim().toLowerCase() == today.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 106,
                        child: Text(
                          day.trim(),
                          style: TextStyle(
                            color: isToday ? _hotPink : _black.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          hrs,
                          style: TextStyle(
                            color: isToday
                                ? _black
                                : _black.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _neonLime,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Photo thumbnail strip ─────────────────────────────────────────────────────

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls, required this.onTap});
  final List<String> urls;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTOS',
          style: GoogleFonts.anton(
            color: _black,
            fontSize: AppResponsive.font(context, 14).clamp(12.0, 16.0),
            letterSpacing: 2.0,
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onTap(i),
              child: Hero(
                tag: 'place_photo_$i',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: urls[i],
                    width: 170,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 170, height: 130, color: _darkGray),
                    errorWidget: (_, __, ___) => Container(
                      width: 170,
                      height: 130,
                      color: _darkGray,
                      child: const Icon(Icons.image_not_supported_rounded,
                          color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});
  final List<PlaceReview> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REVIEWS',
          style: GoogleFonts.anton(
            color: _black,
            fontSize: AppResponsive.font(context, 14).clamp(12.0, 16.0),
            letterSpacing: 2.0,
          ),
        ),
        const Gap(14),
        ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final PlaceReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _black.withValues(alpha: 0.12), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _hotPink.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _hotPink.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(
                  child: Text(
                    review.authorName.isNotEmpty
                        ? review.authorName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.anton(
                      color: _hotPink,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const Gap(10),
              // Author + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        color: _black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      review.relativeTime,
                      style: TextStyle(
                        color: _black.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < review.rating
                        ? _starAmber
                        : _black.withValues(alpha: 0.18),
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const Gap(10),
            Text(
              review.text,
              style: TextStyle(
                color: _black.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.55,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.child,
    required this.onTap,
    this.dark = true,
  });
  final Widget child;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark
              ? Colors.black.withValues(alpha: 0.48)
              : _cream.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.14)
                : _black.withValues(alpha: 0.12),
          ),
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
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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

class _NeonButton extends StatelessWidget {
  const _NeonButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
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
          Expanded(child: _PerforationLine()),
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

// ── Fullscreen photo gallery ──────────────────────────────────────────────────

class _FullscreenGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullscreenGallery({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_index + 1} / ${widget.urls.length}',
          style: GoogleFonts.poppins(
            color: _white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: widget.urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Hero(
              tag: 'place_photo_$i',
              child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(
                    color: _neonLime, strokeWidth: 2),
                errorWidget: (_, __, ___) => const Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.white24,
                    size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
