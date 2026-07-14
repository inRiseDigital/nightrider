// lib/features/shell/presentation/pages/app_shell_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightride/components/app_bottom_nav_bar.dart';
import 'package:nightride/pages/home_page.dart';
import 'package:nightride/pages/map_page.dart';
import 'package:nightride/pages/profile_page.dart';
import 'package:nightride/pages/chat_screen.dart';
import 'package:nightride/pages/favourites_page.dart';
import '../providers/app_nav_provider.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(appNavProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const <Widget>[
          MapPage(),
          HomePage(),
          ChatScreen(),
          FavouritesPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: index,
        onTap: (int i) => ref.read(appNavProvider.notifier).setIndex(i),
      ),
    );
  }
}

