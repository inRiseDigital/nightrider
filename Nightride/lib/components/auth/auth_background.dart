import 'dart:ui';

import 'package:flutter/material.dart';

/// Decorative gradient + glow-blob backdrop shared by all auth screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Pure #070707 base
          Container(color: const Color(0xFF070707)),
          // Subtle pink radial glow top-center
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.75),
                radius: 1.1,
                colors: [
                  const Color(0xFFFF3D73).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.60],
              ),
            ),
          ),
          // Teal glow bottom-right
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, 0.75),
                radius: 0.9,
                colors: [
                  const Color(0xFF62D6C8).withValues(alpha: 0.13),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.70],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: _GlowBlob(
              size: 220,
              color: const Color(0xFFFF3D73).withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            top: 140,
            right: -80,
            child: _GlowBlob(
              size: 240,
              color: const Color(0xFF62D6C8).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 240,
            left: 30,
            child: _GlowBlob(
              size: 200,
              color: const Color(0xFF62D6C8).withValues(alpha: 0.08),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.06)),
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
