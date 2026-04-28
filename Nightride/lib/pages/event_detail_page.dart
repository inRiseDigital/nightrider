import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final String mapToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
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
              expandedHeight: 360.h,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.scaffold,
              leadingWidth: 70.w,
              leading: Padding(
                padding: EdgeInsets.only(left: 14.w),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 40.h,
                      width: 40.w,
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
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 130.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _genre.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    Gap(14.h),

                    // Title
                    Text(
                      _name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Gap(20.h),

                    // ── Info card ────────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20.r),
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
                    Gap(26.h),

                    // ── Artists ──────────────────────────────────────────────
                    if (_artists.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.performers,
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      Gap(12.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: _artists.map((artist) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded, color: AppTheme.accent, size: 13.sp),
                              Gap(7.w),
                              Text(
                                artist,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      Gap(26.h),
                    ],

                    // ── Description ──────────────────────────────────────────
                    if (_description.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.aboutThisEvent,
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      Gap(12.h),
                      Text(
                        _description,
                        style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.65),
                      ),
                      Gap(26.h),
                    ],

                    // ── Map preview ──────────────────────────────────────────
                    if (_lat != 0 && _lng != 0) ...[
                      Text(
                        AppLocalizations.of(context)!.location,
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w900),
                      ),
                      Gap(12.h),
                      GestureDetector(
                        onTap: () {
                          ref.read(mapFocusProvider.notifier).state =
                              MapFocus(_lat, _lng, label: _name);
                          ref.read(appNavProvider.notifier).setIndex(1);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 190.h,
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
                                bottom: 10.h,
                                right: 10.w,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(999.r),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12.sp),
                                      Gap(5.w),
                                      Text(AppLocalizations.of(context)!.openInMaps, style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
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
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
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
                    padding: EdgeInsets.only(right: 20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.price, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                        Text(_priceHint, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openTickets,
                    child: Container(
                      height: 54.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accentPurple]),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16.sp),
                          Gap(8.w),
                          Text(
                            AppLocalizations.of(context)!.getTickets,
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
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
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Gap(2.h),
                Text(text, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                if (subText != null && subText!.isNotEmpty) ...[
                  Gap(3.h),
                  Text(subText!, style: TextStyle(color: Colors.white54, fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
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
      padding: EdgeInsets.symmetric(vertical: 10.h),
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
      height: 190.h,
      color: AppTheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, color: AppTheme.primary, size: 36.sp),
          Gap(8.h),
          Text(locationLine, style: TextStyle(color: Colors.white60, fontSize: 13.sp)),
        ],
      ),
    );
  }
}
