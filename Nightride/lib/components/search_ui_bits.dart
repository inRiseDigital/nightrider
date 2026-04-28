// lib/features/search/presentation/widgets/search_ui_bits.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class SearchSmoothScrollBehavior extends ScrollBehavior {
  const SearchSmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class GapH extends StatelessWidget {
  const GapH(this.h, {super.key});
  final double h;

  @override
  Widget build(BuildContext context) => Gap(h.h);
}
