import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

// Fixed tab definitions for the retro nightlife nav bar.
// Indices must stay in sync with AppShellPage's IndexedStack:
//   0 = Home, 1 = Explore/Map, 2 = AI Plan/Chat, 3 = Favourites, 4 = Profile
const _kNavAiIndex = 2;

const _kNavIcons = <IconData>[
  Icons.home_outlined,          // 0 Home
  Icons.location_on_outlined,   // 1 Explore / Map
  Icons.auto_awesome_rounded,   // 2 AI Plan (rendered in the bar's bump)
  Icons.favorite_border,        // 3 Favourites
  Icons.person_outline,         // 4 Profile
];

const _kNavLabels = <String>[
  'HOME',
  'EXPLORE',
  'AI PLAN',
  'FAVES',
  'PROFILE',
];

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // The AI Plan tab isn't a separate floating circle — the bar's own top
  // edge bulges up into a dome around it, drawn as one continuous shape
  // (rect ∪ circle) by _BumpBarPainter below.
  static const double _barHeight = 64;
  static const double _bumpRadius = 26;
  // How far the bump's center sits below the bar's flat top edge; smaller
  // values make more of the circle poke out above the bar.
  static const double _bumpSink = 13;
  static const double _topClearance = 8;
  static const double _poke = _bumpRadius - _bumpSink;
  static const double _totalHeight = _barHeight + _poke + _topClearance;
  static const double _rectTopY = _totalHeight - _barHeight;
  static const double _bumpCenterY = _rectTopY + _bumpSink;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final bool aiActive = currentIndex == _kNavAiIndex;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: _totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BumpBarPainter(
                  rectTopY: _rectTopY,
                  bumpCenterY: _bumpCenterY,
                  bumpRadius: _bumpRadius,
                  active: aiActive,
                  accent: accent,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight,
              child: Row(
                children: List.generate(_kNavIcons.length, (i) {
                  final bool active = i == currentIndex;
                  final bool isAiTab = i == _kNavAiIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isAiTab)
                            const SizedBox(height: 20)
                          else
                            Icon(
                              _kNavIcons[i],
                              size: 22,
                              color: active ? accent : Colors.white54,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _kNavLabels[i],
                            style: GoogleFonts.anton(
                              fontSize: 9,
                              letterSpacing: 1.1,
                              color: active ? accent : Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: active ? 16 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: _bumpCenterY - 22,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(_kNavAiIndex),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: _AiSparkle(
                        color: aiActive ? accent : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSparkle extends StatelessWidget {
  const _AiSparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 18, color: color),
        Transform.translate(
          offset: const Offset(6, -6),
          child: Icon(Icons.auto_awesome_rounded, size: 10, color: color),
        ),
      ],
    );
  }
}

/// Paints the bar as a single silhouette: a rounded-top rectangle unioned
/// with a circle, so the AI Plan tab reads as a dome rising out of the bar
/// rather than a disconnected floating badge.
class _BumpBarPainter extends CustomPainter {
  const _BumpBarPainter({
    required this.rectTopY,
    required this.bumpCenterY,
    required this.bumpRadius,
    required this.active,
    required this.accent,
  });

  final double rectTopY;
  final double bumpCenterY;
  final double bumpRadius;
  final bool active;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final Offset bumpCenter = Offset(cx, bumpCenterY);

    final Path rectPath = Path()
      ..addRRect(RRect.fromLTRBAndCorners(
        0,
        rectTopY,
        size.width,
        size.height,
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
      ));
    final Path circlePath = Path()
      ..addOval(Rect.fromCircle(center: bumpCenter, radius: bumpRadius));
    final Path shapePath =
        Path.combine(PathOperation.union, rectPath, circlePath);

    if (active) {
      final Paint glow = Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(bumpCenter, bumpRadius, glow);
    }

    canvas.drawPath(shapePath, Paint()..color = const Color(0xFF0F0F0F));

    canvas.drawPath(
      shapePath,
      Paint()
        ..color = AppTheme.borderGray
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    if (active) {
      final double sink = bumpCenterY - rectTopY;
      final double halfAngle =
          math.acos((sink / bumpRadius).clamp(-1.0, 1.0));
      canvas.drawArc(
        Rect.fromCircle(center: bumpCenter, radius: bumpRadius),
        -math.pi / 2 - halfAngle,
        2 * halfAngle,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BumpBarPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.accent != accent ||
        oldDelegate.rectTopY != rectTopY ||
        oldDelegate.bumpCenterY != bumpCenterY ||
        oldDelegate.bumpRadius != bumpRadius;
  }
}
