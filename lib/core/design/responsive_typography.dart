import 'package:flutter/material.dart';
import 'package:balaji_points/core/layout/responsive.dart';

/// Responsive font sizes and logo dimensions based on device type
class ResponsiveTypography {
  /// Get responsive logo size based on device type
  static double getLogoSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 80.0,        // Phone: 80px
      DeviceType.tablet => 100.0,       // Tablet: 100px
      DeviceType.desktop => 120.0,      // Desktop: 120px
      DeviceType.largeDesktop => 140.0, // Large desktop: 140px
    };
  }

  /// Get responsive logo border radius
  static double getLogoBorderRadius(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 16.0,
      DeviceType.tablet => 20.0,
      DeviceType.desktop => 24.0,
      DeviceType.largeDesktop => 28.0,
    };
  }

  /// Get responsive logo shadow blur radius
  static double getLogoShadowBlur(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 8.0,
      DeviceType.tablet => 12.0,
      DeviceType.desktop => 16.0,
      DeviceType.largeDesktop => 20.0,
    };
  }

  /// Get responsive title font size
  static double getTitleFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 28.0,        // Mobile: 28px
      DeviceType.tablet => 32.0,        // Tablet: 32px
      DeviceType.desktop => 36.0,       // Desktop: 36px
      DeviceType.largeDesktop => 40.0,  // Large desktop: 40px
    };
  }

  /// Get responsive subtitle font size
  static double getSubtitleFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 14.0,        // Mobile: 14px
      DeviceType.tablet => 15.0,        // Tablet: 15px
      DeviceType.desktop => 16.0,       // Desktop: 16px
      DeviceType.largeDesktop => 17.0,  // Large desktop: 17px
    };
  }

  /// Get responsive body font size
  static double getBodyFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 14.0,        // Mobile: 14px
      DeviceType.tablet => 15.0,        // Tablet: 15px
      DeviceType.desktop => 16.0,       // Desktop: 16px
      DeviceType.largeDesktop => 17.0,  // Large desktop: 17px
    };
  }

  /// Get responsive label font size
  static double getLabelFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 12.0,        // Mobile: 12px
      DeviceType.tablet => 13.0,        // Tablet: 13px
      DeviceType.desktop => 14.0,       // Desktop: 14px
      DeviceType.largeDesktop => 15.0,  // Large desktop: 15px
    };
  }

  /// Get responsive button font size
  static double getButtonFontSize(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 15.0,        // Mobile: 15px
      DeviceType.tablet => 16.0,        // Tablet: 16px
      DeviceType.desktop => 16.0,       // Desktop: 16px
      DeviceType.largeDesktop => 17.0,  // Large desktop: 17px
    };
  }

  /// Get responsive line height for better readability
  static double getLineHeight(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 1.4,
      DeviceType.tablet => 1.5,
      DeviceType.desktop => 1.6,
      DeviceType.largeDesktop => 1.7,
    };
  }

  /// Get responsive letter spacing for elegance
  static double getLetterSpacing(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 0.2,
      DeviceType.tablet => 0.3,
      DeviceType.desktop => 0.4,
      DeviceType.largeDesktop => 0.5,
    };
  }

  /// Get responsive spacing between header and content
  static double getHeaderSpacing(BuildContext context) {
    return switch (context.deviceType) {
      DeviceType.mobile => 24.0,
      DeviceType.tablet => 32.0,
      DeviceType.desktop => 40.0,
      DeviceType.largeDesktop => 48.0,
    };
  }
}

/// Extension on BuildContext for quick access to responsive typography
extension ResponsiveTypographyContext on BuildContext {
  /// Get responsive logo size
  double get responsiveLogoSize => ResponsiveTypography.getLogoSize(this);

  /// Get responsive logo border radius
  double get responsiveLogoBorderRadius =>
      ResponsiveTypography.getLogoBorderRadius(this);

  /// Get responsive title font size
  double get responsiveTitleSize =>
      ResponsiveTypography.getTitleFontSize(this);

  /// Get responsive subtitle font size
  double get responsiveSubtitleSize =>
      ResponsiveTypography.getSubtitleFontSize(this);

  /// Get responsive body font size
  double get responsiveBodySize =>
      ResponsiveTypography.getBodyFontSize(this);

  /// Get responsive label font size
  double get responsiveLabelSize =>
      ResponsiveTypography.getLabelFontSize(this);

  /// Get responsive line height
  double get responsiveLineHeight =>
      ResponsiveTypography.getLineHeight(this);

  /// Get responsive letter spacing
  double get responsiveLetterSpacing =>
      ResponsiveTypography.getLetterSpacing(this);

  /// Get responsive header spacing
  double get responsiveHeaderSpacing =>
      ResponsiveTypography.getHeaderSpacing(this);
}
