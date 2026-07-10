import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/map_dummy_data.dart';

/// Retro polaroid/sticker-style venue card shown in the bottom PageView
/// on the map screen.
class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onMoreDetails,
  });

  final MapBottomCardData data;
  final VoidCallback onTap;
  final VoidCallback onMoreDetails;

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const _black    = Color(0xFF070707);
  static const _surface  = Color(0xFF111111);
  static const _border   = Color(0xFF252525);
  static const _neonLime = Color(0xFFDFFF2F);
  static const _hotPink  = Color(0xFFFF3D73);
  static const _teal     = Color(0xFF62D6C8);

  bool get _isLive => data.openText.toLowerCase().contains('open') ||
      data.openText.toLowerCase().contains('tonight');

  bool get _isTrending => data.tags.any((t) =>
      t.contains('4.') &&
      double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), ''))?.let(
            (v) => v >= 4.5,
          ) ==
          true);

  @override
  Widget build(BuildContext context) {
    final cardHeight   = AppResponsive.mapBottomCardHeight(context);
    final imageWidth   = AppResponsive.mapBottomCardImageSize(context);
    final innerPadding = AppResponsive.gap(context, 10);
    final radius       = AppResponsive.radius(context, 18);
    final imageRadius  = AppResponsive.radius(context, 12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            // Subtle neon glow when live
            if (_isLive)
              BoxShadow(
                color: _hotPink.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Polaroid image panel ─────────────────────────────────────
            _ImagePanel(
              imageUrl: data.imageUrl,
              imageWidth: imageWidth,
              imageRadius: imageRadius,
              innerPadding: innerPadding,
              cardRadius: radius,
              isLive: _isLive,
              priceHint: data.priceHint,
            ),

            // ── Text content ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.gap(context, 10),
                  innerPadding,
                  innerPadding,
                  innerPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category pill + trending badge
                    Row(
                      children: [
                        if (data.subtitle.isNotEmpty)
                          _Pill(
                            label: data.subtitle.toUpperCase(),
                            color: _teal.withValues(alpha: 0.12),
                            textColor: _teal,
                            borderColor: _teal.withValues(alpha: 0.35),
                            fontSize: AppResponsive.font(context, 10),
                          ),
                        if (_isTrending) ...[
                          SizedBox(width: AppResponsive.gap(context, 5)),
                          _Pill(
                            label: 'TRENDING',
                            color: _hotPink.withValues(alpha: 0.12),
                            textColor: _hotPink,
                            borderColor: _hotPink.withValues(alpha: 0.35),
                            fontSize: AppResponsive.font(context, 9.5),
                          ),
                        ],
                      ],
                    ),

                    // Venue name
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppResponsive.font(context, 13.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                        height: 1.2,
                      ),
                    ),

                    // Distance + open status row
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: AppResponsive.icon(context, 12),
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                        SizedBox(width: AppResponsive.gap(context, 3)),
                        Expanded(
                          child: Text(
                            data.distanceKm > 0
                                ? '${data.distanceKm.toStringAsFixed(1)} km away'
                                : data.openText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: AppResponsive.font(context, 11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // "More details" button — neon lime accent
                    SizedBox(
                      height: AppResponsive.gap(context, 28).clamp(26.0, 34.0),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onMoreDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _neonLime,
                          foregroundColor: _black,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppResponsive.radius(context, 8),
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'MORE DETAILS',
                          style: TextStyle(
                            fontSize: AppResponsive.font(context, 10.5)
                                .clamp(9.5, 12.0),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _black,
                          ),
                        ),
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

// ── Polaroid image panel ─────────────────────────────────────────────────────
class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.imageUrl,
    required this.imageWidth,
    required this.imageRadius,
    required this.innerPadding,
    required this.cardRadius,
    required this.isLive,
    required this.priceHint,
  });

  final String imageUrl;
  final double imageWidth;
  final double imageRadius;
  final double innerPadding;
  final double cardRadius;
  final bool   isLive;
  final String priceHint;

  static const _hotPink  = Color(0xFFFF3D73);
  static const _neonLime = Color(0xFFDFFF2F);
  static const _black    = Color(0xFF070707);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(cardRadius),
      ),
      child: SizedBox(
        width: imageWidth,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            Hero(
              tag: 'venue_image_${imageUrl.hashCode}',
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
            ),

            // Dark scrim
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                ),
              ),
            ),

            // LIVE NOW badge — top left
            if (isLive)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _hotPink,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _hotPink.withValues(alpha: 0.50),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Price hint — bottom left
            if (priceHint.isNotEmpty)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    priceHint,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder when no image URL ────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(Icons.nightlife, color: Color(0xFF333333), size: 32),
      ),
    );
  }
}

// ── Small label pill ─────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.fontSize,
  });

  final String label;
  final Color  color;
  final Color  textColor;
  final Color  borderColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Dart extension helper used internally
extension _LetExt<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
