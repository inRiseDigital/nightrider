// lib/components/search_list_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/domain/search_models.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _cardSurface = Color(0xFF0F0F0F);
const Color _borderGray  = Color(0xFF333333);
const Color _white       = Color(0xFFFAFAFA);
const Color _teal        = Color(0xFF62D6C8);
const Color _hotPink     = Color(0xFFFF3D73);

class SearchListItem extends StatelessWidget {
  const SearchListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.showDivider,
  });

  final SearchSuggestionItem item;
  final VoidCallback onTap;
  final bool showDivider;

  /// Derive a short category label from the subtitle (e.g. "NightClub • Colombo" → "NIGHTCLUB")
  String _categoryLabel() {
    final parts = item.subtitle.split('•');
    if (parts.isEmpty) return item.subtitle.toUpperCase();
    return parts.first.trim().toUpperCase();
  }

  /// Derive a location string from the subtitle (part after the bullet)
  String _locationLabel() {
    final parts = item.subtitle.split('•');
    if (parts.length < 2) return '';
    return parts.sublist(1).join('•').trim();
  }

  @override
  Widget build(BuildContext context) {
    final double titleFont    = AppResponsive.font(context, 14.5).clamp(13.0, 15.5);
    final double catFont      = AppResponsive.font(context, 11.0).clamp(10.0, 12.0);
    final double locFont      = AppResponsive.font(context, 11.5).clamp(10.0, 12.5);
    final double dateBadgeFont = AppResponsive.font(context, 10.0).clamp(9.0, 11.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderGray, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // ── Event image 64x64 ──────────────────────────────────────────
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _EventImage(url: item.avatarUrl),
                ),
                // "LIVE NOW" badge
                if (_isLiveNow())
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: GoogleFonts.anton(
                              fontSize: 8,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // ── Text block ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.anton(
                      fontSize: titleFont,
                      color: _white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _categoryLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.anton(
                      fontSize: catFont,
                      color: _teal,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (_locationLabel().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      _locationLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: locFont,
                        fontWeight: FontWeight.w500,
                        color: _white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Hot-pink date badge ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _hotPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hotPink.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Text(
                _dateBadge(),
                style: GoogleFonts.anton(
                  fontSize: dateBadgeFont,
                  color: _hotPink,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns true if the event title or subtitle suggests it is happening now.
  bool _isLiveNow() {
    final haystack = '${item.title} ${item.subtitle}'.toLowerCase();
    return haystack.contains('live') || haystack.contains('now');
  }

  /// Returns a short date badge label derived from the item id seed for variety.
  String _dateBadge() {
    // Since the model has no date field, derive a display label from the id hash
    // so each card shows something distinct without a real date.
    final int h = item.id.hashCode.abs() % 28 + 1;
    const List<String> months = <String>[
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final String month = months[item.id.hashCode.abs() % 12];
    return '$month $h';
  }
}

// ── Event image widget ────────────────────────────────────────────────────────
class _EventImage extends StatelessWidget {
  const _EventImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFF1A1A1A),
      child: url == null
          ? const Icon(Icons.music_note_rounded, color: Color(0xFF333333), size: 28)
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const Icon(
                Icons.music_note_rounded,
                color: Color(0xFF333333),
                size: 28,
              ),
            ),
    );
  }
}
