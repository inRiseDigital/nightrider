import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Decorative gradient + glow-blob backdrop shared by all auth screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Pure black base
          Container(color: const Color(0xFF000000)),
          // Subtle pink radial glow top-left
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.6, -0.5),
                radius: 1.0,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65],
              ),
            ),
          ),
          // Teal glow bottom-right
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, 0.6),
                radius: 0.9,
                colors: [
                  AppTheme.primaryLight.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              size: 220,
              color: AppTheme.primary.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 140,
            right: -80,
            child: _GlowBlob(
              size: 240,
              color: AppTheme.accent.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 240,
            left: 30,
            child: _GlowBlob(
              size: 200,
              color: AppTheme.primaryLight.withValues(alpha: 0.12),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.08)),
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
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
