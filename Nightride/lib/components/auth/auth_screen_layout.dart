import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/auth_dimensions.dart';
import 'package:nightride/core/theme/app_theme.dart';

import 'auth_background.dart';
import 'auth_header.dart';

/// Layout shell for all auth screens.
///
/// Composition:
///   Stack
///   ├── AuthBackground (full-bleed)
///   └── SafeArea(bottom: false)
///       └── Column
///           ├── AuthHeader
///           ├── small gap
///           └── Expanded → _FormPanel
///                          ├── rounded-top dark surface w/ glow stroke
///                          └── SingleChildScrollView (centred, max-width)
///                              └── child (form content)
///
/// • Avoids fixed-height bottom panel maths — Expanded gives the form whatever
///   vertical space remains, so the layout naturally adapts to any screen
///   height, orientation, and even keyboard insets.
/// • [maxFormWidth] keeps the form from stretching edge-to-edge on
///   foldables / tablets.
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffold,
      // resizeToAvoidBottomInset is true by default — needed so the inner
      // SingleChildScrollView can scroll content above the keyboard.
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AuthHeader(title: title, subtitle: subtitle),
                SizedBox(height: AuthDimensions.gapL(context)),
                Expanded(child: _FormPanel(child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = AuthDimensions.panelTopRadius(context);
    final maxWidth = AuthDimensions.maxFormWidth(context);
    final hPad = AuthDimensions.horizontalPadding(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0816),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top-edge gradient wash inside the panel.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    topRight: Radius.circular(radius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
              ),
            ),
          ),
          // Glowing 2-dp top stroke.
          Positioned(
            top: 0,
            left: hPad,
            right: hPad,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.primary.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Scrollable form content.
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  AuthDimensions.panelInnerTopPadding(context),
                  hPad,
                  AuthDimensions.panelInnerBottomPadding(context),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
