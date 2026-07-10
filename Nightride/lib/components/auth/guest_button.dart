import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

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
    final fontSize = AuthDimensions.subtitleFontSize(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white.withValues(alpha: 0.54),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
