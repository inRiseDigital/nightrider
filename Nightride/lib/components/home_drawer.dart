// lib/components/home_drawer.dart
//
// Side menu opened from the Home tab's hamburger icon.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightride/components/home_language_sheet.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/auth/sign_in_page.dart';
import 'package:nightride/pages/profile_page.dart';
import 'package:nightride/pages/settings_page.dart';
import 'package:nightride/providers/app_nav_provider.dart';
import 'package:nightride/providers/home_providers.dart';
import 'package:nightride/providers/profile_providers.dart';
import 'package:nightride/services/auth_service.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).data;
    final displayName = profile.displayName.isNotEmpty
        ? profile.displayName
        : profile.username.isNotEmpty
            ? profile.username
            : 'YOU';
    final lang = ref.watch(homeLanguageProvider);

    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.anton(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.anton(
                        fontSize: 18,
                        color: AppTheme.cream,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.borderGray, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'PROFILE',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'FAVOURITES',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(appNavProvider.notifier).setIndex(3);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI PLAN MY NIGHT',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(appNavProvider.notifier).setIndex(2);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.language_rounded,
                    label: 'LANGUAGE',
                    trailing: langLabel(lang),
                    onTap: () {
                      Navigator.pop(context);
                      HomeLanguageSheet.show(context, ref);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'SETTINGS',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.borderGray, height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'SIGN OUT',
              accent: AppTheme.hotPink,
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.cream;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.anton(
                  fontSize: 14,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
