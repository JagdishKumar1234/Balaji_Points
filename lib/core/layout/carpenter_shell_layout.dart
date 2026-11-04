import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layout math for carpenter shell top / bottom navigation bars.
class CarpenterShellLayout {
  CarpenterShellLayout._();

  /// Bottom tab bar height (UI spec).
  static const double navBarHeight = 78;

  /// How far the raised Add Bill button rises above the visible bar. This part
  /// of [navBarHeight] is transparent, with the page showing through.
  static const double navBarRaise = 12;

  /// Top toolbar height.
  static const double topBarHeight = kToolbarHeight; // 56

  static double topInset(MediaQueryData mq) =>
      math.max(mq.padding.top, mq.viewPadding.top);

  static double bottomInset(MediaQueryData mq) =>
      math.max(mq.padding.bottom, mq.viewPadding.bottom);

  /// Total top chrome: status bar + toolbar.
  static double topChromeHeight(MediaQueryData mq) =>
      topBarHeight + topInset(mq);

  /// Total bottom chrome: tab bar + home indicator area.
  static double chromeHeight(MediaQueryData mq) =>
      navBarHeight + bottomInset(mq);

  /// Space the page leaves for the tab bar. It runs under the raised button's
  /// strip, so no empty band shows above the bar.
  static double contentBottomPadding(MediaQueryData mq) =>
      chromeHeight(mq) - navBarRaise;

  /// Lets the last item scroll clear of the raised Add Bill button.
  static const double scrollEndMargin = 20.0;

  static double bottomPaddingForScrollView(MediaQueryData mq) =>
      scrollEndMargin;

  static EdgeInsets scrollViewPadding(MediaQueryData mq) =>
      EdgeInsets.only(bottom: bottomPaddingForScrollView(mq));
}
