import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/services/auth_service.dart';

/// Account tab — team roster and preference toggles have no backing
/// collection today (there is no per-venue team/role model in the schema),
/// so they're local/mock like the rest of the dashboard shell. Sign-out is
/// real, using the same authServiceProvider.signOut() + reset-to-sign-in
/// pattern as settings_page.dart.
class OrganizerAccountPage extends ConsumerStatefulWidget {
  const OrganizerAccountPage({super.key});

  @override
  ConsumerState<OrganizerAccountPage> createState() => _OrganizerAccountPageState();
}

class _Pref {
  _Pref(this.label, this.desc, this.on);
  final String label;
  final String desc;
  bool on;
}

class _OrganizerAccountPageState extends ConsumerState<OrganizerAccountPage> {
  final _prefs = [
    _Pref('Guest list alerts', 'Push me when an RSVP list passes 80% of capacity.', true),
    _Pref('Auto-publish residencies', 'Weekly nights publish without re-review.', false),
    _Pref('Share crowd data', 'Helps the assistant recommend your venue.', true),
    _Pref('Two-factor on payouts', 'Require SMS confirmation for payout changes.', true),
  ];

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: const Text('Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const Text('TEAM', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.darkGray, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: const [
                _TeamRow(initials: 'RA', name: 'Rania Aziz', role: 'Owner · full access'),
                _TeamRow(initials: 'MK', name: 'Marc Keller', role: 'Manager · events, guest lists'),
                _TeamRow(initials: 'DS', name: 'Dina Saleh', role: 'Door staff · check-in only', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('PREFERENCES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.darkGray, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _prefs.asMap().entries.map((entry) {
                final pref = entry.value;
                final isLast = entry.key == _prefs.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.borderGray)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pref.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
                            Text(pref.desc, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2),
                          ],
                        ),
                      ),
                      Switch(
                        value: pref.on,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppTheme.primary,
                        onChanged: (v) => setState(() => pref.on = v),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF2B8B5)),
              foregroundColor: const Color(0xFFF2B8B5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.initials, required this.name, required this.role, this.isLast = false});
  final String initials;
  final String name;
  final String role;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.borderGray)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFF005046), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(color: Color(0xFF9EF2E4), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
                Text(role, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
