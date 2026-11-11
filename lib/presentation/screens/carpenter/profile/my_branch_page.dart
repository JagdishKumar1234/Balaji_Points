import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// The member's own branch: name, ID, address, store phone, branch admin's
/// phone and email, plus app support. Opens from Profile.
class MyBranchPage extends ConsumerWidget {
  const MyBranchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final support = ref.watch(branchSupportProvider);
    final bottom = CarpenterShellLayout.bottomPaddingForScrollView(
      MediaQuery.of(context),
    );

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: l10n.myBranch,
            subtitle: l10n.myBranchSubtitle,
            showLogo: false,
            showProfileButton: false,
            showBackButton: true,
          ),
          Expanded(
            child: support.when(
              loading: () => const Center(child: AppLoader()),
              error: (_, __) => _Message(l10n.noBranchAssigned),
              data: (s) => s == null
                  ? _Message(l10n.noBranchAssigned)
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
                      child: ResponsiveContainer(
                        maxWidth: 700,
                        padding: EdgeInsets.zero,
                        child: _BranchDetails(support: s),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Google Maps links for the branch address. Opened as an external link,
/// Android and iOS hand these to the Google Maps app when it is installed,
/// and to the browser otherwise.
/// The address alone finds the place; the branch name (with " - E Road")
/// made Maps fall back to the town centre.
@visibleForTesting
String mapsQuery(CurrentBranch b) =>
    b.address.toLowerCase().contains('tamil nadu')
    ? b.address
    : '${b.address}, Tamil Nadu';

@visibleForTesting
Uri mapsSearchUrl(CurrentBranch b) => Uri.https(
  'www.google.com',
  '/maps/search/',
  {'api': '1', 'query': mapsQuery(b)},
);

/// Turn-by-turn directions from the member's current location.
@visibleForTesting
Uri mapsDirectionsUrl(CurrentBranch b) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': mapsQuery(b), 'travelmode': 'driving'},
);

class _BranchDetails extends StatelessWidget {
  const _BranchDetails({required this.support});

  final BranchSupport support;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = support.branch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
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
                child: const Icon(
                  Icons.store_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: AppTypography.h5(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.branchId}: ${b.id}',
                      style: AppTypography.caption(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Branch details
        _Card(
          title: l10n.branchDetails,
          children: [
            _Row(
              icon: Icons.location_on_rounded,
              label: l10n.address,
              value: b.address.isEmpty ? l10n.notAvailable : b.address,
            ),
            if (b.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _open(mapsSearchUrl(b)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md12,
                        ),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: Text(
                        l10n.openInGoogleMaps,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _open(mapsDirectionsUrl(b)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md12,
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        l10n.directions,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            _Row(
              icon: Icons.phone_rounded,
              label: l10n.branchPhone,
              value: b.phone.isEmpty ? l10n.notAvailable : b.phone,
              actionIcon: b.phone.isEmpty ? null : Icons.call_rounded,
              actionLabel: l10n.branchPhone,
              onTap: b.phone.isEmpty
                  ? null
                  : () => _open(
                      Uri(scheme: 'tel', path: BranchSupport.dialable(b.phone)),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Branch admin
        _Card(
          title: l10n.branchAdmin,
          children: [
            if (support.adminName.isNotEmpty)
              _Row(
                icon: Icons.person_rounded,
                label: l10n.name,
                value: support.adminName,
              ),
            _Row(
              icon: Icons.phone_android_rounded,
              label: l10n.mobile,
              value: support.adminPhone.isEmpty
                  ? l10n.notAvailable
                  : support.adminPhone,
              actionIcon: support.adminPhone.isEmpty
                  ? null
                  : Icons.call_rounded,
              actionLabel: l10n.mobile,
              onTap: support.adminPhone.isEmpty
                  ? null
                  : () => _open(
                      Uri(
                        scheme: 'tel',
                        path: BranchSupport.dialable(support.adminPhone),
                      ),
                    ),
            ),
            _Row(
              icon: Icons.email_outlined,
              label: l10n.email,
              value: support.adminEmail.isEmpty
                  ? l10n.notAvailable
                  : support.adminEmail,
              actionIcon: support.adminEmail.isEmpty
                  ? null
                  : Icons.send_rounded,
              actionLabel: l10n.email,
              onTap: support.adminEmail.isEmpty
                  ? null
                  : () =>
                        _open(Uri(scheme: 'mailto', path: support.adminEmail)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // App support
        _Card(
          title: l10n.appSupport,
          children: [
            _Row(
              icon: Icons.phone_android_rounded,
              label: l10n.mobile,
              value: AppConstants.supportPhoneDisplay,
              actionIcon: Icons.call_rounded,
              actionLabel: l10n.mobile,
              onTap: () => _open(
                Uri(scheme: 'tel', path: AppConstants.supportPhoneE164),
              ),
            ),
            _Row(
              icon: Icons.email_outlined,
              label: l10n.email,
              value: AppConstants.supportEmail,
              actionIcon: Icons.send_rounded,
              actionLabel: l10n.email,
              onTap: () =>
                  _open(Uri(scheme: 'mailto', path: AppConstants.supportEmail)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.supportHint,
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: context.themeTextSecondary),
        ),
      ],
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // The phone has no app for this link; nothing else to do.
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge(color: context.themeTextPrimary),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.actionIcon,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final IconData? actionIcon;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md12,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.themeGoldSoft,
                borderRadius: AppRadius.sm8,
              ),
              child: Icon(icon, size: 18, color: context.themeTextPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall(
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (value.contains(' '))
                    SelectableText(
                      value,
                      style: AppTypography.bodyMedium(
                        color: context.themeTextPrimary,
                      ),
                    )
                  else
                    // Emails and phones shrink to one line rather than
                    // breaking mid-word.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        value,
                        maxLines: 1,
                        style: AppTypography.bodyMedium(
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (actionIcon != null && onTap != null)
              IconButton(
                tooltip: actionLabel,
                onPressed: onTap,
                icon: Icon(actionIcon, color: context.themePrimary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
      ),
    );
  }
}
