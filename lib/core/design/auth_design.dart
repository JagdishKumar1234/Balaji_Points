import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_spacing.dart';

/// Authentication Module Design System
/// Standardizes TextField, Container, and Card dimensions across all platforms
class AuthDesign {
  // ─── TextField Heights ───────────────────────────────────────────────────
  /// Standard text field height (label + input + error space)
  static const double textFieldHeight = 64;

  /// PIN field height (larger, centered input)
  static const double pinFieldHeight = 70;

  /// Phone field height (with prefix icon)
  static const double phoneFieldHeight = 64;

  // ─── Container & Card Dimensions ────────────────────────────────────────
  /// Glass card padding (outer padding inside screen)
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.xl3);

  /// Card inner spacing (between elements inside card)
  static const double cardSpacing = AppSpacing.md;

  /// Large spacing between major card sections
  static const double largeSpacing = AppSpacing.xl3;

  /// Glass card border radius (consistent across all platforms)
  static const double cardBorderRadiusValue = 20;

  /// Card blur intensity
  static const double cardBlurSigma = 14;

  /// Card shadow blur radius
  static const double cardShadowBlurRadius = 24;

  /// Card shadow offset
  static const Offset cardShadowOffset = Offset(0, 8);

  // ─── Button Dimensions ──────────────────────────────────────────────────
  /// Standard button height
  static const double buttonHeight = 48;

  /// Button padding (horizontal)
  static const double buttonHorizontalPadding = 16;

  // ─── Logo & Icon Sizes ──────────────────────────────────────────────────
  /// Logo display size
  static const Size logoSize = Size(88, 88);

  /// Small icon size
  static const double smallIconSize = 20;

  /// Checkbox size
  static const double checkboxSize = 24;

  // ─── Spacing System ─────────────────────────────────────────────────────
  /// Spacing between logo and title
  static const double logoToTitleSpacing = AppSpacing.md;

  /// Spacing between sections
  static const double sectionSpacing = AppSpacing.xl3;

  /// Spacing between form fields
  static const double fieldSpacing = AppSpacing.md;

  /// Bottom padding from content to keyboard
  static const double bottomKeyboardPadding = AppSpacing.xl;

  /// Top padding from status bar to content
  static const double topContentPadding = AppSpacing.sm;

  /// Horizontal padding from screen edges
  static const double horizontalScreenPadding = AppSpacing.xl;

  // ─── Content Width ──────────────────────────────────────────────────────
  /// Maximum content width (constrains on large screens)
  static const double maxContentWidth = 500;

  /// Responsive content width helper
  static double getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 480) {
      return horizontalScreenPadding;
    } else if (screenWidth < 1024) {
      return AppSpacing.xl2;
    } else {
      return (screenWidth - maxContentWidth) / 2;
    }
  }

  // ─── Glass Card Opacity Values ──────────────────────────────────────────
  /// Light mode glass card main color opacity
  static const double lightCardMainOpacity = 0.92;

  /// Light mode glass card secondary color opacity
  static const double lightCardSecondaryOpacity = 0.72;

  /// Dark mode glass card main color opacity
  static const double darkCardMainOpacity = 0.82;

  /// Dark mode glass card secondary color opacity
  static const double darkCardSecondaryOpacity = 0.72;

  /// Glass card border opacity (light)
  static const double lightCardBorderOpacity = 0.50;

  /// Glass card border opacity (dark)
  static const double darkCardBorderOpacity = 0.55;

  /// Card shadow opacity (light)
  static const double lightCardShadowOpacity = 0.10;

  /// Card shadow opacity (dark)
  static const double darkCardShadowOpacity = 0.40;

  // ─── Border Width ───────────────────────────────────────────────────────
  /// Glass card border width
  static const double cardBorderWidth = 1.5;

  /// TextField border width
  static const double textFieldBorderWidth = 1.0;
}

/// Helper extension for using auth design in BuildContext
extension AuthDesignContext on BuildContext {
  AuthDesign get authDesign => AuthDesign();

  /// Get responsive horizontal padding based on screen width
  double getAuthPadding() {
    return AuthDesign.getResponsiveHorizontalPadding(
      MediaQuery.of(this).size.width,
    );
  }
}
