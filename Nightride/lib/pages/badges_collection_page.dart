import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';
import 'package:nightride/pages/badge_claim_page.dart';

class BadgesCollectionPage extends StatelessWidget {
  const BadgesCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        title: const Text('My Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Gap(20),
            // Featured Badge Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    _BadgeImage(size: AppResponsive.gap(context, 100).clamp(80.0, 110.0)),
                    const Gap(20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nightride Elite',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Earned for attending 10+ parties in a month.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: AppResponsive.font(context, 13).clamp(11.0, 14.0),
                            ),
                          ),
                          const Gap(12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _MiniChip(label: 'Rare', color: Colors.amber),
                              _MiniChip(label: 'Elite', color: AppTheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(30),
            // Badges Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final bool unlocked = index < 4;
                  return _BadgeGridItem(unlocked: unlocked);
                },
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, AppResponsive.gap(context, 30).clamp(20.0, 36.0)),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BadgeClaimPage()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: Size(double.infinity, AppResponsive.gap(context, 54).clamp(44.0, 60.0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('CLAIM NEW BADGES'),
        ),
      ),
    );
  }
}

class _BadgeGridItem extends StatelessWidget {
  const _BadgeGridItem({required this.unlocked});
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Opacity(
            opacity: unlocked ? 1.0 : 0.3,
            child: _BadgeImage(size: AppResponsive.gap(context, 80).clamp(64.0, 90.0)),
          ),
        ),
        const Gap(8),
        Container(
          height: 14,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: unlocked ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _BadgeImage extends StatelessWidget {
  const _BadgeImage({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Using a custom container to represent the badge from the UI
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Image.network(
          'https://cdn-icons-png.flaticon.com/512/8644/8644445.png', // Shield Icon
          color: Colors.pinkAccent,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppResponsive.font(context, 10).clamp(8.0, 11.0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
