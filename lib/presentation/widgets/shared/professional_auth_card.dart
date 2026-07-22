import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
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
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF001F4D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              logoPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Title
        Text(
          title,
          style: AppTypography.displaySmall(
            color: const Color(0xFF001F4D),
          ).copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: AppTypography.bodyMedium(
            color: const Color(0xFF78909C),
          ),
          textAlign: TextAlign.center,
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
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Powered by',
          style: AppTypography.bodySmall(
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : const Color(0xFF78909C),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '✦',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                companyName,
                style: AppTypography.bodyMedium(
                  color: const Color(0xFF001F4D),
                ).copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '✦',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 12,
              ),
            ),
          ],
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
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          themeToggle,
          languagePicker,
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
