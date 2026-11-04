import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/responsive_typography.dart';
import 'package:balaji_points/core/layout/responsive.dart';

/// Professional auth card with centered design
/// Used for all authentication screens
class ProfessionalAuthCard extends StatelessWidget {
  final Widget child;
  final String? securityMessage;
  final bool isDark;
  final EdgeInsets? padding;

  const ProfessionalAuthCard({
    super.key,
    required this.child,
    this.securityMessage,
    this.isDark = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final maxWidth = isMobile ? double.infinity : 440.0;
    final cardPadding = padding ?? const EdgeInsets.all(32);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // White/Card container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? context.themeCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.themeBorder.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: context.themeShadow,
                ),
                padding: cardPadding,
                child: child,
              ),

              // Security message (if provided)
              if (securityMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _SecurityMessage(message: securityMessage!, isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Security message widget with shield icon
class _SecurityMessage extends StatelessWidget {
  final String message;
  final bool isDark;

  const _SecurityMessage({required this.message, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: context.themePrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: context.themeTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Auth screen header with logo and text
class AuthHeader extends StatelessWidget {
  final String logoPath;
  final String title;
  final String subtitle;
  final bool isDark;

  const AuthHeader({
    super.key,
    required this.logoPath,
    required this.title,
    required this.subtitle,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get responsive sizes based on device type
    final logoSize = context.responsiveLogoSize;
    final logoBorderRadius = context.responsiveLogoBorderRadius;
    final logoShadowBlur = ResponsiveTypography.getLogoShadowBlur(context);
    final fallbackIconSize = logoSize * 0.5;

    final titleFontSize = context.responsiveTitleSize;
    final subtitleFontSize = context.responsiveSubtitleSize;
    final lineHeight = context.responsiveLineHeight;

    return Column(
      children: [
        // Logo container
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? context.themePrimary.withValues(alpha: 0.3)
                  : context.themePrimary,
              borderRadius: BorderRadius.circular(logoBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: context.themePrimary.withValues(alpha: 0.2),
                  blurRadius: logoShadowBlur,
                  offset: Offset(0, logoShadowBlur * 0.3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoBorderRadius),
              child: Image.asset(
                logoPath,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.white,
                      size: fallbackIconSize,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: context.responsiveHeaderSpacing * 0.6),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            height: lineHeight,
            color: context.themeTextPrimary,
            letterSpacing: context.responsiveLetterSpacing,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleFontSize,
            height: lineHeight,
            color: context.themeTextSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Footer with company branding
class AuthFooter extends StatelessWidget {
  final String companyName;
  final bool isDark;

  const AuthFooter({super.key, required this.companyName, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    // The page scrolls over a light background and the navy curve, so the
    // footer brings its own background to stay readable on both.
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.poweredBy,
            style: AppTypography.bodySmall(color: context.themeTextSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✦',
                  style: TextStyle(
                    color: context.themeGold,
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 10),

                Flexible(
                  child: Text(
                    companyName,
                    style: AppTypography.bodyMedium(
                      color: context.themeTextPrimary,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),

                Text(
                  '✦',
                  style: TextStyle(
                    color: context.themeGold,
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Top controls (Theme toggle + Language picker)
class AuthTopControls extends StatelessWidget {
  final Widget themeToggle;
  final Widget languagePicker;

  const AuthTopControls({
    super.key,
    required this.themeToggle,
    required this.languagePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 44, height: 44, child: themeToggle),

          SizedBox(height: 44, child: languagePicker),
        ],
      ),
    );
  }
}

/// Divider text (e.g., "WELCOME TO")
class DividerText extends StatelessWidget {
  final String text;
  final bool isDark;

  const DividerText({super.key, required this.text, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall(
          color: context.themeGold,
        ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );
  }
}
