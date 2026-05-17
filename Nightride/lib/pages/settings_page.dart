import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/components/home_language_sheet.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/data/services/privacy_service.dart';
import 'package:nightride/l10n/app_localizations.dart';
import 'package:nightride/pages/admin/admin_panel_page.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/edit_profile_page.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/providers/settings_providers.dart';
import 'package:nightride/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: Text(l.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          _SettingsSection(
            title: l.account,
            children: [
              _NavigableTile(
                icon: Icons.person_outline_rounded,
                label: l.editProfile,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                ),
              ),
              _NavigableTile(
                icon: Icons.notifications_none_rounded,
                label: l.notifications,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _NotificationsPage()),
                ),
              ),
              _NavigableTile(
                icon: Icons.lock_outline_rounded,
                label: l.privacySecurity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _PrivacyPage()),
                ),
              ),
            ],
          ),
          Gap(24.h),
          _SettingsSection(
            title: l.preferences,
            children: [
              _NavigableTile(
                icon: Icons.palette_outlined,
                label: l.appearance,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AppearancePage()),
                ),
              ),
              _NavigableTile(
                icon: Icons.language_rounded,
                label: l.language,
                onTap: () => HomeLanguageSheet.show(context, ref),
              ),
            ],
          ),
          Gap(24.h),
          _SettingsSection(
            title: l.support,
            children: [
              _NavigableTile(
                icon: Icons.help_outline_rounded,
                label: l.helpCenter,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _HelpCenterPage()),
                ),
              ),
              _NavigableTile(
                icon: Icons.info_outline_rounded,
                label: l.aboutNightride,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AboutPage()),
                ),
              ),
            ],
          ),
          if (ref.watch(isAdminProvider).asData?.value == true) ...[
            Gap(24.h),
            _SettingsSection(
              title: 'Admin',
              children: [
                _NavigableTile(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin Panel',
                  iconColor: AppTheme.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                  ),
                ),
              ],
            ),
          ],
          Gap(40.h),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                  (route) => false,
                );
              }
            },
            child: Text(l.logOut, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Notifications ────────────────────────────────────────────────────────────

class _NotificationsPage extends ConsumerStatefulWidget {
  const _NotificationsPage();
  @override
  ConsumerState<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<_NotificationsPage> {
  bool _eventAlerts = true;
  bool _nearbyEvents = true;
  bool _friendActivity = false;
  bool _promotions = false;
  bool _appUpdates = true;

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Notifications',
      child: Column(
        children: [
          _SwitchSection(title: 'Events', children: [
            _SwitchTile(label: 'Event alerts & reminders', value: _eventAlerts, onChanged: (v) => setState(() => _eventAlerts = v)),
            _SwitchTile(label: 'Events near me', value: _nearbyEvents, onChanged: (v) => setState(() => _nearbyEvents = v)),
          ]),
          Gap(24.h),
          _SwitchSection(title: 'Social', children: [
            _SwitchTile(label: 'Friend activity', value: _friendActivity, onChanged: (v) => setState(() => _friendActivity = v)),
          ]),
          Gap(24.h),
          _SwitchSection(title: 'Other', children: [
            _SwitchTile(label: 'Promotions & deals', value: _promotions, onChanged: (v) => setState(() => _promotions = v)),
            _SwitchTile(label: 'App updates', value: _appUpdates, onChanged: (v) => setState(() => _appUpdates = v)),
          ]),
        ],
      ),
    );
  }
}

// ── Delete account ───────────────────────────────────────────────────────────

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
      content: const Text(
        'This will permanently delete your account and all your data. This cannot be undone.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Delete all user data — subcollections must be removed before the parent doc
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(uid);

    final subcollections = await Future.wait([
      userRef.collection('favourites').get(),
      userRef.collection('chat_sessions').get(),
      userRef.collection('settings').get(),
    ]);

    final batch = db.batch();
    for (final snap in subcollections) {
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(userRef);
    batch.delete(db.collection('avatars').doc(uid));
    await batch.commit();

    // Clear onboarding so it shows again on next launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('ob_ageRange');
    await prefs.remove('ob_genres');
    await prefs.remove('ob_vibes');
    await prefs.remove('ob_features');
    await prefs.remove('ob_goOutTime');
    await prefs.remove('ob_budget');

    // Delete Firebase Auth account
    await user.delete();

    // Sign out and go to sign-in (onboarding will show after they create a new account)
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    if (e.code == 'requires-recent-login') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign out and sign in again before deleting your account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete account. Please try again.'), backgroundColor: Colors.redAccent),
      );
    }
  }
}

