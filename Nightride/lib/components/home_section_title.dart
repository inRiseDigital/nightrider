// lib/features/home/presentation/widgets/home_section_title.dart
import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_responsive.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppResponsive.font(context, 18).clamp(15.0, 20.0),
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
