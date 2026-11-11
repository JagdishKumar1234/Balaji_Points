import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/core/legal/legal_documents.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum LegalDocument { terms, privacy }

/// Terms & Conditions or Privacy Policy. Opens from Profile and from the
/// registration form, before login too.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  static String routeFor(LegalDocument d) =>
      d == LegalDocument.terms ? '/terms' : '/privacy';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTerms = document == LegalDocument.terms;
    final title = isTerms ? l10n.legalTermsTitle : l10n.legalPrivacyTitle;
    final sections = isTerms ? LegalDocuments.terms : LegalDocuments.privacy;
    final bottom = MediaQuery.paddingOf(context).bottom + 32;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: title,
            showLogo: false,
            showProfileButton: false,
            showBackButton: true,
            onBackTap: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
              child: ResponsiveContainer(
                maxWidth: 700,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      icon: isTerms
                          ? Icons.gavel_rounded
                          : Icons.privacy_tip_rounded,
                      title: title,
                      subtitle: l10n.legalLastUpdated(
                        LegalDocuments.effectiveDate,
                      ),
                      note: isEnglish ? null : l10n.legalEnglishOnly,
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < sections.length; i++) ...[
                      _SectionCard(number: i + 1, section: sections[i]),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '© ${LegalDocuments.company}',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.note,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.forCard,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: AppRadius.md12,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h5(color: AppColors.white)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: AppTypography.caption(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.section});

  final int number;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.themeGoldSoft,
                  borderRadius: AppRadius.sm8,
                ),
                child: Text(
                  '$number',
                  style: AppTypography.labelSmall(
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: AppTypography.labelLarge(
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            section.body,
            style: AppTypography.bodyMedium(
              color: context.themeTextPrimary,
            ).copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}
