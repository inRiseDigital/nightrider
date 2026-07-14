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
        // Google full-width card button
        if (onGoogle != null)
          _GoogleCard(onTap: onGoogle!),
        if (onGoogle != null && (onFacebook != null || onApple != null))
          SizedBox(height: AuthDimensions.gapM(context)),
        // Remaining social icons in a row
        if (onFacebook != null || onApple != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onFacebook != null)
                _SocialIcon(kind: SocialKind.facebook, onTap: onFacebook),
              if (onFacebook != null && onApple != null)
                SizedBox(width: AuthDimensions.gapL(context)),
              if (onApple != null)
                _SocialIcon(kind: SocialKind.apple, onTap: onApple),
            ],
          ),
        // Fallback: if no Google but icons still requested
        if (onGoogle == null && onFacebook == null && onApple == null)
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

class _GoogleCard extends StatelessWidget {
  const _GoogleCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo rendered with colored segments
            _GoogleLogo(size: 20),
            const SizedBox(width: 12),
            const Text(
              'CONTINUE WITH GOOGLE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFAFAFA),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Simple colored "G" using a styled text approach with Google brand colors
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    final double strokeW = size.width * 0.16;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - strokeW / 2);

    // Blue arc (top-right to bottom-right)
    canvas.drawArc(rect, -0.52, 1.74, false,
        Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt);
    // Green arc (bottom-right to bottom-left)
    canvas.drawArc(rect, 1.22, 1.05, false,
        Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt);
    // Yellow arc (bottom-left to top-left)
    canvas.drawArc(rect, 2.27, 1.04, false,
        Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt);
    // Red arc (top-left to top-right)
    canvas.drawArc(rect, 3.31, 1.24, false,
        Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt);

    // Horizontal bar of the G
    final barPaint = Paint()..color = const Color(0xFF4285F4)..strokeWidth = strokeW..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy - strokeW * 0.1),
      Offset(cx + r - strokeW / 2, cy - strokeW * 0.1),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFF333333)),
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
          child: Container(height: 1, color: const Color(0xFF333333)),
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333), width: 1.0),
        ),
        child: Center(
          child: Icon(_icon, size: size * 0.55, color: const Color(0xFFFAFAFA)),
        ),
      ),
    );
  }
}
