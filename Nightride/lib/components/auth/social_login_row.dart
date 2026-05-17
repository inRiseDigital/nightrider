import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';

enum SocialKind { google, facebook, apple }

/// Optional "Or sign with" divider + a centered row of social-login icons.
/// Pass `dividerLabel: null` to omit the divider.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({
    super.key,
    this.dividerLabel,
    this.onGoogle,
    this.onFacebook,
    this.onApple,
  });

  final String? dividerLabel;
  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dividerLabel != null) ...[
          _Divider(label: dividerLabel!),
          SizedBox(height: AuthDimensions.gapM(context)),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(kind: SocialKind.google, onTap: onGoogle),
            SizedBox(width: AuthDimensions.gapL(context)),
            _SocialIcon(kind: SocialKind.facebook, onTap: onFacebook),
            SizedBox(width: AuthDimensions.gapL(context)),
            _SocialIcon(kind: SocialKind.apple, onTap: onApple),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AuthDimensions.subtitleFontSize(context) - 1,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.kind, this.onTap});
  final SocialKind kind;
  final VoidCallback? onTap;

  IconData get _icon => switch (kind) {
        SocialKind.google => Icons.g_mobiledata_rounded,
        SocialKind.facebook => Icons.facebook_rounded,
        SocialKind.apple => Icons.apple,
      };

  @override
  Widget build(BuildContext context) {
    final size = AuthDimensions.socialIconSize(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(_icon, size: size * 0.85, color: Colors.white),
        ),
      ),
    );
  }
}
