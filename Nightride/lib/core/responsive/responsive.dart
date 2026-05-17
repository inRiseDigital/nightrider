import 'package:flutter/widgets.dart';

/// Device form factor categories. Used to dispatch responsive values
/// without resorting to brittle pixel math.
enum FormFactor {
  /// Very small phones (shortestSide < 360 dp).
  compact,

  /// Typical phones (360–599 dp).
  regular,

  /// Foldables (e.g. Honor Magic V3 unfolded), large phones, small tablets (600–839 dp).
  foldable,

  /// Tablets and larger (≥ 840 dp).
  tablet,
}

/// Width breakpoints in logical pixels (dp). These match Material 3's window-size classes.
abstract class Breakpoints {
  static const double compact = 360;
  static const double regular = 600;
  static const double foldable = 840;
}

/// MediaQuery-backed helpers for picking values per form factor.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get shortestSide => screenSize.shortestSide;
  bool get isLandscape => screenWidth > screenHeight;

  FormFactor get formFactor {
    final s = shortestSide;
    if (s < Breakpoints.compact) return FormFactor.compact;
    if (s < Breakpoints.regular) return FormFactor.regular;
    if (s < Breakpoints.foldable) return FormFactor.foldable;
    return FormFactor.tablet;
  }

  bool get isCompact => formFactor == FormFactor.compact;
  bool get isRegular => formFactor == FormFactor.regular;
  bool get isFoldable => formFactor == FormFactor.foldable;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isWide => screenWidth >= Breakpoints.regular;

  /// Pick a value by form factor. Foldable falls back to regular,
  /// tablet falls back to foldable → regular.
  T responsive<T>({
    required T compact,
    required T regular,
    T? foldable,
    T? tablet,
  }) {
    switch (formFactor) {
      case FormFactor.compact:
        return compact;
      case FormFactor.regular:
        return regular;
      case FormFactor.foldable:
        return foldable ?? regular;
      case FormFactor.tablet:
        return tablet ?? foldable ?? regular;
    }
  }
}
