import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Enterprise design system — shadow tokens.
///
/// PDF spec: blur 16, soft / low-opacity, no neumorphic effects.
/// All shadows use black with very low alpha so they work on both
/// light and dark backgrounds without looking heavy.
class AppShadows {
  AppShadows._();

  // --------------------------------------------------------------------------
  // Light mode shadows
  // --------------------------------------------------------------------------

  /// Barely-there lift — cards, list items (blur 8).
  static List<BoxShadow> get low => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Standard card shadow (blur 16 — PDF spec value).
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Wallet / hero cards — slightly deeper (blur 24).
  static List<BoxShadow> get walletCard => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Floating action elements — buttons, FABs (blur 20).
  static List<BoxShadow> get floating => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// Modal / bottom-sheet overlay (blur 32).
  static List<BoxShadow> get modal => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  // --------------------------------------------------------------------------
  // Dark mode shadows (slightly stronger to create depth on dark surfaces)
  // --------------------------------------------------------------------------

  static List<BoxShadow> get lowDark => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.20),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get walletCardDark => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.40),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // --------------------------------------------------------------------------
  // Semantic helpers
  // --------------------------------------------------------------------------

  /// Adaptive shadow — picks light or dark based on [isDark].
  static List<BoxShadow> adaptive({required bool isDark, String level = 'card'}) {
    if (isDark) {
      switch (level) {
        case 'low':
          return lowDark;
        case 'wallet':
          return walletCardDark;
        default:
          return cardDark;
      }
    } else {
      switch (level) {
        case 'low':
          return low;
        case 'wallet':
          return walletCard;
        default:
          return card;
      }
    }
  }

  // --------------------------------------------------------------------------
  // Colored shadows (for branded/primary elements)
  // --------------------------------------------------------------------------

  static List<BoxShadow> primaryGlow(Color primaryColor) => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> successGlow() => [
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
