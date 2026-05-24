import 'package:flutter/material.dart';

/// Enterprise design system — spacing tokens.
///
/// Base unit: 4 px.  Named scale: xs(4) → 6xl(60).
/// Semantic tokens for screen, card, section layout.
class AppSpacing {
  AppSpacing._();

  // --------------------------------------------------------------------------
  // Base scale
  // --------------------------------------------------------------------------
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
  static const double xl6 = 60.0;

  // --------------------------------------------------------------------------
  // Semantic layout tokens (from PDF spec)
  // --------------------------------------------------------------------------

  /// Default horizontal screen inset — 20 px.
  static const double screenPaddingH = xl;

  /// Vertical screen inset — 24 px.
  static const double screenPaddingV = xl2;

  /// Gap between major sections — 24 px.
  static const double sectionGap = xl2;

  /// Tighter section break — 20 px.
  static const double sectionGapTight = xl;

  /// Standard card internal padding — 18 px.
  static const double cardPadding = 18.0;

  /// Gap between stacked cards — 16 px.
  static const double cardGap = lg;

  /// Tight gap inside a card or between related rows — 12 px.
  static const double cardGapTight = md;

  /// Standard button height — 54 px.
  static const double buttonHeight = 54.0;

  /// Standard input field height — 56 px.
  static const double inputHeight = 56.0;

  /// Bottom navigation bar height — 64 px.
  static const double bottomNavHeight = 64.0;

  /// App bar height — 56 px.
  static const double appBarHeight = 56.0;

  // --------------------------------------------------------------------------
  // EdgeInsets presets
  // --------------------------------------------------------------------------
  static const EdgeInsets paddingAll4 = EdgeInsets.all(xs);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(sm);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(md);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(lg);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(xl);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(xl2);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(xl3);

  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: screenPaddingH);

  static const EdgeInsets screenSymmetric = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingH12 = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingH20 = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingV4 = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: lg);

  // --------------------------------------------------------------------------
  // SizedBox helpers
  // --------------------------------------------------------------------------
  static const Widget gap4 = SizedBox(height: xs);
  static const Widget gap8 = SizedBox(height: sm);
  static const Widget gap12 = SizedBox(height: md);
  static const Widget gap16 = SizedBox(height: lg);
  static const Widget gap20 = SizedBox(height: xl);
  static const Widget gap24 = SizedBox(height: xl2);
  static const Widget gap32 = SizedBox(height: xl3);
  static const Widget gap40 = SizedBox(height: xl4);
  static const Widget gap48 = SizedBox(height: xl5);

  static const Widget hgap4 = SizedBox(width: xs);
  static const Widget hgap8 = SizedBox(width: sm);
  static const Widget hgap12 = SizedBox(width: md);
  static const Widget hgap16 = SizedBox(width: lg);
  static const Widget hgap20 = SizedBox(width: xl);
  static const Widget hgap24 = SizedBox(width: xl2);
}
