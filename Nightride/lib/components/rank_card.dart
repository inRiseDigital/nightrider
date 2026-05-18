import 'package:flutter/material.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
              Text(tier.emoji, style: TextStyle(fontSize: AppResponsive.font(context, 28).clamp(22.0, 32.0))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: TextStyle(
                        color: tier.color,
                        fontSize: AppResponsive.font(context, 16).clamp(14.0, 17.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '$pts pts total',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: AppResponsive.font(context, 11).clamp(10.0, 12.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.streakDays > 0) _StreakPill(days: data.streakDays),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(tier.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                next != null
                    ? '${pts - tier.minPoints} / ${next.minPoints - tier.minPoints} pts to ${next.name}'
                    : 'Max rank reached!',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
                ),
              ),
              if (next != null)
                Text(
                  '${next.emoji} ${next.name}',
                  style: TextStyle(
                    color: next.color.withValues(alpha: 0.65),
                    fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: const Color(0xFFF97316),
            size: AppResponsive.icon(context, 13).clamp(11.0, 15.0),
          ),
          const SizedBox(width: 3),
          Text(
            '$days day${days == 1 ? "" : "s"}',
            style: TextStyle(
              color: const Color(0xFFF97316),
              fontSize: AppResponsive.font(context, 10).clamp(9.0, 11.0),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
