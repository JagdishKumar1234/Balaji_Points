import 'package:flutter/material.dart';

/// Responsive breakpoint constants (Material 3 window size classes).
///
/// Layout contract (docs/ui_spec_conformance_audit.md §6):
///   compact  < 600   phone layout, bottom nav, 16 px gutter, 1 column
///   medium   600–839 bottom nav, content max-width 640, 2-column cards
///   expanded 840–1199 navy rail (80), 24 px gutter, 2-column grids
///   large    ≥ 1200  navy sidebar (232), 24/32 padding, tables + pagination
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  /// Readable max width for single-column (phone-designed) content.
  static const double readableContent = 720;
}

/// Material 3 window size class.
enum WindowSize {
  compact,
  medium,
  expanded,
  large;

  static WindowSize of(double width) {
    if (width < ResponsiveBreakpoints.mobile) return WindowSize.compact;
    if (width < ResponsiveBreakpoints.tablet) return WindowSize.medium;
    if (width < ResponsiveBreakpoints.desktop) return WindowSize.expanded;
    return WindowSize.large;
  }

  bool get isCompact => this == WindowSize.compact;
  bool get atLeastMedium => index >= WindowSize.medium.index;
  bool get atLeastExpanded => index >= WindowSize.expanded.index;

  /// Horizontal page gutter for this size class.
  double get gutter => switch (this) {
    WindowSize.compact => 16,
    WindowSize.medium => 20,
    WindowSize.expanded => 24,
    WindowSize.large => 32,
  };
}

/// Extension on BuildContext to provide responsive helpers
extension ResponsiveContext on BuildContext {
  /// Current window width in logical pixels. Uses `sizeOf` so widgets only
  /// rebuild on size changes (not on keyboard / inset changes).
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Current window height in logical pixels
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Material 3 window size class of the whole window. Prefer
  /// [ResponsiveLayout] / `LayoutBuilder` when the widget does not span the
  /// full window (e.g. content beside the navigation rail).
  WindowSize get windowSize => WindowSize.of(screenWidth);

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
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// View padding accounting for system UI
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Device orientation
  Orientation get orientation => MediaQuery.orientationOf(this);

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
    // Size from the parent's constraints, not the window: inside a rail
    // layout the available width is smaller than the screen.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth + padding.horizontal) {
          return Padding(padding: padding, child: child);
        }
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth + padding.horizontal,
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}

/// Picks a builder by the space actually available to this widget.
///
/// ```dart
/// ResponsiveLayout(
///   compact: (_) => const BillCards(),
///   expanded: (_) => const BillTable(),
/// )
/// ```
/// Missing sizes fall back to the next smaller one.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = WindowSize.of(constraints.maxWidth);
        final builder = switch (size) {
          WindowSize.large => large ?? expanded ?? medium ?? compact,
          WindowSize.expanded => expanded ?? medium ?? compact,
          WindowSize.medium => medium ?? compact,
          WindowSize.compact => compact,
        };
        return builder(context);
      },
    );
  }
}

/// Centers phone-designed content at a readable width on large windows.
/// Does nothing on compact screens.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.readableContent,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
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
