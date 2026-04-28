import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/organizer/organizer_home_page.dart';
import 'package:nightride/pages/profile_page.dart';

class OrganizerShellPage extends ConsumerStatefulWidget {
  const OrganizerShellPage({super.key});

  @override
  ConsumerState<OrganizerShellPage> createState() => _OrganizerShellPageState();
}

class _OrganizerShellPageState extends ConsumerState<OrganizerShellPage> {
  int _index = 0;

  static const _pages = [
    OrganizerHomePage(),
    _StatsPage(),
    ProfilePage(),
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
              icon: Icon(Icons.event_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.event_rounded, color: Colors.white),
              label: 'My Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: Colors.white),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.white54),
              selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPage extends StatelessWidget {
  const _StatsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('Analytics', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Coming soon', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
