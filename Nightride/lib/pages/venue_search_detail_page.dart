import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/data/services/places_service.dart';
import 'package:nightride/data/services/yelp_service.dart';
import 'package:nightride/providers/home_providers.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF070707);
const _surface = Color(0xFF111111);
const _card    = Color(0xFF0F0F0F);
const _border  = Color(0xFF222222);
const _lime    = Color(0xFFDFFF2F);
const _pink    = Color(0xFFFF3D73);
const _teal    = Color(0xFF62D6C8);
const _cream   = Color(0xFFF3EAD6);
const _white   = Color(0xFFFAFAFA);
const _muted2  = Color(0xFF888888);

// ── Aggregated venue data ─────────────────────────────────────────────────────

class _VenueData {
  final String name;
  final String address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final double? lat;
  final double? lng;
  final double? rating;
  final int? reviewCount;
  final List<String> photos;
  final List<_Review> reviews;

  const _VenueData({
    required this.name,
    required this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.lat,
    this.lng,
    this.rating,
    this.reviewCount,
    this.photos = const [],
    this.reviews = const [],
  });

  bool get hasCoords => lat != null && lng != null;
}

class _Review {
  final String author;
  final int rating;
  final String text;
  const _Review({required this.author, required this.rating, required this.text});
}

// ── Page ──────────────────────────────────────────────────────────────────────

class VenueSearchDetailPage extends ConsumerStatefulWidget {
  const VenueSearchDetailPage({
    super.key,
    required this.venueName,
    this.userLat,
    this.userLng,
  });

  final String venueName;
  final double? userLat;
  final double? userLng;

  @override
  ConsumerState<VenueSearchDetailPage> createState() =>
      _VenueSearchDetailPageState();
}

class _VenueSearchDetailPageState
    extends ConsumerState<VenueSearchDetailPage> {
  _VenueData? _venue;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      double? lat = widget.userLat;
      double? lng = widget.userLng;
      if (lat == null || lng == null) {
        final pos = ref.read(userLocationProvider).asData?.value;
        lat = pos?.latitude;
        lng = pos?.longitude;
      }

      final futures = await Future.wait([
        PlacesService.searchByText(
          widget.venueName,
          lat: lat,
          lng: lng,
          radiusMeters: 30000,
        ),
        YelpService.findByName(widget.venueName, lat ?? 0, lng ?? 0),
      ]);

      final osmResult = futures[0] as PlaceSearchResult?;
      final yelpBiz  = futures[1] as YelpBusiness?;

      PlaceDetails? details;
      List<YelpReview> yelpReviews = [];

      await Future.wait([
        if (osmResult != null)
          PlacesService.getDetails(osmResult.placeId).then((d) => details = d),
        if (yelpBiz != null)
          YelpService.getReviews(yelpBiz.yelpId).then((r) => yelpReviews = r),
      ]);

      final venueLat = details?.lat ?? osmResult?.lat ?? yelpBiz?.lat;
      final venueLng = details?.lng ?? osmResult?.lng ?? yelpBiz?.lng;

      final photos = <String>{
        ...?details?.photoUrls,
        ...?yelpBiz?.photoUrls,
      }.where((u) => u.isNotEmpty).take(12).toList();

      final reviews = yelpReviews.map((r) => _Review(
        author: r.authorName,
        rating: r.rating,
        text:   r.text,
      )).toList();

      setState(() {
        _venue = _VenueData(
          name:         widget.venueName,
          address:      details?.address ?? osmResult?.address ?? '',
          phone:        details?.phoneNumber,
          website:      details?.website,
          openingHours: details?.weekdayText?.isNotEmpty == true
              ? details!.weekdayText!.first
              : null,
          lat:          venueLat,
          lng:          venueLng,
          rating:       yelpBiz?.rating,
          reviewCount:  yelpBiz?.reviewCount,
          photos:       photos,
          reviews:      reviews,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Share helpers ─────────────────────────────────────────────────────────

  String _mapsUrl(_VenueData v) => v.hasCoords
      ? 'https://www.google.com/maps/search/?api=1&query=${v.lat},${v.lng}'
      : 'https://www.google.com/maps/search/${Uri.encodeComponent(v.name)}';

  void _share() {
    final v = _venue;
    if (v == null) return;
    Share.share(
      '🎉 Check out ${v.name}!\n'
      '${v.address.isNotEmpty ? "📍 ${v.address}\n" : ""}'
      '\n${_mapsUrl(v)}\n\n'
      'Found on Night Rite App 🌙',
      subject: v.name,
    );
  }

  void _copyLink() {
    final v = _venue;
    if (v == null) return;
    Clipboard.setData(ClipboardData(text: _mapsUrl(v)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Link copied!',
          style: GoogleFonts.poppins(color: _bg, fontSize: 13)),
      backgroundColor: _lime,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _Loader();
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);
    if (_venue == null) return const SizedBox.shrink();

    final v = _venue!;
    final heroH = v.photos.isNotEmpty ? 300.0 : (v.hasCoords ? 260.0 : 100.0);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: heroH,
            pinned: true,
            backgroundColor: _bg,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _white, size: 18),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _share,
                tooltip: 'Share',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.share_rounded,
                      color: _lime, size: 18),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 60, 12),
              title: Text(
                v.name.toUpperCase(),
                style: GoogleFonts.anton(
                  color: _white, fontSize: 15, letterSpacing: 0.8,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 8)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: _HeroBackground(venue: v),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Rating
                  if (v.rating != null) ...[
                    _RatingRow(rating: v.rating!, reviewCount: v.reviewCount),
                    const Gap(20),
                  ],

                  // Info card
                  _InfoCard(venue: v),
                  const Gap(16),

                  // Action row: Directions | Share | Copy Link
                  _ActionRow(
                    venue: v,
                    onShare: _share,
                    onCopy: _copyLink,
                    mapsUrl: _mapsUrl(v),
                  ),
                  const Gap(28),

                  // Photos
                  if (v.photos.length > 1) ...[
                    _SectionLabel(label: 'PHOTOS'),
                    const Gap(10),
                    _PhotoStrip(photos: v.photos),
                    const Gap(28),
                  ],

                  // Map preview (when no photos AND has coords)
                  if (v.photos.isEmpty && v.hasCoords) ...[
                    _SectionLabel(label: 'LOCATION'),
                    const Gap(10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 180,
                        child: _MiniMap(lat: v.lat!, lng: v.lng!),
                      ),
                    ),
                    const Gap(28),
                  ],

                  // Events
                  _SectionLabel(label: 'EVENTS'),
                  const Gap(10),
                  _EventsCard(venue: v),
                  const Gap(28),

                  // Reviews
                  if (v.reviews.isNotEmpty) ...[
                    _SectionLabel(label: 'REVIEWS'),
                    const Gap(10),
                    ...v.reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(review: r),
                    )),
                    const Gap(12),
                  ],

                  // Share card
                  _ShareCard(
                    onShare: _share,
                    onCopy: _copyLink,
                    venueName: v.name,
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

// ── Hero background ───────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.venue});
  final _VenueData venue;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (venue.photos.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: venue.photos.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: _surface),
        errorWidget: (_, __, ___) => venue.hasCoords
            ? _MiniMap(lat: venue.lat!, lng: venue.lng!)
            : Container(color: _surface),
      );
    } else if (venue.hasCoords) {
      content = _MiniMap(lat: venue.lat!, lng: venue.lng!);
    } else {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
        ),
      );
    }

    return Stack(fit: StackFit.expand, children: [
      content,
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33000000), Color(0xCC070707)],
          ),
        ),
      ),
    ]);
  }
}

