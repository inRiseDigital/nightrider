import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Brand row + page title + subtitle stack used at the top of every auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.brandLabel = 'Nightride',
    this.brandLetter = 'N',
  });

  final String title;
  final String subtitle;
  final String brandLabel;
  final String brandLetter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AuthDimensions.horizontalPadding(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AuthDimensions.maxFormWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AuthDimensions.headerTopPadding(context)),
              _BrandRow(label: brandLabel, letter: brandLetter),
              SizedBox(height: AuthDimensions.brandToTitleGap(context)),
              Text(
                title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: AuthDimensions.titleFontSize(context),
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryLight,
                  height: 1.05,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: AuthDimensions.gapS(context)),
              Text(
                subtitle,
                textAlign: TextAlign.left,
                softWrap: true,
                style: TextStyle(
                  fontSize: AuthDimensions.subtitleFontSize(context),
                  height: 1.35,
                  color: AppTheme.primaryLight.withValues(alpha: 0.6),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.label, required this.letter});
  final String label;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final size = AuthDimensions.brandLogoSize(context);
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(size * 0.26),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.48,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
        SizedBox(width: AuthDimensions.gapM(context)),
        Text(
          label,
          style: TextStyle(
            fontSize: AuthDimensions.brandFontSize(context),
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryLight.withValues(alpha: 0.95),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
