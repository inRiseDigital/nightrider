import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// Fixed tab definitions for the retro nightlife nav bar.
// Indices must stay in sync with AppShellPage's IndexedStack:
//   0 = Map, 1 = Home, 2 = AI/Chat, 3 = Favourites, 4 = Profile
const _kNavIcons = <IconData>[
  Icons.location_on_rounded,   // 0 Map
  Icons.home_rounded,          // 1 Home
  Icons.auto_awesome_rounded,  // 2 AI / Sparkle
  Icons.favorite_rounded,      // 3 Favourites
  Icons.person_rounded,        // 4 Profile
];

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          top: BorderSide(color: AppTheme.borderGray, width: 0.8),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 42,
          child: Row(
            children: List.generate(_kNavIcons.length, (i) {
              final bool active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _kNavIcons[i],
                        size: 20,
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white54,
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: active ? 4 : 0,
                        height: active ? 4 : 0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
