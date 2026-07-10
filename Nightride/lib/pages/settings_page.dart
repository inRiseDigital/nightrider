import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/home_language_sheet.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/data/services/privacy_service.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/admin/admin_panel_page.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/organizer_apply_page.dart';
import 'package:nightride/pages/edit_profile_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/providers/settings_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ── Retro nightlife palette ──────────────────────────────────────────────────

const _kBlack    = Color(0xFF070707);
const _kDarkCard = Color(0xFF151515);
const _kBorder   = Color(0xFF333333);
const _kCream    = Color(0xFFF3EAD6);
const _kNeonLime = Color(0xFFDFFF2F);
const _kHotPink  = Color(0xFFFF3D73);
const _kWhite    = Color(0xFFFAFAFA);
const _kGray     = Color(0xFF888888);

// ── Main Settings Page ────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBlack,
      appBar: AppBar(
        backgroundColor: _kBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: GoogleFonts.anton(
            color: _kCream,
            fontSize: AppResponsive.font(context, 22).clamp(18.0, 26.0),
            letterSpacing: 3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── APPEARANCE ──────────────────────────────────────────────────────
          _SectionLabel(label: 'APPEARANCE'),
          const Gap(10),
          _DarkCard(
            children: [
              _AppearanceSection(l: l),
            ],
          ),

          const Gap(28),

          // ── ACCOUNT ─────────────────────────────────────────────────────────
          _SectionLabel(label: 'ACCOUNT'),
          const Gap(10),
          _DarkCard(
            children: [
              _RowTile(
                icon: Icons.person_outline_rounded,
                label: l.editProfile,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
              ),
              _Sep(),
              _RowTile(
                icon: Icons.notifications_none_rounded,
                label: l.notifications,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _NotificationsPage()),
                ),
              ),
              _Sep(),
              _RowTile(
                icon: Icons.lock_outline_rounded,
                label: l.privacySecurity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _PrivacyPage()),
                ),
              ),
              _Sep(),
              _RowTile(
                icon: Icons.help_outline_rounded,
                label: l.helpCenter,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _HelpCenterPage()),
                ),
              ),
              _Sep(),
              _RowTile(
                icon: Icons.info_outline_rounded,
                label: l.aboutNightride,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AboutPage()),
                ),
              ),
            ],
          ),

          // ── ORGANIZER (non-admin, non-organizer only) ────────────────────────
          if (ref.watch(isAdminProvider).asData?.value != true &&
              ref.watch(isOrganizerProvider).asData?.value != true) ...[
            const Gap(28),
            _SectionLabel(label: 'ORGANIZER'),
            const Gap(10),
            _OrganizerSection(ref: ref),
          ],

          // ── ADMIN PANEL (admin only) ─────────────────────────────────────────
          if (ref.watch(isAdminProvider).asData?.value == true) ...[
            const Gap(28),
            _SectionLabel(label: 'ADMIN'),
            const Gap(10),
            _DarkCard(
              children: [
                _AdminPanelTile(context: context),
              ],
            ),
          ],

          // ── DANGER / LOG OUT ─────────────────────────────────────────────────
          const Gap(28),
          _SectionLabel(label: 'SESSION'),
          const Gap(10),
          _LogOutButton(l: l),

          const Gap(40),
        ],
      ),
    );
  }
}

