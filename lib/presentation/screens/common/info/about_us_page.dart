import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';

/// Carpenter-facing About screen — copy is store-agnostic for multi-tenant SaaS.
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const double _sectionGap = 22;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    // Shell draws content full-bleed behind the bottom bar; pad scroll so text
    // clears the bar and the system home-indicator inset.
    final scrollBottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(
      mq,
    );
    final bodyStyle = AppTypography.bodyMedium().copyWith(
      fontSize: 15,
      height: 1.58,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
    );
    final titleStyle = AppTypography.buttonMedium().copyWith(
      fontSize: 17,
      height: 1.35,
      color: theme.colorScheme.onSurface,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: l10n.aboutUs,
            subtitle: l10n.aboutUsSubtitle,
            showLogo: true,
            showProfileButton: false,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, scrollBottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.lightPrimary.withValues(alpha: 0.12),
                          AppColors.lightSecondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: AppRadius.forCard,
                      border: Border.all(
                        color: AppColors.lightPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism_rounded,
                          color: AppColors.lightPrimary,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            l10n.rewardsLoyaltyProgram,
                            style: AppTypography.buttonMedium().copyWith(
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AboutSection(
                    title: l10n.aboutUsOverviewTitle,
                    body: l10n.aboutUsOverviewBody,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: _sectionGap),
                  _AboutSection(
                    title: l10n.aboutUsEarningTitle,
                    body: l10n.aboutUsEarningBody,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: _sectionGap),
                  _AboutSection(
                    title: l10n.aboutUsOffersTitle,
                    body: l10n.aboutUsOffersBody,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: _sectionGap),
                  _AboutSection(
                    title: l10n.aboutUsFairnessTitle,
                    body: l10n.aboutUsFairnessBody,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: _sectionGap),
                  _AboutSection(
                    title: l10n.aboutUsStoresTitle,
                    body: l10n.aboutUsStoresBody,
                    titleStyle: titleStyle,
                    bodyStyle: bodyStyle,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.aboutUsClosing,
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),
                  _AboutDeveloperCredits(theme: theme, l10n: l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aaiji Tech Studio — contact links (mailto / tel).
class _AboutDeveloperCredits extends StatelessWidget {
  const _AboutDeveloperCredits({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  static const String _email = 'aaijitechstudio@gmail.com';
  static const String _phoneDisplay = '8947038661';
  static const String _phoneTel = '+918947038661';

  Future<void> _tryLaunch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final linkStyle = AppTypography.labelLarge().copyWith(
      fontSize: 14,
      height: 1.4,
      color: AppColors.lightPrimary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.lightPrimary.withValues(alpha: 0.5),
    );
    final captionStyle = AppTypography.bodyMedium().copyWith(
      fontSize: 13,
      height: 1.45,
      color: muted,
    );
    final headingStyle = AppTypography.buttonMedium().copyWith(
      fontSize: 13,
      height: 1.35,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
      letterSpacing: 0.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.aboutUsCreditsHeading, style: headingStyle),
        const SizedBox(height: 10),
        Text(
          l10n.aboutUsCreditsStudio,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 15,
            height: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _tryLaunch(context, Uri(scheme: 'mailto', path: _email)),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppColors.lightPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.email, style: captionStyle),
                      Text(
                        _email,
                        style: linkStyle.copyWith(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _tryLaunch(context, Uri(scheme: 'tel', path: _phoneTel)),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: AppColors.lightPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.phoneNumber, style: captionStyle),
                      Text(
                        _phoneDisplay,
                        style: linkStyle.copyWith(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.body,
    required this.titleStyle,
    required this.bodyStyle,
  });

  final String title;
  final String body;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 8),
        Text(body, style: bodyStyle),
      ],
    );
  }
}
