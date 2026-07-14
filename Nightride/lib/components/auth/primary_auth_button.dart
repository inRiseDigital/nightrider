import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final height = AuthDimensions.buttonHeight(context);
    final radius = AuthDimensions.buttonBorderRadius(context);
    final fontSize = AuthDimensions.buttonFontSize(context);

    final Widget content = isLoading
        ? SizedBox(
            height: height * 0.42,
            width: height * 0.42,
            child: const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          )
        : Text(
            label.toUpperCase(),
            style: GoogleFonts.anton(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.0,
              color: Colors.black,
            ),
          );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDFFF2F).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GlassMorphismButton(
          onPressed: isLoading ? () {} : onPressed,
          style: GlassMorphismButtonStyle(
            backgroundColor: const Color(0xFFDFFF2F),
            borderRadius: BorderRadius.circular(radius),
            blurIntensity: 14.0,
            height: height,
          ),
          child: content,
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDFFF2F).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDFFF2F),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFFDFFF2F).withValues(alpha: 0.6),
          disabledForegroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: content,
      ),
    );
  }
}
