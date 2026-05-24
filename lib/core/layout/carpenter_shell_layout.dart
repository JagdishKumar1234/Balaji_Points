import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layout math for carpenter shell top / bottom navigation bars.
class CarpenterShellLayout {
  CarpenterShellLayout._();

  static const double navBarHeight = kToolbarHeight; // 56

  static double topInset(MediaQueryData mq) =>
      math.max(mq.padding.top, mq.viewPadding.top);

  static double bottomInset(MediaQueryData mq) =>
      math.max(mq.padding.bottom, mq.viewPadding.bottom);

  /// Total top chrome: status bar + toolbar.
  static double topChromeHeight(MediaQueryData mq) =>
      navBarHeight + topInset(mq);

  /// Total bottom chrome: tab bar + home indicator area.
  static double chromeHeight(MediaQueryData mq) =>
      navBarHeight + bottomInset(mq);

  static const double scrollEndMargin = 0.0;

  static double bottomPaddingForScrollView(MediaQueryData mq) => scrollEndMargin;

  static EdgeInsets scrollViewPadding(MediaQueryData mq) => EdgeInsets.only(
        bottom: bottomPaddingForScrollView(mq),
      );
}
