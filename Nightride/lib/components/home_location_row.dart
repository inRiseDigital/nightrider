// lib/features/home/presentation/widgets/home_location_row.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/theme/app_theme.dart';

class HomeLocationRow extends StatelessWidget {
  const HomeLocationRow({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          Icons.location_on_rounded,
          color: AppTheme.primaryLight,
          size: AppResponsive.icon(context, 16).clamp(14.0, 18.0),
        ),
        Gap(AppResponsive.gap(context, 6).clamp(4.0, 8.0)),
        Expanded(
          child: Text(
            country,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppResponsive.font(context, 13).clamp(11.5, 14.0),
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
