// lib/domain/rank_system.dart
import 'package:flutter/material.dart';

class RankTier {
  final String name;
  final String emoji;
  final Color color;
  final int minPoints;
  const RankTier(this.name, this.emoji, this.color, this.minPoints);
}

class RankSystem {
  static const List<RankTier> tiers = [
    RankTier('Newcomer',      '🌱', Color(0xFF4ADE80), 0),
    RankTier('Night Crawler', '🌙', Color(0xFF60A5FA), 100),
    RankTier('Club Hopper',   '🎭', Color(0xFFE879F9), 500),
    RankTier('Party Animal',  '🔥', Color(0xFFF97316), 1000),
    RankTier('VIP',           '⭐', Color(0xFFFBBF24), 2500),
    RankTier('Legend',        '👑', Color(0xFFFF6B6B), 5000),
  ];

  static RankTier tierFor(int points) {
    RankTier current = tiers.first;
    for (final t in tiers) {
      if (points >= t.minPoints) current = t;
    }
    return current;
  }

  static RankTier? nextTier(int points) {
    for (final t in tiers) {
      if (t.minPoints > points) return t;
    }
    return null;
  }

  static double progress(int points) {
    final current = tierFor(points);
    final next = nextTier(points);
    if (next == null) return 1.0;
    final range = next.minPoints - current.minPoints;
    final earned = points - current.minPoints;
    return (earned / range).clamp(0.0, 1.0);
  }

  static const int newcomerBonus = 50;
  static const int dailyLogin = 10;
  static const int likeEvent = 5;
}
