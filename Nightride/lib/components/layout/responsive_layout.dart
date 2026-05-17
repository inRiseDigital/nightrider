import 'package:flutter/material.dart';
import 'package:nightride/core/responsive/app_dimensions.dart';

/// Applies responsive horizontal padding via [AppDimensions.pagePaddingHorizontal].
///
/// Use as the outermost padding around scrollable page content so all pages
/// share consistent horizontal gutters per form factor.
class ResponsivePagePadding extends StatelessWidget {
  const ResponsivePagePadding({
    super.key,
    required this.child,
    this.includeVertical = false,
  });

  final Widget child;

  /// When true, also applies [AppDimensions.pagePaddingTop] / `pagePaddingBottom`.
  final bool includeVertical;

  @override
  Widget build(BuildContext context) {
    final h = AppDimensions.pagePaddingHorizontal(context);
    return Padding(
      padding: includeVertical
          ? EdgeInsets.fromLTRB(
              h,
              AppDimensions.pagePaddingTop(context),
              h,
              AppDimensions.pagePaddingBottom(context),
            )
          : EdgeInsets.symmetric(horizontal: h),
      child: child,
    );
  }
}

/// Centres [child] horizontally with a max-width cap that scales by form factor.
///
/// Pass [tight] (default true) so the inner box still fills the width up to
/// the cap; otherwise the box hugs its child.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
    this.tight = true,
  });

  final Widget child;

  /// Override the cap. Defaults to [AppDimensions.contentMaxWidth].
  final double? maxWidth;
  final AlignmentGeometry alignment;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? AppDimensions.contentMaxWidth(context);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: tight ? SizedBox(width: cap.isFinite ? cap : null, child: child) : child,
      ),
    );
  }
}

/// Convenience: vertical gap from the [AppDimensions] scale.
/// Usage: `const ResponsiveGap.section()` or `ResponsiveGap.l()`.
class ResponsiveGap extends StatelessWidget {
  const ResponsiveGap.xs({super.key}) : _kind = _GapKind.xs;
  const ResponsiveGap.s({super.key}) : _kind = _GapKind.s;
  const ResponsiveGap.m({super.key}) : _kind = _GapKind.m;
  const ResponsiveGap.l({super.key}) : _kind = _GapKind.l;
  const ResponsiveGap.xl({super.key}) : _kind = _GapKind.xl;
  const ResponsiveGap.section({super.key}) : _kind = _GapKind.section;
  const ResponsiveGap.subSection({super.key}) : _kind = _GapKind.subSection;

  final _GapKind _kind;

  @override
  Widget build(BuildContext context) {
    final h = switch (_kind) {
      _GapKind.xs => AppDimensions.gapXS(context),
      _GapKind.s => AppDimensions.gapS(context),
      _GapKind.m => AppDimensions.gapM(context),
      _GapKind.l => AppDimensions.gapL(context),
      _GapKind.xl => AppDimensions.gapXL(context),
      _GapKind.section => AppDimensions.sectionGap(context),
      _GapKind.subSection => AppDimensions.subSectionGap(context),
    };
    return SizedBox(height: h);
  }
}

enum _GapKind { xs, s, m, l, xl, section, subSection }
