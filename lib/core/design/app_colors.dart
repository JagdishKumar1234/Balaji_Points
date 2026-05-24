import 'package:flutter/material.dart';

/// Enterprise design system — color tokens.
/// Light / Dark semantic colors + tier palette + preserved legacy aliases.
class AppColors {
  AppColors._();

  // --------------------------------------------------------------------------
  // Light Theme
  // --------------------------------------------------------------------------
  static const Color lightPrimary = Color(0xFF1D2B6B);
  static const Color lightSecondary = Color(0xFFC96B7B);
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSoftSurface = Color(0xFFF2F4F7);
  static const Color lightBorder = Color(0xFFE4E7EC);
  static const Color lightTextPrimary = Color(0xFF101828);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextMuted = Color(0xFF98A2B3);

  // --------------------------------------------------------------------------
  // Dark Theme
  // --------------------------------------------------------------------------
  static const Color darkPrimary = Color(0xFF2D4AB8);
  static const Color darkSecondary = Color(0xFFD96A87);
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkCard = Color(0xFF171A22);
  static const Color darkSurface = Color(0xFF232733);
  static const Color darkBorder = Color(0xFF313543);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A8B8);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // --------------------------------------------------------------------------
  // Tier Colors
  // --------------------------------------------------------------------------
  static const Color tierSilver = Color(0xFFB8BDC7);
  static const Color tierGold = Color(0xFFD4A537);
  static const Color tierPlatinum = Color(0xFF8E9AAF);
  static const Color tierDiamond = Color(0xFF5CC8FF);

  // --------------------------------------------------------------------------
  // Status Colors
  // --------------------------------------------------------------------------
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF166534);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFE53935);
  static const Color info = Color(0xFF3B82F6);

  // --------------------------------------------------------------------------
  // Neutrals
  // --------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // --------------------------------------------------------------------------
  // Gradients
  // --------------------------------------------------------------------------
  static const List<Color> primaryGradient = [lightPrimary, Color(0xFF2A4080)];
  static const List<Color> secondaryGradient = [lightSecondary, Color(0xFFE08090)];
  static const List<Color> successGradient = [success, Color(0xFF34D399)];
  static const List<Color> darkPrimaryGradient = [darkPrimary, Color(0xFF3A5AD4)];

  // --------------------------------------------------------------------------
  // Semantic helpers (opacity variants)
  // --------------------------------------------------------------------------
  static Color shadowSoft(bool isDark) =>
      isDark ? black.withValues(alpha: 0.30) : black.withValues(alpha: 0.08);

  static Color overlay(double opacity) => black.withValues(alpha: opacity);

  // --------------------------------------------------------------------------
  // Points / bill status
  // --------------------------------------------------------------------------
  static const Color pointsEarned = success;
  static const Color pointsSpent = error;
  static const Color pointsPending = warning;
  static const Color billPending = warning;
  static const Color billApproved = success;
  static const Color billRejected = error;

  // --------------------------------------------------------------------------
  // Spin wheel
  // --------------------------------------------------------------------------
  static const Color spinAmber = Color(0xFFFBBF24);
  static const Color spinOrange = Color(0xFFF97316);
  static const Color spinRed = Color(0xFFEF4444);
  static const Color spinPink = Color(0xFFEC4899);
  static const Color spinPurple = Color(0xFFA855F7);
  static const Color spinBlue = Color(0xFF3B82F6);
  static const Color spinGreen = Color(0xFF10B981);
  static const Color spinYellow = Color(0xFFEAB308);

  // --------------------------------------------------------------------------
  // Leaderboard / trophy
  // --------------------------------------------------------------------------
  static const Color rank1Background = Color(0xFFFFF8E1);
  static const Color rank1Text = Color(0xFFF57F17);
  static const Color rank2Background = Color(0xFFEEEEEE);
  static const Color rank2Text = Color(0xFF616161);
  static const Color rank3Background = Color(0xFFEFEBE9);
  static const Color rank3Text = Color(0xFF5D4037);
  static const Color trophyGold = Color(0xFFFFC107);
  static const Color trophySilver = Color(0xFFBDBDBD);
  static const Color trophyBronze = Color(0xFF8D6E63);

  // --------------------------------------------------------------------------
  // Home screen accents
  // --------------------------------------------------------------------------
  static const Color homeIconCircleBlue = Color(0xFFE6EEF8);
  static const Color homeQuickActionScanBg = Color(0xFFE6EEF8);
  static const Color homeQuickActionRedeemBg = Color(0xFFFFF3F5);
  static const Color homeQuickActionHistoryBg = Color(0xFFF1F5F9);
  static const Color homeAccentPink = Color(0xFFFF6B81);
  static const Color homePointsPositive = Color(0xFF16A34A);
  static const Color homePointsNegative = Color(0xFFDC2626);

  // --------------------------------------------------------------------------
  // Offer cards
  // --------------------------------------------------------------------------
  static const Color offerBannerBg = Color(0xFFFEF3C7);
  static const Color offerBasicBg = Color(0xFFDCFCE7);
  static const Color offerFullWidthBg = Color(0xFFFCE7F3);

  // --------------------------------------------------------------------------
  // Confetti / effects
  // --------------------------------------------------------------------------
  static const Color confettiGold = Color(0xFFFFD700);
  static const Color confettiSilver = Color(0xFFC0C0C0);
  static const Color glowEffect = Color(0xFFFFEB3B);

  // --------------------------------------------------------------------------
  // Wooden / brand
  // --------------------------------------------------------------------------
  static const Color woodenBackground = Color(0xFFF5E6D3);
  static const Color woodenBase = Color(0xFFD4A574);
  static const Color woodenDark = Color(0xFFC4946A);
  static const List<Color> woodenGradient = [woodenBackground, Color(0xFFE8D5BE)];

  // --------------------------------------------------------------------------
  // Orange shades (profile warnings, etc.)
  // --------------------------------------------------------------------------
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeLight = Color(0xFFFFB74D);
  static const Color orangeDark = Color(0xFFFF6F00);
  static const Color orangeBackground = Color(0xFFFFF3E0);

  // --------------------------------------------------------------------------
  // Misc color scale aliases (used throughout the app)
  // --------------------------------------------------------------------------
  static const Color amber = Color(0xFFFFC107);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color red = Color(0xFFF44336);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color black12 = Color(0x1F000000);
  static const Color black26 = Color(0x42000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black87 = Color(0xDD000000);
  static const Color white70 = Color(0xB3FFFFFF);

  // --------------------------------------------------------------------------
  // Navigation / shell
  // --------------------------------------------------------------------------
  static const Color navyBackground = Color(0xFF001F3F);
  static const Color carpenterAppBackground = Color(0xFFF8FAFC);

  static Color carpenterAppBarBorderColor(bool isDark) {
    return isDark
        ? white.withValues(alpha: 0.24)
        : const Color(0xFF1E2A4A).withValues(alpha: 0.16);
  }
}
