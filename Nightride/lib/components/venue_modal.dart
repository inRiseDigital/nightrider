import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/providers/home_providers.dart';

class VenueModal extends ConsumerWidget {
  const VenueModal({super.key, required this.data, required this.onNavigate});

  final MapBottomCardData data;
  final VoidCallback onNavigate;

  static const _bg          = Color(0xFF0F0F0F);
  static const _border      = Color(0xFF333333);
  static const _neonLime    = Color(0xFFDFFF2F);
  static const _hotPink     = Color(0xFFFF3D73);
  static const _teal        = Color(0xFF62D6C8);
  static const _cream       = Color(0xFFF3EAD6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos  = ref.watch(userLocationProvider).asData?.value;
    final double km = (userPos != null && data.lat != 0 && data.lng != 0)
        ? haversineKm(userPos.latitude, userPos.longitude, data.lat, data.lng)
        : 0;
    final String distLabel   = formatDistance(km);
    final String travelLabel = formatTravel(km);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.gap(context, 14),
        AppResponsive.gap(context, 10),
        AppResponsive.gap(context, 14),
        AppResponsive.gap(context, 14),
      ),
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 40,
            offset: Offset(0, -18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Gap(12),

          // ── Venue image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'venue_image_${data.title}',
                    child: Image.network(data.imageUrl, fit: BoxFit.cover),
                  ),
                  // Dark gradient scrim
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  // Open/closed badge — bottom left
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Text(
                        data.openText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  // Category badge — top right (hotPink)
                  if (data.subtitle.isNotEmpty)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _hotPink.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          data.subtitle.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Gap(14),

          // ── Name row + distance badge ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.anton(
                    fontSize: AppResponsive.font(context, 20).clamp(17.0, 22.0),
                    color: _cream,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Distance — teal badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _teal.withValues(alpha: 0.45), width: 1),
                    ),
                    child: Text(
                      distLabel,
                      style: TextStyle(
                        color: _teal,
                        fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (travelLabel.isNotEmpty) ...[
                    const Gap(3),
                    Text(
                      travelLabel,
                      style: const TextStyle(
                        color: _teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Gap(6),

          // ── Location line ────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              data.locationLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: AppResponsive.font(context, 12.5).clamp(11.0, 13.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Gap(18),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            children: [
              // Close — outlined dark
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 1.5),
                    ),
                    child: const Text(
                      'CLOSE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(10),
              // See full details — neonLime
              Expanded(
                child: GestureDetector(
                  onTap: onNavigate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _neonLime,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _neonLime.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'SEE DETAILS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.anton(
                        fontSize: 13,
                        color: const Color(0xFF070707),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
        ],
      ),
    );
  }
}
