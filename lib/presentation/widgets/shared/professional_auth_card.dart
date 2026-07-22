import 'package:flutter/material.dart';
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
              // White card container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: cardPadding,
                child: child,
              ),

              // Security message (if provided)
              if (securityMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _SecurityMessage(
                  message: securityMessage!,
                  isDark: isDark,
                ),
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

  const _SecurityMessage({
    required this.message,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: const Color(0xFF0D47A1).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: AppTypography.bodySmall(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF78909C),
              ),
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
    final fallbackIconSize = logoSize * 0.5; // Icon is 50% of logo size

    final titleFontSize = context.responsiveTitleSize;
    final subtitleFontSize = context.responsiveSubtitleSize;
    final lineHeight = context.responsiveLineHeight;

    return Column(
      children: [
        // Logo container - responsive sizing across all platforms
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF001F4D),
              borderRadius: BorderRadius.circular(logoBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF001F4D).withValues(alpha: 0.2),
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
                  // Fallback icon - responsive size
                  return Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: fallbackIconSize,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Responsive spacing after logo
        SizedBox(height: context.responsiveHeaderSpacing * 0.6),

        // Title - responsive font size for all platforms
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            height: lineHeight,
            color: isDark
                ? Colors.white.withValues(alpha: 0.95)
                : const Color(0xFF001F4D),
            letterSpacing: context.responsiveLetterSpacing,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Space between title and subtitle
        const SizedBox(height: 8),

        // Subtitle - responsive font size
        Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleFontSize,
            height: lineHeight,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF78909C),
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

  const AuthFooter({
    super.key,
    required this.companyName,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacing from card above
        const SizedBox(height: AppSpacing.xl),

        // "Powered by" text
        Text(
          'Powered by',
          style: AppTypography.bodySmall(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF78909C),
          ),
          textAlign: TextAlign.center,
        ),

        // Space between texts
        const SizedBox(height: 8),

        // Company name with gold stars - constrained for stability
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left gold star
              Text(
                '✦',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),

              // Company name - white on dark, navy on light
              Flexible(
                child: Text(
                  companyName,
                  style: AppTypography.bodyMedium(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : const Color(0xFF001F4D),
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),

              // Right gold star
              Text(
                '✦',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
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
        vertical: AppSpacing.lg,  // Increased for better visibility
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Theme toggle - ensure proper sizing
          SizedBox(
            width: 44,
            height: 44,
            child: themeToggle,
          ),

          // Right: Language picker - ensure proper sizing
          SizedBox(
            height: 44,
            child: languagePicker,
          ),
        ],
      ),
    );
  }
}

/// Divider text (e.g., "WELCOME TO")
class DividerText extends StatelessWidget {
  final String text;
  final bool isDark;

  const DividerText({
    super.key,
    required this.text,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSmall(
          color: const Color(0xFFD4AF37),
        ).copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
