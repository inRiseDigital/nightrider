import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';

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
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: GlassMorphismButton(
          onPressed: isLoading ? () {} : onPressed,
          style: GlassMorphismButtonStyle(
            backgroundColor: AppTheme.primary,
            borderRadius: BorderRadius.circular(radius),
            blurIntensity: 14.0,
            height: height,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
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
