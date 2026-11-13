import 'package:flutter/material.dart';

import 'package:balaji_points/core/design/app_colors.dart';

/// Fixed bottom action bar for forms (use as `Scaffold.bottomNavigationBar`).
///
/// * Keeps its own height: `Align(heightFactor: 1)`, never `Center`, which
///   would take the whole screen in a bottom bar.
/// * Sits above Android's navigation bar (gesture strip or 3 buttons) and
///   the iPhone home indicator via the bottom safe-area padding.
/// * With the keyboard open that padding is 0, so the bar rides right above
///   the keyboard with no gap.
class AdminFormFooter extends StatelessWidget {
  const AdminFormFooter({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      10,
      16,
      10 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: BoxDecoration(
      color: context.themeBackground,
      border: Border(top: BorderSide(color: context.themeBorder)),
    ),
    child: Align(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}
