import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balaji_points/core/design/app_colors.dart';

/// WCAG 2.1 contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Text pairs must reach 4.5:1 (WCAG AA body text).
  const textPairs = <String, (Color, Color)>{
    'ink on background': (AppColors.textPrimary, AppColors.background),
    'secondary on white': (AppColors.textSecondary, AppColors.surface),
    'secondary on background': (AppColors.textSecondary, AppColors.background),
    'muted on white': (AppColors.textMuted, AppColors.surface),
    'muted on background': (AppColors.textMuted, AppColors.background),
    'white on navy': (AppColors.white, AppColors.primary),
    'muted on navy': (AppColors.onPrimaryMuted, AppColors.primary),
    'navy on gold (CTA)': (AppColors.primary, AppColors.gold),
    'white on dark primary': (AppColors.white, AppColors.primaryOnDark),
    'white on success': (AppColors.white, AppColors.success),
    'white on error': (AppColors.white, AppColors.error),
    'success chip': (AppColors.successText, AppColors.successSoft),
    'pending chip': (AppColors.pendingText, AppColors.pendingSoft),
    'error chip': (AppColors.errorText, AppColors.errorSoft),
    'dark ink': (AppColors.darkTextPrimary, AppColors.darkSurface),
    'dark secondary': (AppColors.darkTextSecondary, AppColors.darkSurface),
    'dark muted': (AppColors.darkTextMuted, AppColors.darkSurface),
    'dark success chip': (AppColors.darkSuccessText, AppColors.darkSuccessSoft),
    'dark pending chip': (AppColors.darkPendingText, AppColors.darkPendingSoft),
    'dark error chip': (AppColors.darkErrorText, AppColors.darkErrorSoft),
    // Dark ColorScheme.error / onError (destructive text + danger fills).
    'dark error text on card': (AppColors.darkErrorText, AppColors.darkSurface),
    'dark error text on bg': (AppColors.darkErrorText, AppColors.darkBackground),
    'error text on white': (AppColors.error, AppColors.surface),
  };

  // Icon / large-text pairs must reach 3:1.
  const iconPairs = <String, (Color, Color)>{
    'dark primary on dark bg': (AppColors.primaryOnDark, AppColors.darkBackground),
    'dark primary on dark card': (AppColors.primaryOnDark, AppColors.darkSurface),
    'warning on white': (AppColors.warning, AppColors.surface),
    'warning on dark card': (AppColors.warning, AppColors.darkSurface),
    'success on dark card': (AppColors.success, AppColors.darkSurface),
    'gold on navy': (AppColors.gold, AppColors.primary),
    'navy primary on light bg': (AppColors.primary, AppColors.background),
  };

  group('design tokens meet WCAG AA', () {
    textPairs.forEach((name, pair) {
      test('text: $name', () {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });
    iconPairs.forEach((name, pair) {
      test('icon: $name', () {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(3.0));
      });
    });
  });
}
