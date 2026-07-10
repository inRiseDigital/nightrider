import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/core/config/maps_config.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:nightride/services/favourites_service.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
class _P {
  static const black     = Color(0xFF070707);
  static const surface   = Color(0xFF0F0F0F);
  static const darkGray  = Color(0xFF151515);
  static const borderGray= Color(0xFF333333);
  static const cream     = Color(0xFFF3EAD6);
  static const neonLime  = Color(0xFFDFFF2F);
  static const hotPink   = Color(0xFFFF3D73);
  static const teal      = Color(0xFF62D6C8);
  static const white     = Color(0xFFFAFAFA);
}

// ── Entry point ────────────────────────────────────────────────────────────────

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(id));

    return Scaffold(
      backgroundColor: _P.black,
      body: async.when(
        loading: () => const _LoadingBody(),
        error: (_, __) => const _ErrorBody(),
        data: (data) {
          if (data == null) return const _ErrorBody();
          return _DetailBody(data: data);
        },
      ),
    );
  }
}

// ── Loading ────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _P.black,
      body: Center(
        child: CircularProgressIndicator(color: _P.neonLime, strokeWidth: 2),
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CircleButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _P.white, size: 18),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Event not found',
                    style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.data});
  final Map<String, dynamic> data;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  // ── Field getters ─────────────────────────────────────────────────────────
  String get _id          => widget.data['id'] as String? ?? '';
  String get _name        => widget.data['name'] as String? ?? '';
  String get _coverImage  => widget.data['cover_image'] as String? ?? '';
  String get _genre       => widget.data['genre'] as String? ?? 'Music';
  String get _date        => widget.data['date'] as String? ?? '';
  String get _startTime   => widget.data['start_time'] as String? ?? '';
  String get _venueName   => widget.data['venue_name'] as String? ?? '';
  String get _address     => widget.data['address'] as String? ?? '';
  String get _city        => widget.data['city'] as String? ?? '';
  String get _country     => widget.data['country'] as String? ?? '';
  String get _priceHint   => widget.data['price_hint'] as String? ?? '';
  String get _description => widget.data['description'] as String? ?? '';
  String get _ticketUrl   => widget.data['ticket_url'] as String? ?? '';
  String get _language    => widget.data['language'] as String? ?? '';
  double get _lat         => (widget.data['lat'] as num? ?? 0).toDouble();
  double get _lng         => (widget.data['lng'] as num? ?? 0).toDouble();

  List<String> get _artists =>
      (widget.data['artists'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  List<Map<String, dynamic>> get _performers {
    final raw = widget.data['performers'] as List<dynamic>?;
    if (raw == null || raw.isEmpty) return [];
    return raw.whereType<Map>().map((p) => Map<String, dynamic>.from(p)).toList();
  }

  Map<String, dynamic> get _policies =>
      (widget.data['policies'] as Map<String, dynamic>?) ?? {};

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns e.g. "JUN 14" for the date badge circle
  String _formatDayMonth() {
    if (_date.isEmpty) return '';
    final parts = _date.split('-');
    if (parts.length < 3) return _date.toUpperCase();
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    final monthName = (m > 0 && m <= 12) ? months[m] : '';
    return '$monthName $d';
  }

  /// Returns formatted time e.g. "9:30PM"
  String _formatTime() {
    if (_startTime.isEmpty) return '';
    String t = _startTime.contains('T')
        ? _startTime.split('T').last
        : _startTime;
    // trim to HH:MM
    if (t.length >= 5) t = t.substring(0, 5);
    // parse and convert to 12h
    final colonIdx = t.indexOf(':');
    if (colonIdx < 0) return t.toUpperCase();
    final hh = int.tryParse(t.substring(0, colonIdx)) ?? 0;
    final mm = t.substring(colonIdx + 1);
    final ampm = hh >= 12 ? 'PM' : 'AM';
    final hour12 = hh % 12 == 0 ? 12 : hh % 12;
    return '$hour12:$mm$ampm';
  }

  Future<void> _openTickets() async {
    if (_ticketUrl.isEmpty) return;
    final uri = Uri.tryParse(_ticketUrl);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _share(BuildContext context) async {
    final text = _ticketUrl.isNotEmpty ? '$_name\n$_ticketUrl' : _name;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _P.surface,
          content: Text('Link copied to clipboard',
              style: TextStyle(color: _P.white)),
        ),
      );
    }
  }

  Future<void> _toggleFavourite(bool isCurrentlyFav) async {
    final svc = ref.read(favouritesServiceProvider);
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    if (isCurrentlyFav) {
      await svc.remove(user.uid, _id);
    } else {
      await svc.add(user.uid, {
        ...widget.data,
        'id': _id,
      });
    }
    ref.invalidate(isFavouriteProvider(_id));
    ref.invalidate(favouritesStreamProvider);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.42;
    // cream card overlaps hero by ~80px
    const cardOverlap = 80.0;

    final isFavAsync = ref.watch(isFavouriteProvider(_id));
    final isFav = isFavAsync.asData?.value ?? false;

    final favsAll = ref.watch(favouritesStreamProvider).asData?.value ?? [];
    final attendeeCount = widget.data['attendee_count'] as int?
        ?? (favsAll.isNotEmpty ? favsAll.length : null);

    const String mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: kGoogleMapsApiKey,
    );
    final String staticMapUrl =
        (mapsKey.isNotEmpty &&
                mapsKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE' &&
                _lat != 0 &&
                _lng != 0)
            ? 'https://maps.googleapis.com/maps/api/staticmap'
                '?center=$_lat,$_lng&zoom=14&size=600x260&scale=2'
                '&markers=color:0x9f7aea%7C$_lat,$_lng'
                '&style=feature:all%7Celement:geometry%7Ccolor:0x242f3e'
                '&style=feature:water%7Celement:geometry%7Ccolor:0x17263c'
                '&style=feature:road%7Celement:geometry%7Ccolor:0x38414e'
                '&key=$mapsKey'
            : '';

    final locationLine =
        [_city, _country].where((s) => s.isNotEmpty).join(', ');
    final addressLine =
        [_venueName, _address].where((s) => s.isNotEmpty).join(' · ');
    final priceLabel = _priceHint.isNotEmpty ? _priceHint.toUpperCase() : 'FREE';
    final dayMonth  = _formatDayMonth();
    final timeStr   = _formatTime();

    return Scaffold(
      backgroundColor: _P.black,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ───────────────────────────────────────────────
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _coverImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _coverImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: _P.darkGray),
                              errorWidget: (_, __, ___) =>
                                  Container(color: _P.darkGray),
                            )
                          : Container(color: _P.darkGray),
                      // Strong gradient toward bottom so cream card reads over it
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.40, 0.75, 1.0],
                            colors: [
                              Color(0x00070707),
                              Color(0x15070707),
                              Color(0xAA070707),
                              Color(0xFF070707),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Cream ticket card — overlaps hero ────────────────────────
                Transform.translate(
                  offset: const Offset(0, -cardOverlap),
                  child: Container(
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(
                      color: _P.cream,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Card main content ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Time badge + genre row ───────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Teal circle badge with date + time
                                  if (dayMonth.isNotEmpty || timeStr.isNotEmpty)
                                    _TimeBadge(
                                      dayMonth: dayMonth,
                                      time: timeStr,
                                    ),
                                  const Gap(12),
                                  // Genre pill
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: _GenrePill(genre: _genre),
                                  ),
                                ],
                              ),
                              const Gap(16),

                              // ── Event title ──────────────────────────────
                              Text(
                                _name.toUpperCase(),
                                style: GoogleFonts.anton(
                                  color: _P.black,
                                  fontSize: AppResponsive.font(context, 38)
                                      .clamp(30.0, 46.0),
                                  height: 0.95,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Gap(8),

                              // ── Address line ─────────────────────────────
                              if (addressLine.isNotEmpty ||
                                  locationLine.isNotEmpty)
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(Icons.location_on_rounded,
                                          color: _P.hotPink, size: 16),
                                    ),
                                    const Gap(5),
                                    Expanded(
                                      child: Text(
                                        [
                                          if (addressLine.isNotEmpty)
                                            addressLine,
                                          if (locationLine.isNotEmpty)
                                            locationLine,
                                        ].join(' · '),
                                        style: GoogleFonts.poppins(
                                          color: _P.black
                                              .withValues(alpha: 0.55),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                              const Gap(20),

                              // ── Dashed separator ─────────────────────────
                              _DashedDivider(
                                  color: _P.black.withValues(alpha: 0.18)),
                              const Gap(16),

                              // ── People going section ─────────────────────
                              if (attendeeCount != null &&
                                  attendeeCount > 0) ...[
                                Row(
                                  children: [
                                    Text(
                                      'PEOPLE GOING',
                                      style: GoogleFonts.poppins(
                                        color: _P.black
                                            .withValues(alpha: 0.40),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(8),
                                _PeopleGoingRow(count: attendeeCount),
                                const Gap(16),
                                _DashedDivider(
                                    color: _P.black.withValues(alpha: 0.12)),
                                const Gap(16),
                              ],

                              // ── Entry row ────────────────────────────────
                              Row(
                                children: [
                                  Text(
                                    'ENTRY',
                                    style: GoogleFonts.poppins(
                                      color: _P.black.withValues(alpha: 0.40),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.2,
                                    ),
                                  ),
                                  const Gap(14),
                                  Text(
                                    priceLabel,
                                    style: GoogleFonts.anton(
                                      color: _P.black,
                                      fontSize: 22,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(14),

                              // ── Language row ─────────────────────────────
                              if (_language.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.language_rounded,
                                        color:
                                            _P.black.withValues(alpha: 0.35),
                                        size: 15),
                                    const Gap(6),
                                    Text(
                                      _language.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color:
                                            _P.black.withValues(alpha: 0.50),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(14),
                              ],

                              // ── Perforated tear line ──────────────────────
                              _TicketTearLine(),
                              const Gap(10),

                              // ── Barcode strip ─────────────────────────────
                              _BarcodeStrip(
                                  color: _P.black.withValues(alpha: 0.50)),
                              const Gap(4),
                              Text(
                                'ADMIT ONE  ·  NIGHT RITE',
                                style: GoogleFonts.poppins(
                                  color: _P.black.withValues(alpha: 0.28),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.4,
                                ),
                              ),
                              const Gap(28),
                            ],
                          ),
                        ),

                        // ── Performers section ─────────────────────────────
                        if (_performers.isNotEmpty || _artists.isNotEmpty) ...[
                          _SectionDivider(),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 22, 22, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.performers
                                      .toUpperCase(),
                                  style: GoogleFonts.anton(
                                    color: _P.black,
                                    fontSize: AppResponsive.font(context, 18)
                                        .clamp(15.0, 20.0),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Gap(14),
                                if (_performers.isNotEmpty)
                                  Column(
                                    children: _performers.map((p) {
                                      final pName =
                                          p['name'] as String? ?? '';
                                      final type =
                                          p['type'] as String? ?? 'DJ';
                                      final bio =
                                          p['bio'] as String? ?? '';
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: _P.black
                                              .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _P.black
                                                .withValues(alpha: 0.10),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: _P.hotPink
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.mic_rounded,
                                                color: _P.hotPink,
                                                size: 20,
                                              ),
                                            ),
                                            const Gap(12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          pName,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: _P.black,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _P.teal
                                                              .withValues(
                                                                  alpha: 0.22),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          type.toUpperCase(),
                                                          style:
                                                              GoogleFonts.poppins(
                                                            color: const Color(
                                                                0xFF006B62),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (bio.isNotEmpty) ...[
                                                    const Gap(4),
                                                    Text(
                                                      bio,
                                                      style: GoogleFonts.poppins(
                                                        color: _P.black
                                                            .withValues(
                                                                alpha: 0.50),
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _artists
                                        .map((artist) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 9),
                                              decoration: BoxDecoration(
                                                color: _P.black
                                                    .withValues(alpha: 0.06),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _P.black
                                                      .withValues(alpha: 0.10),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.mic_rounded,
                                                      color: _P.hotPink,
                                                      size: 13),
                                                  const Gap(7),
                                                  Text(
                                                    artist,
                                                    style: GoogleFonts.poppins(
                                                      color: _P.black,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                const Gap(22),
                              ],
                            ),
                          ),
                        ],

                        // ── Event policies ─────────────────────────────────
                        if (_policies.isNotEmpty) ...[
                          _SectionDivider(),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 22, 22, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EVENT POLICIES',
                                  style: GoogleFonts.anton(
                                    color: _P.black,
                                    fontSize: AppResponsive.font(context, 18)
                                        .clamp(15.0, 20.0),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Gap(14),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _P.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _P.black.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      if ((_policies['age_restriction']
                                                  as int? ??
                                              0) >
                                          0) ...[
                                        _PolicyRow(
                                          icon: Icons.person_outline_rounded,
                                          iconColor: Colors.orangeAccent,
                                          label: 'Age Restriction',
                                          value:
                                              '${_policies['age_restriction']}+ only',
                                        ),
                                        _PolicyDivider(),
                                      ],
                                      if ((_policies['refund_policy']
                                                  as String? ??
                                              '')
                                          .isNotEmpty) ...[
                                        _PolicyRow(
                                          icon: Icons.receipt_long_rounded,
                                          iconColor: Colors.blue,
                                          label: 'Refund Policy',
                                          value: _policies['refund_policy']
                                              as String,
                                        ),
                                        _PolicyDivider(),
                                      ],
                                      _PolicyRow(
                                        icon: Icons.loop_rounded,
                                        iconColor:
                                            _policies['re_entry_allowed'] ==
                                                    true
                                                ? Colors.green
                                                : Colors.redAccent,
                                        label: 'Re-entry',
                                        value:
                                            _policies['re_entry_allowed'] ==
                                                    true
                                                ? 'Allowed'
                                                : 'Not allowed',
                                      ),
                                      _PolicyDivider(),
                                      _PolicyRow(
                                        icon: Icons.accessible_rounded,
                                        iconColor:
                                            _policies['wheelchair_accessible'] ==
                                                    true
                                                ? Colors.green
                                                : Colors.black38,
                                        label: 'Wheelchair Access',
                                        value:
                                            _policies['wheelchair_accessible'] ==
                                                    true
                                                ? 'Accessible'
                                                : 'Not specified',
                                      ),
                                      _PolicyDivider(),
                                      _PolicyRow(
                                        icon: Icons.pets_rounded,
                                        iconColor:
                                            _policies['allow_pets'] == true
                                                ? Colors.green
                                                : Colors.black38,
                                        label: 'Pets',
                                        value: _policies['allow_pets'] == true
                                            ? 'Allowed'
                                            : 'Not allowed',
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(22),
                              ],
                            ),
                          ),
                        ],

                        // ── About / description ────────────────────────────
                        if (_description.isNotEmpty) ...[
                          _SectionDivider(),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 22, 22, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.aboutThisEvent
                                      .toUpperCase(),
                                  style: GoogleFonts.anton(
                                    color: _P.black,
                                    fontSize: AppResponsive.font(context, 18)
                                        .clamp(15.0, 20.0),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Gap(12),
                                Text(
                                  _description,
                                  style: GoogleFonts.poppins(
                                    color: _P.black.withValues(alpha: 0.60),
                                    fontSize: AppResponsive.font(context, 14)
                                        .clamp(12.0, 15.0),
                                    height: 1.65,
                                  ),
                                ),
                                const Gap(22),
                              ],
                            ),
                          ),
                        ],

                        // ── Map ────────────────────────────────────────────
                        if (_lat != 0 && _lng != 0) ...[
                          _SectionDivider(),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(22, 22, 22, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.location
                                      .toUpperCase(),
                                  style: GoogleFonts.anton(
                                    color: _P.black,
                                    fontSize: AppResponsive.font(context, 18)
                                        .clamp(15.0, 20.0),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Gap(12),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(mapFocusProvider.notifier).state =
                                        MapFocus(_lat, _lng, label: _name);
                                    ref
                                        .read(appNavProvider.notifier)
                                        .setIndex(0);
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          height: 190,
                                          width: double.infinity,
                                          child: staticMapUrl.isNotEmpty
                                              ? Image.network(
                                                  staticMapUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (_, child, prog) =>
                                                          prog == null
                                                              ? child
                                                              : Container(
                                                                  color: _P
                                                                      .darkGray,
                                                                  child:
                                                                      const Center(
                                                                    child: CircularProgressIndicator(
                                                                        color: _P
                                                                            .teal,
                                                                        strokeWidth:
                                                                            2),
                                                                  ),
                                                                ),
                                                  errorBuilder: (_, __, ___) =>
                                                      _MapFallback(
                                                          locationLine:
                                                              locationLine),
                                                )
                                              : _MapFallback(
                                                  locationLine: locationLine),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _P.black
                                                  .withValues(alpha: 0.72),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                  color: _P.white
                                                      .withValues(alpha: 0.15)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.open_in_new_rounded,
                                                    color: _P.white,
                                                    size: 12),
                                                const Gap(5),
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .openInMaps,
                                                  style: GoogleFonts.poppins(
                                                    color: _P.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Gap(22),
                              ],
                            ),
                          ),
                        ],

                        // Bottom spacing for action bar
                        const SizedBox(height: 124),
                      ],
                    ),
                  ),
                ),

                // Collapse the overlap offset so scroll doesn't over-extend
                const SizedBox(height: 0 - cardOverlap),
              ],
            ),
          ),

          // ── Back button — top left ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _CircleButton(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _P.white, size: 18),
            ),
          ),

          // ── Share + Favourite — top right ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Column(
              children: [
                _CircleButton(
                  onTap: () => _share(context),
                  child: const Icon(Icons.ios_share_rounded,
                      color: _P.white, size: 18),
                ),
                const Gap(8),
                _CircleButton(
                  onTap: () => _toggleFavourite(isFav),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? _P.hotPink : _P.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action bar — I'M GOING ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: _P.black.withValues(alpha: 0.97),
                border: Border(
                  top: BorderSide(
                    color: _P.borderGray.withValues(alpha: 0.5),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _P.black.withValues(alpha: 0.70),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _ticketUrl.isNotEmpty
                    ? _openTickets
                    : () => _toggleFavourite(isFav),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: _P.neonLime,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _P.neonLime.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFav
                            ? Icons.check_circle_rounded
                            : Icons.local_activity_rounded,
                        color: _P.black,
                        size: 22,
                      ),
                      const Gap(10),
                      Text(
                        _ticketUrl.isNotEmpty
                            ? AppLocalizations.of(context)!.getTickets
                                .toUpperCase()
                            : "I'M GOING",
                        style: GoogleFonts.anton(
                          color: _P.black,
                          fontSize: AppResponsive.font(context, 17)
                              .clamp(15.0, 19.0),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time badge (teal circle with day/month + time) ────────────────────────────

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.dayMonth, required this.time});
  final String dayMonth;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: _P.teal,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dayMonth.isNotEmpty)
            Text(
              dayMonth,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _P.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: 0.5,
              ),
            ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              time,
              textAlign: TextAlign.center,
              style: GoogleFonts.anton(
                color: _P.black,
                fontSize: 14,
                height: 1.1,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Genre pill ────────────────────────────────────────────────────────────────

class _GenrePill extends StatelessWidget {
  const _GenrePill({required this.genre});
  final String genre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _P.hotPink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        genre.toUpperCase(),
        style: GoogleFonts.poppins(
          color: _P.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ── People going row ──────────────────────────────────────────────────────────

class _PeopleGoingRow extends StatelessWidget {
  const _PeopleGoingRow({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final avatarColors = [
      _P.hotPink,
      _P.teal,
      _P.neonLime,
      const Color(0xFFFF8C42),
    ];
    final shown = count.clamp(0, 4);
    const avatarSize = 32.0;
    const overlap = 22.0;
    final stackWidth = shown * overlap + (avatarSize - overlap);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: stackWidth.clamp(avatarSize, double.infinity),
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(shown, (i) {
              return Positioned(
                left: i * overlap,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: avatarColors[i % avatarColors.length]
                        .withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                    border: Border.all(color: _P.cream, width: 2.5),
                  ),
                  child: Center(
                    child: Icon(Icons.person_rounded,
                        color: _P.black.withValues(alpha: 0.65), size: 15),
                  ),
                ),
              );
            }),
          ),
        ),
        const Gap(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count GOING',
              style: GoogleFonts.anton(
                color: _P.black,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'are attending this event',
              style: GoogleFonts.poppins(
                color: _P.black.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _P.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: _P.borderGray.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: _P.black.withValues(alpha: 0.55),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({this.color = const Color(0x28000000)});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedLinePainter(color: color),
        child: const SizedBox(height: 1, width: double.infinity),
      );
}

// ── Ticket perforated tear line ───────────────────────────────────────────────

class _TicketTearLine extends StatelessWidget {
  const _TicketTearLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 11,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: _P.black.withValues(alpha: 0.20),
                dashWidth: 7,
                gapWidth: 5,
              ),
              child: const SizedBox(height: 1),
            ),
          ),
          // Left notch circle (black, punched out)
          Positioned(
            left: -22,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: _P.black, shape: BoxShape.circle),
            ),
          ),
          // Right notch circle (black, punched out)
          Positioned(
            right: -22,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: _P.black, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section divider ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: _P.black.withValues(alpha: 0.10),
      );
}

// ── Barcode strip ─────────────────────────────────────────────────────────────

class _BarcodeStrip extends StatelessWidget {
  const _BarcodeStrip({this.color = Colors.black});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        width: double.infinity,
        child: CustomPaint(painter: _BarcodePainter(color: color)),
      );
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double gapWidth;
  const _DashedLinePainter({
    required this.color,
    this.dashWidth = 5.0,
    this.gapWidth = 4.0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), p);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color ||
      old.dashWidth != dashWidth ||
      old.gapWidth != gapWidth;
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter({this.color = Colors.black});
  final Color color;
  static const _pat = [
    3, 1, 4, 1, 5, 2, 1, 3, 2, 1, 1, 2, 3, 1, 2, 1, 3, 2,
    1, 2, 1, 3, 1, 2, 2, 1, 3, 1, 2, 3, 1, 2, 1, 1, 3
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final total = _pat.fold<int>(0, (a, b) => a + b);
    final unit = size.width / total;
    final p = Paint()..color = color;
    double x = 0;
    bool bar = true;
    for (final u in _pat) {
      if (bar) {
        canvas.drawRect(
          Rect.fromLTWH(x, size.height * 0.05, u * unit, size.height * 0.90),
          p,
        );
      }
      x += u * unit;
      bar = !bar;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) => old.color != color;
}

// ── Policy row ────────────────────────────────────────────────────────────────

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: _P.black.withValues(alpha: 0.55),
                fontSize: AppResponsive.font(context, 13).clamp(11.5, 14.0),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _P.black,
                fontSize: AppResponsive.font(context, 13).clamp(11.5, 14.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyDivider extends StatelessWidget {
  const _PolicyDivider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(
            color: _P.black.withValues(alpha: 0.08), height: 1),
      );
}

// ── Map fallback ──────────────────────────────────────────────────────────────

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.locationLine});
  final String locationLine;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      color: _P.darkGray,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, color: _P.teal, size: 36),
          const Gap(8),
          Text(
            locationLine,
            style: GoogleFonts.poppins(
              color: _P.white.withValues(alpha: 0.55),
              fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
