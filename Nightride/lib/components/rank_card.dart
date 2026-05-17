import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nightride/domain/profile_models.dart';
import 'package:nightride/domain/rank_system.dart';

class RankCard extends StatelessWidget {
  const RankCard({super.key, required this.data});
  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    final pts = data.rank;
    final tier = RankSystem.tierFor(pts);
    final next = RankSystem.nextTier(pts);
    final pct = RankSystem.progress(pts);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: tier.color.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tier.color.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tier.emoji, style: TextStyle(fontSize: 28.sp)),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '$pts pts total',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.streakDays > 0) _StreakPill(days: data.streakDays),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6.h,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(tier.color),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                next != null
                    ? '${pts - tier.minPoints} / ${next.minPoints - tier.minPoints} pts to ${next.name}'
                    : 'Max rank reached!',
                style: TextStyle(color: Colors.white38, fontSize: 10.sp),
              ),
              if (next != null)
                Text(
                  '${next.emoji} ${next.name}',
                  style: TextStyle(
                    color: next.color.withValues(alpha: 0.65),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: const Color(0xFFF97316), size: 13.sp),
          SizedBox(width: 3.w),
          Text(
            '$days day${days == 1 ? "" : "s"}',
            style: TextStyle(
              color: const Color(0xFFF97316),
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
