import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// Inline "Don't have an account? Sign Up"-style prompt + tappable link,
/// centered horizontally. Reused on Sign In / Sign Up / Forgot Password.
class AuthFooterLinks extends StatelessWidget {
  const AuthFooterLinks({
    super.key,
    required this.prompt,
    required this.linkText,
    required this.onLinkTap,
  });

  final String prompt;
  final String linkText;
  final VoidCallback onLinkTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = AuthDimensions.subtitleFontSize(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$prompt ',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: onLinkTap,
          child: Text(
            linkText,
            style: TextStyle(
              fontSize: fontSize,
              color: AppTheme.primaryLight.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
