// lib/common/widgets/auth_process_scaffold.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

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
        : 22.w;
    final horizontalPadding = EdgeInsets.symmetric(horizontal: hPad);

    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      body: Stack(
        children: [
          const RepaintBoundary(child: _AuthProcessBackground()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: horizontalPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Gap(18.h),

                          // Brand row (fixed start)
                          Row(
                            children: [
                              Container(
                                width: 38.sp,
                                height: 38.sp,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'N',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              Gap(12.w),
                              Text(
                                'Nightride',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryLight.withOpacity(
                                    0.95,
                                  ),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),

                          Gap(titleTopGap.h),

                          // ✅ Title and subtitle ALWAYS start from EXACT same X.
                          // Title: unlimited width (wraps naturally, start stays same)
                          Text(
                            title,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryLight,
                              height: 1.05,
                              letterSpacing: 0.2,
                            ),
                          ),

                          Gap(12.h),

                          Text(
                            subtitle,
                            textAlign: TextAlign.left,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              height: 1.35,
                              color: AppTheme.primaryLight.withOpacity(0.55),
                              letterSpacing: 0.1,
                            ),
                          ),

                          const Spacer(),

                          Gap(reservedBottomGap.h),
                        ],
                      ),
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
              colors: [AppTheme.primary.withOpacity(0.12), Colors.transparent],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        Positioned(
          top: -90.h,
          left: -70.w,
          child: _GlowBlob(
            size: 240.w,
            color: AppTheme.primary.withOpacity(0.26),
          ),
        ),
        Positioned(
          top: 120.h,
          right: -90.w,
          child: _GlowBlob(
            size: 260.w,
            color: AppTheme.accent.withOpacity(0.12),
          ),
        ),
        Positioned(
          bottom: 220.h,
          left: 40.w,
          child: _GlowBlob(
            size: 210.w,
            color: AppTheme.primaryLight.withOpacity(0.14),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.10)),
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
