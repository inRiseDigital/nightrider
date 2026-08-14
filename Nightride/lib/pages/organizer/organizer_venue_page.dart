import 'package:flutter/material.dart';

import 'package:nightride/core/theme/app_theme.dart';

class _VenueInfo {
  const _VenueInfo({
    required this.name,
    required this.address,
    required this.hasHero,
    required this.genres,
    required this.hours,
  });
  final String name;
  final String address;
  final bool hasHero;
  final List<String> genres;
  final List<(String, String)> hours;
}

const _venues = {
  'sirens': _VenueInfo(
    name: 'Sirens Rooftop',
    address: 'Level 42, Marasi Drive, Business Bay, Dubai',
    hasHero: true,
    genres: ['House', 'Disco', 'Afrobeats', 'Rooftop'],
    hours: [
      ('Thursday', '20:00 – 03:00'),
      ('Friday', '20:00 – 04:00'),
      ('Saturday', '20:00 – 04:00'),
      ('Sunday – Wednesday', 'Closed'),
    ],
  ),
  'warehouse9': _VenueInfo(
    name: 'Warehouse 9',
    address: 'Street 14, Al Quoz Industrial 3, Dubai',
    hasHero: false,
    genres: ['Techno', 'House', 'Late licence'],
    hours: [
      ('Wednesday', '23:00 – 04:00'),
      ('Thursday', '23:00 – 05:00'),
      ('Friday – Saturday', '23:00 – 05:00'),
      ('Sunday – Tuesday', 'Closed'),
    ],
  ),
};

/// Venue tab — no venue picker/hours/hero-image concept exists in the
/// `events`/`venues` write path yet for the signed-in organizer to bind to,
/// so this is local/mock UI, same as the Home tab.
class OrganizerVenuePage extends StatefulWidget {
  const OrganizerVenuePage({super.key});

  @override
  State<OrganizerVenuePage> createState() => _OrganizerVenuePageState();
}

class _OrganizerVenuePageState extends State<OrganizerVenuePage> {
  String _venueId = 'sirens';

  @override
  Widget build(BuildContext context) {
    final venue = _venues[_venueId]!;
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: Text(venue.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Row(
            children: _venues.entries.map((e) {
              final active = _venueId == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _venueId = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
                      border: Border.all(color: active ? AppTheme.primary : AppTheme.borderGray),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.storefront_outlined, size: 18, color: active ? AppTheme.primaryLight : Colors.white54),
                      const SizedBox(width: 6),
                      Text(e.value.name, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(color: AppTheme.darkGray, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Icon(
              venue.hasHero ? Icons.image_outlined : Icons.add_photo_alternate_outlined,
              color: Colors.white24,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 2),
                Text(venue.address, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: venue.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF8C0035), borderRadius: BorderRadius.circular(8)),
                        child: Text(g, style: const TextStyle(color: Color(0xFFFFD9DF), fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList(),
                ),
              ],
            ),
          ),
          if (!venue.hasHero) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF6B3E00), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, color: Color(0xFFFFDDB3), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${venue.name} still has no hero image — listings without one rank lower.',
                        style: const TextStyle(color: Color(0xFFFFDDB3), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('OPENING HOURS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.darkGray, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: venue.hours.map((h) {
                final isLast = h == venue.hours.last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.borderGray)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      Text(h.$2, style: TextStyle(color: h.$2 == 'Closed' ? Colors.white38 : Colors.white70, fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
