import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

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
        child: Text(AppLocalizations.of(context)!.eventNotFound, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.data});

  final Map<String, dynamic> data;

  String get _name => data['name'] as String? ?? '';
  String get _coverImage => data['cover_image'] as String? ?? '';
  String get _genre => data['genre'] as String? ?? 'Music';
  String get _date => data['date'] as String? ?? '';
  String get _startTime => data['start_time'] as String? ?? '';
  String get _venueName => data['venue_name'] as String? ?? '';
  String get _address => data['address'] as String? ?? '';
  String get _city => data['city'] as String? ?? '';
  String get _country => data['country'] as String? ?? '';
  String get _priceHint => data['price_hint'] as String? ?? '';
  String get _description => data['description'] as String? ?? '';
  String get _ticketUrl => data['ticket_url'] as String? ?? '';
  String get _language => data['language'] as String? ?? '';
  List<String> get _artists =>
      (data['artists'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  double get _lat => (data['lat'] as num? ?? 0).toDouble();
  double get _lng => (data['lng'] as num? ?? 0).toDouble();

  String _formatDateTime() {
    if (_date.isEmpty) return '';
    final parts = _date.split('-');
    if (parts.length < 3) return _date;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String mapToken = '';
    try { mapToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? ''; } catch (_) {}
    final String staticMapUrl = (mapToken.isNotEmpty && _lat != 0 && _lng != 0)
        ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/static/'
            'pin-l+9f7aea($_lng,$_lat)/$_lng,$_lat,14,0/600x260@2x'
            '?access_token=$mapToken'
        : '';

    final locationLine = [_city, _country].where((s) => s.isNotEmpty).join(', ');
    final addressLine = [_venueName, _address].where((s) => s.isNotEmpty).join(' · ');

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero image ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.scaffold,
              leadingWidth: 70,
              leading: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
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
                      placeholder: (_, __) => Container(color: AppTheme.surface),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.45, 0.75, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            AppTheme.scaffold.withValues(alpha: 0.7),
                            AppTheme.scaffold,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _genre.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: AppResponsive.font(context, 10).clamp(8.5, 11.0),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const Gap(14),

                    // Title
                    Text(
                      _name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppResponsive.font(context, 26).clamp(22.0, 28.5),
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const Gap(20),

                    // ── Info card ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          // Date & time
                          if (_formatDateTime().isNotEmpty) ...[
                            _InfoRow(
                              icon: Icons.calendar_month_rounded,
                              iconColor: AppTheme.accent,
                              text: _formatDateTime(),
                            ),
                            _Divider(),
                          ],

                          // Venue
                          if (locationLine.isNotEmpty)
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              iconColor: AppTheme.primary,
                              text: locationLine,
                              subText: addressLine.isNotEmpty ? addressLine : null,
                            ),

                          // Language
                          if (_language.isNotEmpty) ...[
                            _Divider(),
                            _InfoRow(
                              icon: Icons.language_rounded,
                              iconColor: Colors.blueAccent,
                              text: _language,
                            ),
                          ],

                          // Price
                          if (_priceHint.isNotEmpty) ...[
                            _Divider(),
                            _InfoRow(
                              icon: Icons.local_activity_rounded,
                              iconColor: Colors.greenAccent,
                              text: _priceHint,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(26),

                    // ── Artists ──────────────────────────────────────────────
                    if (_artists.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.performers,
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0), fontWeight: FontWeight.w900),
                      ),
                      const Gap(12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _artists.map((artist) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded, color: AppTheme.accent, size: AppResponsive.icon(context, 13).clamp(11.0, 14.5)),
                              const Gap(7),
                              Text(
                                artist,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      const Gap(26),
                    ],

                    // ── Description ──────────────────────────────────────────
                    if (_description.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.aboutThisEvent,
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0), fontWeight: FontWeight.w900),
                      ),
                      const Gap(12),
                      Text(
                        _description,
                        style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), height: 1.65),
                      ),
                      const Gap(26),
                    ],

                    // ── Map preview ──────────────────────────────────────────
                    if (_lat != 0 && _lng != 0) ...[
                      Text(
                        AppLocalizations.of(context)!.location,
                        style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0), fontWeight: FontWeight.w900),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: () {
                          ref.read(mapFocusProvider.notifier).state =
                              MapFocus(_lat, _lng, label: _name);
                          ref.read(appNavProvider.notifier).setIndex(1);
                          Navigator.of(context).popUntil((route) => route.isFirst);
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
                                        loadingBuilder: (_, child, prog) => prog == null
                                            ? child
                                            : Container(
                                                color: AppTheme.surface,
                                                child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                                              ),
                                        errorBuilder: (_, __, ___) => _MapFallback(locationLine: locationLine),
                                      )
                                    : _MapFallback(locationLine: locationLine),
                              ),
                              // "Open in Maps" overlay pill
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.open_in_new_rounded, color: Colors.white, size: AppResponsive.icon(context, 12).clamp(10.0, 13.5)),
                                      const Gap(5),
                                      Text(AppLocalizations.of(context)!.openInMaps, style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0), fontWeight: FontWeight.w700)),
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

        // ── Bottom action bar ────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.97),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 22, offset: const Offset(0, -6)),
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
                        Text(AppLocalizations.of(context)!.price, style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0))),
                        Text(_priceHint, style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 16).clamp(14.0, 17.5), fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openTickets,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accentPurple]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: AppResponsive.icon(context, 16).clamp(14.0, 17.5)),
                          const Gap(8),
                          Text(
                            AppLocalizations.of(context)!.getTickets,
                            style: TextStyle(fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.iconColor, required this.text, this.subText});
  final IconData icon;
  final Color iconColor;
  final String text;
  final String? subText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: AppResponsive.icon(context, 18).clamp(15.0, 20.0)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(2),
                Text(text, style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0), fontWeight: FontWeight.bold)),
                if (subText != null && subText!.isNotEmpty) ...[
                  const Gap(3),
                  Text(subText!, style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
    );
  }
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
          Icon(Icons.map_rounded, color: AppTheme.primary, size: AppResponsive.icon(context, 36).clamp(28.0, 40.0)),
          const Gap(8),
          Text(locationLine, style: TextStyle(color: Colors.white60, fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.5))),
        ],
      ),
    );
  }
}
