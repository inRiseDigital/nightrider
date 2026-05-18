import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nightride/core/responsive/app_responsive.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero Title
            Text(
              'CONGRATULATIONS!',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: AppResponsive.font(context, 24).clamp(20.5, 26.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Gap(8),
            Text(
              'You have unlocked new milestones.',
              style: TextStyle(color: Colors.white70, fontSize: AppResponsive.font(context, 14).clamp(12.0, 15.0)),
            ),
            const Gap(40),

            // Progress List
            _TaskItem(
              title: 'Weekend Warrior',
              progress: 1.0,
              isClaimed: false,
              description: 'Attend 3 parties in one weekend',
            ),
            const Gap(16),
            _TaskItem(
              title: 'Early Bird',
              progress: 1.0,
              isClaimed: true,
              description: 'Check in before 10 PM',
            ),
            const Gap(16),
            _TaskItem(
              title: 'Social Butterfly',
              progress: 0.7,
              isClaimed: false,
              description: 'Connect with 20 new people',
            ),

            const Gap(50),

            // New Badge Preview
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                   _BadgePreview(),
                   const Gap(20),
                   Text(
                     'PART STARTER BADGE',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: AppResponsive.font(context, 16).clamp(14.0, 17.5),
                       fontWeight: FontWeight.w900,
                     ),
                   ),
                   const Gap(8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       _MiniChip(label: '+500 XP', color: Colors.blueAccent),
                       const Gap(8),
                       _MiniChip(label: 'Exclusive Access', color: Colors.pinkAccent),
                     ],
                   ),
                ],
              ),
            ),

            const Gap(60),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rewards Claimed!')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
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
                style: TextStyle(color: Colors.white, fontSize: AppResponsive.font(context, 15).clamp(12.5, 16.5), fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isClaimed)
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20)
              else if (progress >= 1.0)
                Text('READY', style: TextStyle(color: AppTheme.primaryLight, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0), fontWeight: FontWeight.w900))
              else
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 11).clamp(9.5, 12.0))),
            ],
          ),
          const Gap(4),
          Text(description, style: TextStyle(color: Colors.white54, fontSize: AppResponsive.font(context, 12).clamp(10.5, 13.0))),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.greenAccent : AppTheme.primary),
              minHeight: 6,
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
      width: AppResponsive.font(context, 120).clamp(100.0, 132.0),
      height: AppResponsive.font(context, 120).clamp(100.0, 132.0),
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
          width: 60,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: AppResponsive.font(context, 10).clamp(8.5, 11.0), fontWeight: FontWeight.bold),
      ),
    );
  }
}
