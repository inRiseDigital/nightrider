import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightride/data/map_dummy_data.dart';
import 'package:nightride/data/services/open_map_service.dart';

/// Draggable bottom sheet that mirrors the Google Maps place detail panel.
/// Fetches live data from Google Places API using the app's GOOGLE_MAPS_API_KEY.
class GoogleMapsPlaceSheet extends StatefulWidget {
  const GoogleMapsPlaceSheet({
    super.key,
    required this.venue,
    required this.onDirections,
    required this.onStart,
    required this.onClose,
  });

  final MapBottomCardData venue;
  final VoidCallback onDirections;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  State<GoogleMapsPlaceSheet> createState() => _GoogleMapsPlaceSheetState();
}

class _GoogleMapsPlaceSheetState extends State<GoogleMapsPlaceSheet> {
  OpenPlaceInfo? _details;
  bool _fetching = false;
  bool _saved = false;
  bool _hoursExpanded = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bg       = Color(0xFF0F0F0F);
  static const _card     = Color(0xFF151515);
  static const _border   = Color(0xFF333333);
  static const _neonLime = Color(0xFFDFFF2F);
  static const _hotPink  = Color(0xFFFF3D73);
  static const _teal     = Color(0xFF62D6C8);
  static const _cream    = Color(0xFFF3EAD6);
  static const _white    = Colors.white;
  static const _muted    = Color(0xFF888888);
  static const _green    = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (widget.venue.lat == 0 || widget.venue.lng == 0) return;
    setState(() => _fetching = true);
    final details = await OpenMapService.getVenueDetails(
      widget.venue.title, widget.venue.lat, widget.venue.lng,
    );
    if (mounted) setState(() { _details = details; _fetching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopSection(),
            _buildActionPills(),
            if (_fetching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _neonLime,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_details != null) ...[
              _buildOverview(),
              _buildBottomBar(),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ── Top section ────────────────────────────────────────────────────────────

  Widget _buildTopSection() {
    final d      = _details;
    final openNow = d?.openNow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 4, bottom: 5),
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d?.name ?? widget.venue.title,
                  style: GoogleFonts.anton(
                    fontSize: 18,
                    color: _cream,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _iconCircle(
                _saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                _saved ? _neonLime : _white,
                () => setState(() => _saved = !_saved),
              ),
              const SizedBox(width: 4),
              _iconCircle(Icons.share_rounded, _white, () {}),
              const SizedBox(width: 4),
              _iconCircle(Icons.close_rounded, _white, widget.onClose),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              // Type label
              Text(
                d?.typeLabel ?? widget.venue.subtitle,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              if (openNow != null) ...[
                const Text(' · ', style: TextStyle(color: _muted, fontSize: 13)),
                Text(
                  openNow ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: openNow ? _green : _hotPink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Action pills ───────────────────────────────────────────────────────────

  Widget _buildActionPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _pill(
              icon: Icons.directions_rounded,
              label: 'Directions',
              bg: _neonLime,
              fg: const Color(0xFF070707),
              bold: true,
              onTap: widget.onDirections,
            ),
            const SizedBox(width: 10),
            _pill(
              icon: Icons.navigation_rounded,
              label: 'Start',
              bg: _teal.withValues(alpha: 0.20),
              fg: _teal,
              bold: true,
              onTap: widget.onStart,
            ),
            const SizedBox(width: 10),
            _pill(
              icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              label: 'Save',
              bg: Colors.transparent,
              fg: _white,
              onTap: () => setState(() => _saved = !_saved),
              border: _border,
            ),
            const SizedBox(width: 10),
            _pill(
              icon: Icons.share_rounded,
              label: 'Share',
              bg: Colors.transparent,
              fg: _white,
              onTap: () {},
              border: _border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    bool bold = false,
    required VoidCallback onTap,
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border != null ? Border.all(color: border, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview ───────────────────────────────────────────────────────────────

  Widget _buildOverview() {
    final d = _details!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(height: 1, color: _border),
          const SizedBox(height: 14),
          if (d.openingHours != null) ...[
            _infoTile(
              icon: Icons.access_time_rounded,
              text: d.openNow == true ? 'Open now' : 'Hours',
              textColor: d.openNow == true ? _green : _white,
              subtitle: d.openingHours,
              trailing: _hoursExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              onTap: () => setState(() => _hoursExpanded = !_hoursExpanded),
            ),
            if (_hoursExpanded)
              Container(
                margin: const EdgeInsets.only(left: 44, top: 6, bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border, width: 1),
                ),
                child: Text(
                  d.openingHours!,
                  style: const TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (d.address.isNotEmpty) ...[
            _infoTile(icon: Icons.location_on_rounded, text: d.address),
            const SizedBox(height: 8),
          ],
          if (d.phone != null) ...[
            _infoTile(
              icon: Icons.phone_rounded,
              text: d.phone!,
              textColor: _neonLime,
              onTap: () => _launch('tel:${d.phone}'),
            ),
            const SizedBox(height: 8),
          ],
          if (d.website != null) ...[
            _infoTile(
              icon: Icons.language_rounded,
              text: _shortUrl(d.website!),
              textColor: _teal,
              onTap: () => _launch(d.website!),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _barIconBtn(Icons.directions_rounded, widget.onDirections),
          _barIconBtn(Icons.navigation_rounded, widget.onStart),
          _barTextBtn(Icons.bookmark_outline_rounded, 'Save',
              () => setState(() => _saved = !_saved)),
          _barTextBtn(Icons.share_rounded, 'Share', () {}),
          _barTextBtn(Icons.add_rounded, 'Post', () {}),
        ],
      ),
    );
  }

  Widget _barIconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _neonLime.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: _neonLime.withValues(alpha: 0.40)),
          ),
          child: Icon(icon, color: _neonLime, size: 22),
        ),
      );

  Widget _barTextBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Info tile ──────────────────────────────────────────────────────────────

  Widget _infoTile({
    required IconData icon,
    required String text,
    Color? textColor,
    String? subtitle,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: _muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? _white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (trailing != null) Icon(trailing, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _iconCircle(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _card,
            shape: BoxShape.circle,
            border: Border.all(color: _border, width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  String _shortUrl(String url) {
    try { return Uri.parse(url).host; } catch (_) { return url; }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
