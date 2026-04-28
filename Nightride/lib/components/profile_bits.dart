// lib/features/profile/presentation/widgets/profile_bits.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class GapH extends StatelessWidget {
  const GapH(this.h, {super.key});
  final double h;

  @override
  Widget build(BuildContext context) => SizedBox(height: h.h);
}
