// lib/components/home_location_row.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:nightride/core/responsive/app_responsive.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Retro-styled location indicator shown beneath the hero headline.
class HomeLocationRow extends StatelessWidget {
  const HomeLocationRow({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.teal,
            boxShadow: [
              BoxShadow(
                color: AppTheme.teal.withValues(alpha: 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Gap(AppResponsive.gap(context, 6).clamp(4.0, 8.0)),
        Icon(
          Icons.location_on_rounded,
          color: AppTheme.teal,
          size: AppResponsive.icon(context, 14).clamp(12.0, 16.0),
        ),
        Gap(AppResponsive.gap(context, 4).clamp(3.0, 6.0)),
        Expanded(
          child: Text(
            country.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize:
                  AppResponsive.font(context, 12).clamp(10.5, 13.0),
              color: AppTheme.cream.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
