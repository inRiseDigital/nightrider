// lib/common/widgets/auth_process_scaffold.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/responsive/app_responsive.dart';
import '../../core/theme/app_theme.dart';

class AuthProcessScaffold extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Only vertical spacing controls (horizontal start is FIXED for all pages)
  final double titleTopGap;
  final double reservedBottomGap;

  final Widget bottomPanel;
  final Widget? bottomOverlay;

  const AuthProcessScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bottomPanel,
    this.bottomOverlay,
    this.titleTopGap = 62,
    this.reservedBottomGap = 380,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final hPad = screenW > 600
        ? ((screenW - (screenW * 0.88).clamp(460.0, 640.0)) / 2).clamp(16.0, 80.0)
        : AppResponsive.gap(context, 22).clamp(18.0, 28.0);
    final horizontalPadding = EdgeInsets.symmetric(horizontal: hPad);

    final brandIconSize = AppResponsive.gap(context, 38).clamp(34.0, 44.0);
    final brandRadius = AppResponsive.radius(context, 10).clamp(8.0, 12.0);
    final brandFont = AppResponsive.font(context, 18).clamp(15.0, 20.0);
    final titleFont = AppResponsive.font(context, 34).clamp(26.0, 38.0);
    final subtitleFont = AppResponsive.font(context, 14.5).clamp(12.0, 16.0);

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: Stack(
        children: [
          const RepaintBoundary(child: _AuthProcessBackground()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compute effective topGap so content never overflows the safe area.
                // Fixed overhead: top gap ~20, brand row ~44, title ~42, subtitle gap ~12, subtitle ~22.
                const fixedOverhead = 140.0;
                final effectiveTopGap = titleTopGap.clamp(
                  0.0,
                  (constraints.maxHeight - reservedBottomGap - fixedOverhead).clamp(0.0, titleTopGap),
                );

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: horizontalPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gap(AppResponsive.gap(context, 18).clamp(14.0, 22.0)),

                        // Brand row
                        Row(
                          children: [
                            Container(
                              width: brandIconSize,
                              height: brandIconSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(brandRadius),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'N',
                                style: TextStyle(
                                  fontSize: brandFont,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            Gap(AppResponsive.gap(context, 12).clamp(10.0, 14.0)),
                            Text(
                              'Nightride',
                              style: TextStyle(
                                fontSize: brandFont,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryLight.withValues(alpha:0.95),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),

                        Gap(effectiveTopGap),

                        Text(
                          title,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: titleFont,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryLight,
                            height: 1.05,
                            letterSpacing: 0.2,
                          ),
                        ),

                        Gap(AppResponsive.gap(context, 12).clamp(10.0, 14.0)),

                        Text(
                          subtitle,
                          textAlign: TextAlign.left,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: subtitleFont,
                            height: 1.35,
                            color: AppTheme.primaryLight.withValues(alpha:0.55),
                            letterSpacing: 0.1,
                          ),
                        ),

                        SizedBox(height: reservedBottomGap),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(child: bottomPanel),
          ),

          if (bottomOverlay != null) bottomOverlay!,
        ],
      ),
    );
  }
}

class _AuthProcessBackground extends StatelessWidget {
  const _AuthProcessBackground();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Stack(
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
              colors: [AppTheme.primary.withValues(alpha:0.12), Colors.transparent],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        Positioned(
          top: sh * -0.10,
          left: sw * -0.18,
          child: _GlowBlob(
            size: sw * 0.62,
            color: AppTheme.primary.withValues(alpha:0.26),
          ),
        ),
        Positioned(
          top: sh * 0.14,
          right: sw * -0.23,
          child: _GlowBlob(
            size: sw * 0.66,
            color: AppTheme.accent.withValues(alpha:0.12),
          ),
        ),
        Positioned(
          bottom: sh * 0.26,
          left: sw * 0.10,
          child: _GlowBlob(
            size: sw * 0.54,
            color: AppTheme.primaryLight.withValues(alpha:0.14),
          ),
        ),
        Container(color: Colors.black.withValues(alpha:0.10)),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

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
