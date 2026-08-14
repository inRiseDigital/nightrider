import 'package:flutter/material.dart';

import 'package:nightride/core/theme/app_theme.dart';

/// Home tab of the organizer dashboard — door status, queue control, and a
/// quick read on tonight's numbers. There is no `door`/`queue`/AI-score
/// concept in the real schema (events/{eventId} carries none of this), so
/// this whole tab is local/mock UI per design, same footing as the rest of
/// the still-prototype dashboard shells CLAUDE.md describes.
class OrganizerTonightPage extends StatefulWidget {
  const OrganizerTonightPage({super.key});

  @override
  State<OrganizerTonightPage> createState() => _OrganizerTonightPageState();
}

enum _Door { open, queue, closed }

class _OrganizerTonightPageState extends State<OrganizerTonightPage> {
  _Door _door = _Door.open;
  int _queue = 12;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: const Text('Tonight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.nightlife_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Tonight — Sirens Rooftop',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0F4F31), borderRadius: BorderRadius.circular(8)),
                      child: const Text('LIVE', style: TextStyle(color: Color(0xFFC8EBD5), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Full Moon Rooftop · doors 22:00 · DJ Kalima',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.borderGray),
                  ),
                  child: Row(
                    children: _Door.values.map((d) {
                      final active = _door == d;
                      final label = switch (d) {
                        _Door.open => 'Open',
                        _Door.queue => 'Queue',
                        _Door.closed => 'At capacity',
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _door = d);
                            _snack('Door status set to ${label.toLowerCase()}.');
                          },
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: active ? AppTheme.primaryLight : Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Queue wait', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _stepButton('−', () => setState(() => _queue = (_queue - 5).clamp(0, 999))),
                              SizedBox(
                                width: 60,
                                child: Text('${_queue}m',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                              ),
                              _stepButton('+', () => setState(() => _queue += 5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _snack('Update pushed to 268 guests.'),
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: const Text('Send update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: const [
              _Kpi(icon: Icons.confirmation_number_outlined, value: '268', label: 'RSVPs tonight', delta: '+18%', good: true),
              _Kpi(icon: Icons.payments_outlined, value: 'AED 21.4k', label: 'Revenue', delta: '+7%', good: true),
              _Kpi(icon: Icons.visibility_outlined, value: '9,120', label: 'Views, 7d', delta: '−4%', good: false),
              _Kpi(icon: Icons.auto_awesome_outlined, value: '74', label: 'AI score', delta: '+6', good: true),
            ],
          ),
          const SizedBox(height: 20),
          const Text('NEEDS ATTENTION', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _AttentionRow(
            icon: Icons.gavel_outlined,
            iconBg: const Color(0xFF6B3E00),
            iconFg: const Color(0xFFFFDDB3),
            title: 'Sunset to Sunrise is in review',
            body: 'Possible duplicate · ~2h remaining',
            action: 'Review',
            onTap: () => _snack('Opening review queue…'),
          ),
          _AttentionRow(
            icon: Icons.image_outlined,
            iconBg: const Color(0xFF8C0035),
            iconFg: const Color(0xFFFFD9DF),
            title: 'Warehouse 9 has no hero image',
            body: 'Listings without one rank lower',
            action: 'Upload',
            onTap: () => _snack('Opening venue photos…'),
          ),
          _AttentionRow(
            icon: Icons.reviews_outlined,
            iconBg: const Color(0xFF8C1D18),
            iconFg: const Color(0xFFF9DEDC),
            title: '1 review looks like spam',
            body: '@johndoe22 · 2 days ago',
            action: 'Open',
            onTap: () => _snack('Review flagged for the platform team.'),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.borderGray)),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.value, required this.label, required this.delta, required this.good});
  final IconData icon;
  final String value;
  final String label;
  final String delta;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.darkGray, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 18),
              Text(delta, style: TextStyle(color: good ? const Color(0xFF7FD8A4) : const Color(0xFFFFB95C), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconFg, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Text(action, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
