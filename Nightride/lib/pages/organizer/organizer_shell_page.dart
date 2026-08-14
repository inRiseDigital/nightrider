import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/organizer/organizer_account_page.dart';
import 'package:nightride/pages/organizer/organizer_home_page.dart';
import 'package:nightride/pages/organizer/organizer_tonight_page.dart';
import 'package:nightride/pages/organizer/organizer_venue_page.dart';

/// Four-tab organizer dashboard shell — Home/Events/Venue/Account, matching
/// the Organizer Mobile App Material design. Events keeps the real,
/// Firestore-backed CRUD in [OrganizerHomePage]; Home/Venue/Account are
/// local/mock UI (see those files for why).
class OrganizerShellPage extends ConsumerStatefulWidget {
  const OrganizerShellPage({super.key});

  @override
  ConsumerState<OrganizerShellPage> createState() => _OrganizerShellPageState();
}

class _OrganizerShellPageState extends ConsumerState<OrganizerShellPage> {
  int _index = 0;

  static const _pages = [
    OrganizerTonightPage(),
    OrganizerHomePage(),
    OrganizerVenuePage(),
    OrganizerAccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.space_dashboard_rounded, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.event_rounded, color: Colors.white),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.storefront_rounded, color: Colors.white),
              label: 'Venue',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.manage_accounts_rounded, color: Colors.white),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
