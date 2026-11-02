import 'package:flutter/material.dart';

/// Responsive breakpoint constants and helpers
class ResponsiveBreakpoints {
  // Material adaptive layout breakpoints (logical pixels).
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Extension on BuildContext to provide responsive helpers
extension ResponsiveContext on BuildContext {
  /// Current screen width in logical pixels
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Current screen height in logical pixels
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Compact phone layout.
  bool get isMobile => screenWidth < ResponsiveBreakpoints.mobile;

  /// Tablet-sized layout, including landscape tablets and narrow desktop panes.
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.mobile &&
      screenWidth < ResponsiveBreakpoints.desktop;

  /// Desktop layout.
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktop;

  /// Wide desktop layout.
  bool get isLargeDesktop => screenWidth >= ResponsiveBreakpoints.largeDesktop;

  /// True for medium and larger layouts.
  bool get isWideScreen => screenWidth >= ResponsiveBreakpoints.tablet;

  /// Get device type for conditional logic
  DeviceType get deviceType {
    if (isMobile) return DeviceType.mobile;
    if (isTablet) return DeviceType.tablet;
    if (isLargeDesktop) return DeviceType.largeDesktop;
    return DeviceType.desktop;
  }

  /// Safe area padding accounting for notches, system UI, etc.
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// View padding accounting for system UI
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;

  /// Device orientation
  Orientation get orientation => MediaQuery.of(this).orientation;

  /// True if device is in landscape
  bool get isLandscape => orientation == Orientation.landscape;

  /// True if device is in portrait
  bool get isPortrait => orientation == Orientation.portrait;
}

/// Device type enumeration for conditional UI logic
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  /// True if device is mobile or tablet (touch-friendly)
  bool get isTouch => this == DeviceType.mobile || this == DeviceType.tablet;

  /// True if device is desktop-class (keyboard/mouse)
  bool get isDesktopClass =>
      this == DeviceType.desktop || this == DeviceType.largeDesktop;
}

/// Constrained width widget for centering content on wide screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final Alignment alignment;

  const ResponsiveContainer({
    required this.child,
    this.maxWidth = 600,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = Alignment.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;

    if (screenWidth <= maxWidth + (padding.horizontal * 2)) {
      // Screen is narrow enough, no constraining needed
      return Padding(padding: padding, child: child);
    }

    // Center content with max-width constraint
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Adaptive padding that scales based on screen size
class AdaptivePadding extends EdgeInsets {
  factory AdaptivePadding.fromContext(
    BuildContext context, {
    double mobilePadding = 16,
    double tabletPadding = 24,
    double desktopPadding = 32,
  }) {
    final padding = switch (context.deviceType) {
      DeviceType.mobile => mobilePadding,
      DeviceType.tablet => tabletPadding,
      DeviceType.desktop || DeviceType.largeDesktop => desktopPadding,
    };

    return AdaptivePadding.all(padding);
  }

  const AdaptivePadding.all(double value) : super.all(value);

  const AdaptivePadding.symmetric({double horizontal = 0, double vertical = 0})
    : super.symmetric(horizontal: horizontal, vertical: vertical);
}
