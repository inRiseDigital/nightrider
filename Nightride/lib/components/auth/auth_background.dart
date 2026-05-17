import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Decorative gradient + glow-blob backdrop shared by all auth screens.
/// Fully self-contained — uses no ScreenUtil scaling.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4B3A6A), Color(0xFF251A3B), Color(0xFF0A0712)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.15, -0.35),
                radius: 1.15,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -70,
            child: _GlowBlob(
              size: 240,
              color: AppTheme.primary.withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            top: 120,
            right: -90,
            child: _GlowBlob(
              size: 260,
              color: AppTheme.accent.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 220,
            left: 40,
            child: _GlowBlob(
              size: 210,
              color: AppTheme.primaryLight.withValues(alpha: 0.14),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.10)),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