// ── Appearance inline section ─────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = ref.watch(homeDarkToggleProvider);
    final selectedIdx = ref.watch(accentColorIndexProvider);

    return Column(
      children: [
        // Dark mode toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              _NeonIcon(icon: Icons.dark_mode_outlined),
              const Gap(14),
              Text(
                'DARK MODE',
                style: GoogleFonts.anton(color: _kWhite, fontSize: 14, letterSpacing: 1),
              ),
              const Spacer(),
              Switch(
                value: isDark,
                onChanged: (v) => ref.read(homeDarkToggleProvider.notifier).state = v,
                activeThumbColor: _kNeonLime,
                activeTrackColor: _kNeonLime.withValues(alpha: 0.25),
                inactiveThumbColor: const Color(0xFF555555),
                inactiveTrackColor: const Color(0xFF2A2A2A),
              ),
            ],
          ),
        ),

        _Sep(),

        // Accent color
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              _NeonIcon(icon: Icons.palette_outlined),
              const Gap(14),
              Text(
                'ACCENT COLOR',
                style: GoogleFonts.anton(color: _kWhite, fontSize: 14, letterSpacing: 1),
              ),
              const Spacer(),
              Row(
                children: List.generate(kAccentColors.length, (i) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => ref.read(accentColorIndexProvider.notifier).state = i,
                    child: _ColorDot(color: kAccentColors[i], selected: selectedIdx == i),
                  ),
                )),
              ),
            ],
          ),
        ),

        _Sep(),

        // Language
        InkWell(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          onTap: () => HomeLanguageSheet.show(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                _NeonIcon(icon: Icons.language_rounded),
                const Gap(14),
                Text(
                  'LANGUAGE',
                  style: GoogleFonts.anton(color: _kWhite, fontSize: 14, letterSpacing: 1),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: _kBorder, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Admin panel tile ──────────────────────────────────────────────────────────

class _AdminPanelTile extends StatelessWidget {
  const _AdminPanelTile({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminPanelPage()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kHotPink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _kHotPink.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: _kHotPink, size: 18),
            ),
            const Gap(14),
            Expanded(
              child: Text(
                'ADMIN PANEL',
                style: GoogleFonts.anton(color: _kHotPink, fontSize: 14, letterSpacing: 1),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kBorder, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Log out outlined button ───────────────────────────────────────────────────

class _LogOutButton extends ConsumerWidget {
  const _LogOutButton({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kHotPink, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: _kHotPink, size: 18),
            const Gap(10),
            Text(
              'LOG OUT',
              style: GoogleFonts.anton(
                color: _kHotPink,
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Organizer apply section ───────────────────────────────────────────────────

class _OrganizerSection extends ConsumerWidget {
  const _OrganizerSection({required this.ref});
  final WidgetRef ref;

  void _openApply(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrganizerApplyPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(organizerRequestStatusProvider).asData?.value;

    if (status == 'pending') {
      return _DarkCard(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Colors.orangeAccent, size: 18),
              ),
              const Gap(14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPLICATION PENDING',
                    style: GoogleFonts.anton(color: Colors.orangeAccent, fontSize: 13, letterSpacing: 1),
                  ),
                  const Gap(2),
                  const Text('An admin will review your request', style: TextStyle(color: _kGray, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ]);
    }

    if (status == 'rejected') {
      return _DarkCard(children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openApply(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kHotPink.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kHotPink.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: _kHotPink, size: 18),
                ),
                const Gap(14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APPLICATION REJECTED', style: GoogleFonts.anton(color: _kHotPink, fontSize: 13, letterSpacing: 1)),
                    const Gap(2),
                    const Text('Tap to reapply', style: TextStyle(color: _kGray, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: _kBorder, size: 20),
              ],
            ),
          ),
        ),
      ]);
    }

    // Default: BECOME AN ORGANIZER outlined button
    return GestureDetector(
      onTap: () => _openApply(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kNeonLime, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, color: _kNeonLime, size: 18),
            const Gap(10),
            Text(
              'BECOME AN ORGANIZER',
              style: GoogleFonts.anton(
                color: _kNeonLime,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications sub-page ────────────────────────────────────────────────────

class _NotificationsPage extends ConsumerStatefulWidget {
  const _NotificationsPage();
  @override
  ConsumerState<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<_NotificationsPage> {
  bool _eventAlerts   = true;
  bool _nearbyEvents  = true;
  bool _friendActivity = false;
  bool _promotions    = false;
  bool _appUpdates    = true;

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'NOTIFICATIONS',
      child: Column(
        children: [
          _SectionLabel(label: 'EVENTS'),
          const Gap(10),
          _DarkCard(children: [
            _SwitchTile(label: 'EVENT ALERTS & REMINDERS', value: _eventAlerts,  onChanged: (v) => setState(() => _eventAlerts = v)),
            _Sep(),
            _SwitchTile(label: 'EVENTS NEAR ME',           value: _nearbyEvents, onChanged: (v) => setState(() => _nearbyEvents = v)),
          ]),
          const Gap(24),
          _SectionLabel(label: 'SOCIAL'),
          const Gap(10),
          _DarkCard(children: [
            _SwitchTile(label: 'FRIEND ACTIVITY', value: _friendActivity, onChanged: (v) => setState(() => _friendActivity = v)),
          ]),
          const Gap(24),
          _SectionLabel(label: 'OTHER'),
          const Gap(10),
          _DarkCard(children: [
            _SwitchTile(label: 'PROMOTIONS & DEALS', value: _promotions,  onChanged: (v) => setState(() => _promotions = v)),
            _Sep(),
            _SwitchTile(label: 'APP UPDATES',        value: _appUpdates,  onChanged: (v) => setState(() => _appUpdates = v)),
          ]),
        ],
      ),
    );
  }
}

// ── Delete account helper ─────────────────────────────────────────────────────

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _kDarkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kBorder),
      ),
      title: Text(
        'DELETE ACCOUNT',
        style: GoogleFonts.anton(color: _kWhite, fontSize: 18, letterSpacing: 1.5),
      ),
      content: const Text(
        'This will permanently delete your account and all your data. This cannot be undone.',
        style: TextStyle(color: _kGray, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('CANCEL', style: GoogleFonts.anton(color: _kBorder, letterSpacing: 1)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('DELETE', style: GoogleFonts.anton(color: _kHotPink, letterSpacing: 1)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final db  = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(uid);

    final subcollections = await Future.wait([
      userRef.collection('favourites').get(),
      userRef.collection('chat_sessions').get(),
      userRef.collection('settings').get(),
    ]);

    final batch = db.batch();
    for (final snap in subcollections) {
      for (final doc in snap.docs) { batch.delete(doc.reference); }
    }
    batch.delete(userRef);
    batch.delete(db.collection('avatars').doc(uid));
    await batch.commit();

    final prefs = await SharedPreferences.getInstance();
    for (final k in ['onboarding_completed', 'ob_ageRange', 'ob_genres', 'ob_vibes', 'ob_features', 'ob_goOutTime', 'ob_budget']) {
      await prefs.remove(k);
    }

    await user.delete();
    await ref.read(authServiceProvider).signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        e.code == 'requires-recent-login'
            ? 'Please sign out and sign in again before deleting your account.'
            : 'Could not delete account. Please try again.',
      ),
      backgroundColor: _kHotPink,
    ));
  }
}

// ── Privacy & Security sub-page ───────────────────────────────────────────────

class _PrivacyPage extends ConsumerWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(privacySettingsProvider);
    final svc   = ref.read(privacyServiceProvider);

    void toggle(PrivacySettings Function(PrivacySettings s) update) {
      final current = async.asData?.value ?? const PrivacySettings();
      svc.update(update(current));
    }

    return _SubPage(
      title: 'PRIVACY & SECURITY',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kNeonLime)),
        error: (_, __) => const Center(child: Text('Failed to load settings', style: TextStyle(color: _kGray))),
        data: (s) => Column(
          children: [
            _SectionLabel(label: 'PROFILE'),
            const Gap(10),
            _DarkCard(children: [
              _SwitchTile(
                label: 'PUBLIC PROFILE',
                value: s.publicProfile,
                onChanged: (v) => toggle((s) => s.copyWith(publicProfile: v)),
              ),
              _Sep(),
              _SwitchTile(
                label: 'SHOW LOCATION TO FRIENDS',
                value: s.showLocation,
                onChanged: (v) => toggle((s) => s.copyWith(showLocation: v)),
              ),
              _Sep(),
              _SwitchTile(
                label: 'SHOW ACTIVITY STATUS',
                value: s.showActivity,
                onChanged: (v) => toggle((s) => s.copyWith(showActivity: v)),
              ),
            ]),
            const Gap(24),
            _SectionLabel(label: 'SECURITY'),
            const Gap(10),
            _DarkCard(children: [
              _SwitchTile(
                label: 'TWO-FACTOR AUTHENTICATION',
                value: s.twoFactor,
                onChanged: (v) => toggle((s) => s.copyWith(twoFactor: v)),
              ),
            ]),
            const Gap(24),
            _SectionLabel(label: 'DANGER'),
            const Gap(10),
            _DarkCard(children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _confirmDeleteAccount(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kHotPink.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: _kHotPink.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: _kHotPink, size: 18),
                      ),
                      const Gap(14),
                      Text('DELETE ACCOUNT', style: GoogleFonts.anton(color: _kHotPink, fontSize: 14, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Help Center sub-page ──────────────────────────────────────────────────────

class _HelpCenterPage extends StatelessWidget {
  const _HelpCenterPage();
  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'HELP CENTER',
      child: Column(
        children: [
          _SectionLabel(label: 'FAQS'),
          const Gap(10),
          _DarkCard(children: [
            _ExpandableTile(
              question: 'HOW DO I FIND EVENTS NEAR ME?',
              answer: 'Go to the Map tab and allow location access. Events near you will appear as pins on the map.',
            ),
            _Sep(),
            _ExpandableTile(
              question: 'HOW DO I BUY TICKETS?',
              answer: "Open any event and tap \"GET TICKETS\". You'll be redirected to the official ticketing page.",
            ),
            _Sep(),
            _ExpandableTile(
              question: 'CAN I FILTER EVENTS BY GENRE?',
              answer: 'Yes! Use the category rail on the home page to filter by EDM, Techno, House, DJ, and more.',
            ),
            _Sep(),
            _ExpandableTile(
              question: 'HOW DO I CHANGE THE APP LANGUAGE?',
              answer: 'Go to Settings → Language and select from 12 available languages.',
            ),
          ]),
          const Gap(24),
          _SectionLabel(label: 'CONTACT'),
          const Gap(10),
          _DarkCard(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  _NeonIcon(icon: Icons.email_outlined),
                  const Gap(14),
                  const Text('support@nightride.app', style: TextStyle(color: _kWhite, fontSize: 14)),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── About sub-page ────────────────────────────────────────────────────────────

class _AboutPage extends StatefulWidget {
  const _AboutPage();
  @override
  State<_AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<_AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'ABOUT NIGHTRIDE',
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                const Gap(12),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kNeonLime.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kNeonLime.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: const Icon(Icons.nightlife_rounded, color: _kNeonLime, size: 38),
                ),
                const Gap(14),
                Text(
                  'NIGHTRIDE',
                  style: GoogleFonts.anton(color: _kCream, fontSize: 22, letterSpacing: 4),
                ),
                const Gap(4),
                Text(_version, style: const TextStyle(color: _kGray, fontSize: 13)),
                const Gap(24),
              ],
            ),
          ),
          _SectionLabel(label: 'INFO'),
          const Gap(10),
          _DarkCard(children: [
            _RowTile(icon: Icons.description_outlined,  label: 'TERMS OF SERVICE',    onTap: () {}),
            _Sep(),
            _RowTile(icon: Icons.privacy_tip_outlined,  label: 'PRIVACY POLICY',      onTap: () {}),
            _Sep(),
            _RowTile(icon: Icons.code_rounded,          label: 'OPEN SOURCE LICENSES', onTap: () {}),
          ]),
        ],
      ),
    );
  }
}

// ── Shared sub-page scaffold ──────────────────────────────────────────────────

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBlack,
      appBar: AppBar(
        backgroundColor: _kBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.anton(color: _kCream, fontSize: 20, letterSpacing: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: child,
      ),
    );
  }
}

// ── Reusable primitives ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.anton(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: _kBorder.withValues(alpha: 0.5),
    );
  }
}

class _NeonIcon extends StatelessWidget {
  const _NeonIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? _kNeonLime;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.anton(
                      color: accentColor ?? _kWhite,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(2),
                    Text(subtitle!, style: const TextStyle(color: _kGray, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kBorder, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.anton(color: _kWhite, fontSize: 13, letterSpacing: 0.8),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kNeonLime,
            activeTrackColor: _kNeonLime.withValues(alpha: 0.25),
            inactiveThumbColor: const Color(0xFF555555),
            inactiveTrackColor: const Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  const _ExpandableTile({required this.question, required this.answer});
  final String question;
  final String answer;
  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.anton(color: _kWhite, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: _kNeonLime,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Text(
              widget.answer,
              style: const TextStyle(color: _kGray, fontSize: 13, height: 1.5),
            ),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.selected = false});
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: AppResponsive.font(context, 28).clamp(22.0, 32.0),
      height: AppResponsive.font(context, 28).clamp(22.0, 32.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _kWhite : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: selected
            ? [BoxShadow(color: color.withValues(alpha: 0.65), blurRadius: 10, spreadRadius: 1)]
            : null,
      ),
    );
  }
}
