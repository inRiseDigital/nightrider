import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';

/// "Continue as Guest" text-button at the bottom of the Sign In screen.
class GuestButton extends StatelessWidget {
  const GuestButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AuthDimensions.subtitleFontSize(context),
            color: AppTheme.primaryLight.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