// ── Mini map ──────────────────────────────────────────────────────────────────

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.lat, required this.lng});
  final double lat, lng;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(lat, lng),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.therisetechvillage.nightride',
        ),
        MarkerLayer(markers: [
          Marker(
            point: LatLng(lat, lng),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_pin, color: _pink, size: 44),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 14, color: _lime,
          margin: const EdgeInsets.only(right: 8)),
      Text(label,
          style: GoogleFonts.anton(
              color: _lime, fontSize: 12, letterSpacing: 1.5)),
      const Gap(8),
      Expanded(child: Container(height: 1, color: _border)),
    ]);
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, this.reviewCount});
  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ...List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded, color: _lime, size: 20);
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded, color: _lime, size: 20);
        }
        return const Icon(Icons.star_outline_rounded,
            color: _muted2, size: 20);
      }),
      const Gap(8),
      Text(rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
              color: _lime, fontSize: 16, fontWeight: FontWeight.w900)),
      if (reviewCount != null) ...[
        const Gap(6),
        Text('($reviewCount reviews)',
            style: GoogleFonts.poppins(color: _muted2, fontSize: 13)),
      ],
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.venue});
  final _VenueData venue;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (venue.address.isNotEmpty)
        _InfoRow(icon: Icons.location_on_rounded, color: _pink,
            text: venue.address),
      if (venue.openingHours != null)
        _InfoRow(icon: Icons.access_time_rounded, color: _lime,
            text: venue.openingHours!),
      if (venue.phone != null)
        _InfoRow(icon: Icons.phone_rounded, color: _teal, text: venue.phone!,
            onTap: () => launchUrl(Uri.parse('tel:${venue.phone}'))),
      if (venue.website != null)
        _InfoRow(icon: Icons.language_rounded, color: _teal,
            text: venue.website!,
            onTap: () => launchUrl(Uri.parse(venue.website!),
                mode: LaunchMode.externalApplication)),
    ];

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _muted2, size: 18),
          const Gap(10),
          Expanded(
            child: Text(
              'No details found in OpenStreetMap yet. '
              'Use the actions below to search Google Maps.',
              style: GoogleFonts.poppins(
                  color: _muted2, fontSize: 13, height: 1.5),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .expand((w) => [w, const Divider(color: _border, height: 18)])
            .toList()..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon, required this.color,
    required this.text, this.onTap,
  });
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const Gap(10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                color: onTap != null ? color : _white.withValues(alpha: 0.85),
                fontSize: 13, height: 1.45,
                decoration:
                    onTap != null ? TextDecoration.underline : null,
              )),
        ),
      ],
    );
    return onTap != null
        ? GestureDetector(onTap: onTap, child: content)
        : content;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.venue, required this.onShare,
    required this.onCopy, required this.mapsUrl,
  });
  final _VenueData venue;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final String mapsUrl;

  void _openMaps() {
    final url = venue.hasCoords
        ? 'https://www.google.com/maps/dir/?api=1&destination=${venue.lat},${venue.lng}'
        : 'https://www.google.com/maps/search/${Uri.encodeComponent(venue.name)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ActionBtn(
        icon: Icons.directions_rounded,
        label: 'DIRECTIONS',
        filled: true,
        onTap: _openMaps,
      )),
      const Gap(10),
      Expanded(child: _ActionBtn(
        icon: Icons.share_rounded,
        label: 'SHARE',
        onTap: onShare,
      )),
      const Gap(10),
      Expanded(child: _ActionBtn(
        icon: Icons.link_rounded,
        label: 'COPY LINK',
        onTap: onCopy,
      )),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon, required this.label,
    required this.onTap, this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _lime : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: filled ? _lime : _border, width: filled ? 0 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? _bg : _lime, size: 20),
            const Gap(5),
            Text(label,
                style: GoogleFonts.anton(
                    color: filled ? _bg : _lime,
                    fontSize: 9, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const Gap(10),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: photos[i],
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(width: 200, color: _surface),
            errorWidget: (_, __, ___) =>
                Container(width: 200, color: _surface),
          ),
        ),
      ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.venue});
  final _VenueData venue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                color: _muted2, size: 15),
            const Gap(8),
            Text('No live events in database',
                style: GoogleFonts.poppins(
                    color: _white, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const Gap(8),
          Text(
            "Check the venue's own Instagram or website for tonight's lineup.",
            style: GoogleFonts.poppins(
                color: _muted2, fontSize: 12, height: 1.5),
          ),
          const Gap(12),
          GestureDetector(
            onTap: () {
              final url =
                  'https://www.google.com/search?q=${Uri.encodeComponent("${venue.name} events tonight")}';
              launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _lime.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.search_rounded,
                    color: _lime, size: 14),
                const Gap(6),
                Text('Search events tonight',
                    style: GoogleFonts.poppins(
                        color: _lime, fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.onShare, required this.onCopy,
    required this.venueName,
  });
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final String venueName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lime.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lime.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.share_rounded, color: _lime, size: 16),
            const Gap(8),
            Text('Share this venue',
                style: GoogleFonts.poppins(
                    color: _lime, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const Gap(6),
          Text(
            'Send "$venueName" to friends via WhatsApp, Instagram, or any app.',
            style: GoogleFonts.poppins(
                color: _muted2, fontSize: 12, height: 1.5),
          ),
          const Gap(12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onShare,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('SHARE NOW',
                        style: GoogleFonts.anton(
                            color: _bg, fontSize: 11,
                            letterSpacing: 1)),
                  ),
                ),
              ),
            ),
            const Gap(10),
            Expanded(
              child: GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _lime.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text('COPY LINK',
                        style: GoogleFonts.anton(
                            color: _lime, fontSize: 11,
                            letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _lime.withValues(alpha: 0.12),
              child: Text(
                review.author.isNotEmpty
                    ? review.author[0].toUpperCase() : '?',
                style: GoogleFonts.anton(color: _lime, fontSize: 13),
              ),
            ),
            const Gap(10),
            Expanded(
              child: Text(review.author,
                  style: GoogleFonts.poppins(
                      color: _cream, fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            Row(
              children: List.generate(5, (i) => Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < review.rating ? _lime : _muted2,
                size: 13,
              )),
            ),
          ]),
          if (review.text.isNotEmpty) ...[
            const Gap(10),
            Text(review.text,
                style: GoogleFonts.poppins(
                    color: _white, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                  color: _lime, strokeWidth: 2),
            ),
            const Gap(16),
            Text('Finding venue...',
                style: GoogleFonts.poppins(
                    color: _muted2, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _muted2, size: 44),
              const Gap(16),
              Text('Could not load venue details.',
                  style: GoogleFonts.poppins(
                      color: _muted2, fontSize: 14)),
              const Gap(12),
              TextButton(
                onPressed: onRetry,
                child: Text('Retry',
                    style: GoogleFonts.poppins(
                        color: _lime,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
