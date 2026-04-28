// lib/features/shell/presentation/pages/app_shell_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/components/app_bottom_nav_bar.dart';
import 'package:nightride/pages/home_page.dart';
import 'package:nightride/pages/map_page.dart';
import 'package:nightride/pages/profile_page.dart';
import 'package:nightride/pages/chat_screen.dart';
import '../providers/app_nav_provider.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  static const List<AppNavItem> _items = <AppNavItem>[
    AppNavItem(icon: Icons.home_rounded), // 0
    AppNavItem(icon: Icons.map_rounded), // 1 ✅ MAP
    AppNavItem(icon: Icons.auto_awesome_rounded), // 2 ✅ AI Chat
    AppNavItem(icon: Icons.person_rounded), // 3
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(appNavProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const <Widget>[
          HomePage(),
          MapPage(),
          ChatScreen(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: _items,
        selectedIndex: index,
        onTap: (int i) => ref.read(appNavProvider.notifier).setIndex(i),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title (Coming soon)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