// ── Privacy & Security ───────────────────────────────────────────────────────

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
      title: 'Privacy & Security',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load settings', style: TextStyle(color: Colors.white54))),
        data: (s) => Column(
          children: [
            _SwitchSection(title: 'Profile', children: [
              _SwitchTile(
                label: 'Public profile',
                value: s.publicProfile,
                onChanged: (v) => toggle((s) => s.copyWith(publicProfile: v)),
              ),
              _SwitchTile(
                label: 'Show location to friends',
                value: s.showLocation,
                onChanged: (v) => toggle((s) => s.copyWith(showLocation: v)),
              ),
              _SwitchTile(
                label: 'Show activity status',
                value: s.showActivity,
                onChanged: (v) => toggle((s) => s.copyWith(showActivity: v)),
              ),
            ]),
            Gap(24.h),
            _SwitchSection(title: 'Security', children: [
              _SwitchTile(
                label: 'Two-factor authentication',
                value: s.twoFactor,
                onChanged: (v) => toggle((s) => s.copyWith(twoFactor: v)),
              ),
            ]),
            Gap(24.h),
            _InfoTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Account',
              color: Colors.redAccent,
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appearance ───────────────────────────────────────────────────────────────

class _AppearancePage extends ConsumerWidget {
  const _AppearancePage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(homeDarkToggleProvider);
    final selectedIdx = ref.watch(accentColorIndexProvider);
    return _SubPage(
      title: 'Appearance',
      child: Column(
        children: [
          _SwitchSection(title: 'Theme', children: [
            _SwitchTile(
              label: 'Dark mode',
              subtitle: 'Use the dark theme across the app',
              value: isDark,
              onChanged: (v) => ref.read(homeDarkToggleProvider.notifier).state = v,
            ),
          ]),
          Gap(24.h),
          _SettingsSection(
            title: 'Accent color',
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(kAccentColors.length, (i) => GestureDetector(
                    onTap: () => ref.read(accentColorIndexProvider.notifier).state = i,
                    child: _ColorDot(color: kAccentColors[i], selected: selectedIdx == i),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Help Center ──────────────────────────────────────────────────────────────

class _HelpCenterPage extends StatelessWidget {
  const _HelpCenterPage();
  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Help Center',
      child: Column(
        children: [
          _SettingsSection(title: 'FAQs', children: [
            _ExpandableTile(
              question: 'How do I find events near me?',
              answer: 'Go to the Map tab and allow location access. Events near you will appear as pins on the map.',
            ),
            _ExpandableTile(
              question: 'How do I buy tickets?',
              answer: 'Open any event and tap "GET TICKETS". You\'ll be redirected to the official ticketing page.',
            ),
            _ExpandableTile(
              question: 'Can I filter events by genre?',
              answer: 'Yes! Use the category rail on the home page to filter by EDM, Techno, House, DJ, and more.',
            ),
            _ExpandableTile(
              question: 'How do I change the app language?',
              answer: 'Go to Settings → Language and select from 12 available languages.',
            ),
          ]),
          Gap(24.h),
          _SettingsSection(title: 'Contact', children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'support@nightride.app',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }
}

// ── About ────────────────────────────────────────────────────────────────────

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
      title: 'About Nightride',
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Gap(12.h),
                Container(
                  width: 80.sp,
                  height: 80.sp,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.nightlife_rounded, color: AppTheme.primary, size: 40.sp),
                ),
                Gap(14.h),
                Text('Nightride', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w900)),
                Gap(4.h),
                Text(_version, style: TextStyle(color: Colors.white54, fontSize: 13.sp)),
                Gap(24.h),
              ],
            ),
          ),
          _SettingsSection(title: 'Info', children: [
            _InfoTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
            _InfoTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            _InfoTile(icon: Icons.code_rounded, label: 'Open Source Licenses', onTap: () {}),
          ]),
        ],
      ),
    );
  }
}

// ── Shared sub-page scaffold ─────────────────────────────────────────────────

class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffold,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: child,
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        Gap(12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchSection extends StatelessWidget {
  const _SwitchSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _SettingsSection(title: title, children: children);
}

class _NavigableTile extends StatelessWidget {
  const _NavigableTile({required this.icon, required this.label, required this.onTap, this.iconColor = Colors.white70});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20.sp),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.label, required this.value, required this.onChanged, this.subtitle});
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.onTap, this.color = Colors.white70});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20.sp),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
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
        ListTile(
          title: Text(widget.question, style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
          trailing: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.white38, size: 20.sp),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
            child: Text(widget.answer, style: TextStyle(color: Colors.white60, fontSize: 13.sp, height: 1.5)),
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
    return Container(
      width: 34.sp,
      height: 34.sp,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : null,
      ),
    );
  }
}
