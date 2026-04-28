import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
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
            Gap(20.h),
            // Featured Badge Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    _BadgeImage(size: 100.w),
                    Gap(20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nightride Elite',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Gap(4.h),
                          Text(
                            'Earned for attending 10+ parties in a month.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                          ),
                          Gap(12.h),
                          Wrap(
                            spacing: 8.w,
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
            Gap(30.h),
            // Badges Grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 20.h,
                  childAspectRatio: 0.8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final bool unlocked = index < 4;
                  return _BadgeGridItem(unlocked: unlocked);
                },
              ),
            ),
            Gap(40.h),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 30.h),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BadgeClaimPage()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: Size(double.infinity, 54.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
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
            child: _BadgeImage(size: 80.w),
          ),
        ),
        Gap(8.h),
        Container(
          height: 14.h,
          width: 50.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: unlocked ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(4.r),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
