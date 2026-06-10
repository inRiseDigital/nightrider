import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/core/config/maps_config.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventDetailProvider(id));

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(backgroundColor: AppTheme.scaffold),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.eventNotFound,
            style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

// ── _DetailBody — converts to stateful so it can extract palette ──────────────

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.data});
  final Map<String, dynamic> data;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  Color _cardColor = AppTheme.accent;
  bool _colorLoaded = false;

  Color get _cardTextColor =>
      _cardColor.computeLuminance() > 0.35 ? Colors.black : Colors.white;

  // ── Field getters ─────────────────────────────────────────────────────────
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  Future<void> _extractColor() async {
    if (_coverImage.isEmpty) {
      if (mounted) setState(() { _colorLoaded = true; });
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(_coverImage),
        maximumColorCount: 32,
      );
      final c = palette.vibrantColor?.color
          ?? palette.lightVibrantColor?.color
          ?? palette.darkVibrantColor?.color
          ?? palette.mutedColor?.color
          ?? palette.dominantColor?.color;
      if (!mounted) return;
      setState(() {
        if (c != null) _cardColor = c;
        _colorLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() { _colorLoaded = true; });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDateTime() {
    if (_date.isEmpty) return '';
    final parts = _date.split('-');
    if (parts.length < 3) return _date;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    final monthName = (m > 0 && m <= 12) ? months[m] : '';
    final year = parts[0];
    final timeStr = _startTime.contains('T')
        ? _startTime.split('T').last.substring(0, 5)
        : '';
    return '$monthName $d, $year${timeStr.isNotEmpty ? ' · $timeStr' : ''}';
  }

  Future<void> _openTickets() async {
    if (_ticketUrl.isEmpty) return;
    final uri = Uri.tryParse(_ticketUrl);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero image ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.scaffold,
              leadingWidth: 72,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF555555),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: _coverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTheme.surface),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppTheme.surface),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.30, 0.65, 1.0],
                          colors: [
                            Color(0x00000000),
                            Color(0x22000000),
                            Color(0xBB000000),
                            Color(0xFF000000),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill — always lime
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _genre.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: AppResponsive.font(context, 11)
                              .clamp(9.5, 12.0),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const Gap(16),

                    // Title
                    Text(
                      _name.toUpperCase(),
                      style: GoogleFonts.anton(
                        color: Colors.white,
                        fontSize:
                            AppResponsive.font(context, 32).clamp(26.0, 38.0),
                        height: 1.02,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Gap(22),

                    // ── Dynamic Ticket Card ───────────────────────────────
                    if (!_colorLoaded)
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                    Container(
                      clipBehavior: Clip.none,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _cardColor.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EVENT DETAILS',
                                  style: GoogleFonts.poppins(
                                    color: _cardTextColor
                                        .withValues(alpha: 0.38),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_formatDateTime().isNotEmpty) ...[
                                  _TicketInfoRow(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'DATE & TIME',
                                    value: _formatDateTime(),
                                    textColor: _cardTextColor,
                                  ),
                                  _TicketDivider(
                                      lineColor: _cardTextColor),
                                ],
                                if (locationLine.isNotEmpty) ...[
                                  _TicketInfoRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'VENUE',
                                    value: locationLine,
                                    subValue: addressLine.isNotEmpty
                                        ? addressLine
                                        : null,
                                    textColor: _cardTextColor,
                                  ),
                                ],
                                if (_language.isNotEmpty) ...[
                                  _TicketDivider(
                                      lineColor: _cardTextColor),
                                  _TicketInfoRow(
                                    icon: Icons.language_rounded,
                                    label: 'LANGUAGE',
                                    value: _language,
                                    textColor: _cardTextColor,
                                  ),
                                ],
                                if (_priceHint.isNotEmpty) ...[
                                  _TicketDivider(
                                      lineColor: _cardTextColor),
                                  _TicketInfoRow(
                                    icon: Icons.local_activity_rounded,
                                    label: 'PRICE',
                                    value: _priceHint,
                                    textColor: _cardTextColor,
                                  ),
                                ],
                                if (_description.isNotEmpty) ...[
                                  _TicketDivider(
                                      lineColor: _cardTextColor),
                                  _TicketInfoRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'ABOUT',
                                    value: _description,
                                    isMultiLine: true,
                                    textColor: _cardTextColor,
                                  ),
                                ],
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          // Perforated tear line
                          _TicketTearLine(lineColor: _cardTextColor),
                          // Barcode section
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BarcodeStrip(color: _cardTextColor),
                                const SizedBox(height: 6),
                                Text(
                                  'ADMIT ONE  ·  NIGHT RITE',
                                  style: GoogleFonts.poppins(
                                    color: _cardTextColor
                                        .withValues(alpha: 0.36),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(28),

                    // ── Performers ────────────────────────────────────────
                    if (_performers.isNotEmpty || _artists.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.performers.toUpperCase(),
                        style: GoogleFonts.anton(
                          color: AppTheme.primary,
                          fontSize: AppResponsive.font(context, 18)
                              .clamp(15.0, 20.0),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Gap(12),
                      if (_performers.isNotEmpty)
                        Column(
                          children: _performers.map((p) {
                            final name = p['name'] as String? ?? '';
                            final type = p['type'] as String? ?? 'DJ';
                            final bio = p['bio'] as String? ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.07)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.mic_rounded,
                                      color: AppTheme.accent,
                                      size: AppResponsive.icon(context, 20)
                                          .clamp(17.0, 22.0),
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
                                                name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: AppResponsive
                                                          .font(context, 14)
                                                      .clamp(12.0, 15.5),
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6),
                                              ),
                                              child: Text(
                                                type,
                                                style: TextStyle(
                                                  color:
                                                      AppTheme.primaryLight,
                                                  fontSize: AppResponsive
                                                          .font(context, 10)
                                                      .clamp(9.0, 11.0),
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
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: AppResponsive.font(
                                                      context, 12)
                                                  .clamp(10.5, 13.0),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.05),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.08)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.mic_rounded,
                                          color: AppTheme.accent,
                                          size: AppResponsive.icon(
                                                  context, 13)
                                              .clamp(11.0, 14.5),
                                        ),
                                        const Gap(7),
                                        Text(
                                          artist,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: AppResponsive.font(
                                                    context, 13)
                                                .clamp(11.0, 14.5),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      const Gap(26),
                    ],

                    // ── Event Policies ────────────────────────────────────
                    if (_policies.isNotEmpty) ...[
                      Text(
                        'EVENT POLICIES',
                        style: GoogleFonts.anton(
                          color: AppTheme.primary,
                          fontSize: AppResponsive.font(context, 18)
                              .clamp(15.0, 20.0),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          children: [
                            if ((_policies['age_restriction'] as int? ??
                                    0) >
                                0) ...[
                              _PolicyRow(
                                icon: Icons.person_outline_rounded,
                                iconColor: Colors.orangeAccent,
                                label: 'Age Restriction',
                                value:
                                    '${_policies['age_restriction']}+ only',
                              ),
                              _DividerThin(),
                            ],
                            if ((_policies['refund_policy'] as String? ??
                                    '')
                                .isNotEmpty) ...[
                              _PolicyRow(
                                icon: Icons.receipt_long_rounded,
                                iconColor: Colors.blueAccent,
                                label: 'Refund Policy',
                                value:
                                    _policies['refund_policy'] as String,
                              ),
                              _DividerThin(),
                            ],
                            _PolicyRow(
                              icon: Icons.loop_rounded,
                              iconColor:
                                  _policies['re_entry_allowed'] == true
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                              label: 'Re-entry',
                              value:
                                  _policies['re_entry_allowed'] == true
                                      ? 'Allowed'
                                      : 'Not allowed',
                            ),
                            _DividerThin(),
                            _PolicyRow(
                              icon: Icons.accessible_rounded,
                              iconColor:
                                  _policies['wheelchair_accessible'] == true
                                      ? Colors.greenAccent
                                      : Colors.white38,
                              label: 'Wheelchair Access',
                              value:
                                  _policies['wheelchair_accessible'] == true
                                      ? 'Accessible'
                                      : 'Not specified',
                            ),
                            _DividerThin(),
                            _PolicyRow(
                              icon: Icons.pets_rounded,
                              iconColor:
                                  _policies['allow_pets'] == true
                                      ? Colors.greenAccent
                                      : Colors.white38,
                              label: 'Pets',
                              value: _policies['allow_pets'] == true
                                  ? 'Allowed'
                                  : 'Not allowed',
                            ),
                          ],
                        ),
                      ),
                      const Gap(26),
                    ],

                    // ── Description ───────────────────────────────────────
                    if (_description.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.aboutThisEvent
                            .toUpperCase(),
                        style: GoogleFonts.anton(
                          color: AppTheme.primary,
                          fontSize: AppResponsive.font(context, 18)
                              .clamp(15.0, 20.0),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Gap(12),
                      Text(
                        _description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppResponsive.font(context, 14)
                              .clamp(12.0, 15.0),
                          height: 1.65,
                        ),
                      ),
                      const Gap(26),
                    ],

                    // ── Map preview ───────────────────────────────────────
                    if (_lat != 0 && _lng != 0) ...[
                      Text(
                        AppLocalizations.of(context)!.location.toUpperCase(),
                        style: GoogleFonts.anton(
                          color: AppTheme.primary,
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
                          ref.read(appNavProvider.notifier).setIndex(1);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 190,
                                width: double.infinity,
                                child: staticMapUrl.isNotEmpty
                                    ? Image.network(
                                        staticMapUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, prog) =>
                                            prog == null
                                                ? child
                                                : Container(
                                                    color: AppTheme.surface,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        color:
                                                            AppTheme.primary,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                        errorBuilder: (_, __, ___) =>
                                            _MapFallback(
                                                locationLine: locationLine),
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
                                    color: Colors.black
                                        .withValues(alpha: 0.65),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        color: Colors.white,
                                        size: AppResponsive.icon(
                                                context, 12)
                                            .clamp(10.0, 13.5),
                                      ),
                                      const Gap(5),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .openInMaps,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppResponsive.font(
                                                  context, 11)
                                              .clamp(9.5, 12.0),
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Bottom action bar ──────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.97),
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 22,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_priceHint.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.price,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: AppResponsive.font(context, 12)
                                .clamp(10.5, 13.0),
                          ),
                        ),
                        Text(
                          _priceHint,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppResponsive.font(context, 16)
                                .clamp(14.0, 17.5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openTickets,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _cardColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_activity_rounded,
                            color: _cardTextColor,
                            size: AppResponsive.icon(context, 18)
                                .clamp(15.0, 20.0),
                          ),
                          const Gap(8),
                          Text(
                            AppLocalizations.of(context)!.getTickets
                                .toUpperCase(),
                            style: GoogleFonts.anton(
                              fontSize: AppResponsive.font(context, 15)
                                  .clamp(13.0, 17.0),
                              color: _cardTextColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ticket info row ───────────────────────────────────────────────────────────

class _TicketInfoRow extends StatelessWidget {
  const _TicketInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.isMultiLine = false,
    this.textColor = Colors.black,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final bool isMultiLine;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon,
                size: 18, color: textColor.withValues(alpha: 0.48)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.40),
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize:
                        AppResponsive.font(context, 15).clamp(13.5, 17.0),
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: isMultiLine ? 1.5 : 1.2,
                  ),
                  maxLines: isMultiLine ? 5 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subValue != null && subValue!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subValue!,
                    style: GoogleFonts.poppins(
                      fontSize: AppResponsive.font(context, 12)
                          .clamp(11.0, 13.5),
                      color: textColor.withValues(alpha: 0.50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _TicketDivider extends StatelessWidget {
  const _TicketDivider({this.lineColor = Colors.black});
  final Color lineColor;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: CustomPaint(
          painter:
              _DashedLinePainter(color: lineColor.withValues(alpha: 0.14)),
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      );
}

// ── Perforated tear line ──────────────────────────────────────────────────────

class _TicketTearLine extends StatelessWidget {
  const _TicketTearLine({this.lineColor = Colors.black});
  final Color lineColor;
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
                  color: lineColor.withValues(alpha: 0.18)),
              child: const SizedBox(height: 1),
            ),
          ),
          Positioned(
            left: -10,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppTheme.scaffold, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: -10,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppTheme.scaffold, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barcode strip ─────────────────────────────────────────────────────────────

class _BarcodeStrip extends StatelessWidget {
  const _BarcodeStrip({this.color = Colors.black});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        width: double.infinity,
        child: CustomPaint(painter: _BarcodePainter(color: color)),
      );
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const dw = 5.0;
    const sp = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dw, 0), p);
      x += dw + sp;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color;
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
          Rect.fromLTWH(x, size.height * 0.05, u * unit, size.height * 0.9),
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

// ── Policy widgets ────────────────────────────────────────────────────────────

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
            child: Icon(icon,
                color: iconColor,
                size:
                    AppResponsive.icon(context, 16).clamp(13.0, 18.0)),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize:
                    AppResponsive.font(context, 13).clamp(11.5, 14.0),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    AppResponsive.font(context, 13).clamp(11.5, 14.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerThin extends StatelessWidget {
  const _DividerThin();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(
            color: Colors.white.withValues(alpha: 0.05), height: 1),
      );
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.locationLine});
  final String locationLine;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      color: AppTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded,
              color: AppTheme.primary,
              size: AppResponsive.icon(context, 36).clamp(28.0, 40.0)),
          const Gap(8),
          Text(
            locationLine,
            style: TextStyle(
              color: Colors.white60,
              fontSize:
                  AppResponsive.font(context, 13).clamp(11.0, 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
