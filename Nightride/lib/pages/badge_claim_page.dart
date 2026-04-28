import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/theme/app_theme.dart';

class BadgeClaimPage extends StatelessWidget {
  const BadgeClaimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      appBar: AppBar(
        title: const Text('Claim Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            // Hero Title
            Text(
              'CONGRATULATIONS!',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Gap(8.h),
            Text(
              'You have unlocked new milestones.',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            Gap(40.h),

            // Progress List
            _TaskItem(
              title: 'Weekend Warrior',
              progress: 1.0,
              isClaimed: false,
              description: 'Attend 3 parties in one weekend',
            ),
            Gap(16.h),
            _TaskItem(
              title: 'Early Bird',
              progress: 1.0,
              isClaimed: true,
              description: 'Check in before 10 PM',
            ),
            Gap(16.h),
            _TaskItem(
              title: 'Social Butterfly',
              progress: 0.7,
              isClaimed: false,
              description: 'Connect with 20 new people',
            ),
            
            Gap(50.h),
            
            // New Badge Preview
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                   _BadgePreview(),
                   Gap(20.h),
                   Text(
                     'PART STARTER BADGE',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 16.sp,
                       fontWeight: FontWeight.w900,
                     ),
                   ),
                   Gap(8.h),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       _MiniChip(label: '+500 XP', color: Colors.blueAccent),
                       Gap(8.w),
                       _MiniChip(label: 'Exclusive Access', color: Colors.pinkAccent),
                     ],
                   ),
                ],
              ),
            ),
            
            Gap(60.h),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rewards Claimed!')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: const Text('CLAIM ALL REWARDS'),
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    required this.progress,
    required this.isClaimed,
    required this.description,
  });

  final String title;
  final double progress;
  final bool isClaimed;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isClaimed 
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isClaimed)
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20)
              else if (progress >= 1.0)
                Text('READY', style: TextStyle(color: AppTheme.primaryLight, fontSize: 11.sp, fontWeight: FontWeight.w900))
              else
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
            ],
          ),
          Gap(4.h),
          Text(description, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
          Gap(12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.greenAccent : AppTheme.primary),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Image.network(
          'https://cdn-icons-png.flaticon.com/512/8644/8644445.png',
          width: 60.w,
          color: Colors.white,
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
