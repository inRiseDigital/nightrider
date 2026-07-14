import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

/// Brand row + page title + subtitle used at the top of every auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.brandLabel = 'NIGHT RITE',
    this.brandLetter = 'NR',
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
                title.toUpperCase(),
                textAlign: TextAlign.left,
                style: GoogleFonts.anton(
                  fontSize: AuthDimensions.titleFontSize(context),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF3EAD6),
                  height: 1.05,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: AuthDimensions.gapS(context)),
              Text(
                subtitle,
                textAlign: TextAlign.left,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.60),
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
            color: const Color(0xFFDFFF2F),
            borderRadius: BorderRadius.circular(size * 0.26),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(width: AuthDimensions.gapM(context)),
        Text(
          label,
          style: GoogleFonts.anton(
            fontSize: AuthDimensions.brandFontSize(context),
            fontWeight: FontWeight.w400,
            color: const Color(0xFF62D6C8),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
