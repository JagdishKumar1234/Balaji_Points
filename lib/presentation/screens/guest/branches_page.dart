import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/services/branch/public_branches.dart';

/// Every active branch with its address, phone (tap to call) and
/// Directions (the super admin's Google Maps pin, else a Maps search for the
/// store name and address). Open to guests and members.
class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key, this.inTab = false});

  /// Shown as a tab (guest mode): no back arrow.
  final bool inTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(publicBranchesProvider);
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: l10n.guestBranches,
            subtitle: l10n.guestBranchesSub,
            showLogo: false,
            showProfileButton: false,
            showBackButton: !inTab,
            onBackTap: () =>
                context.canPop() ? context.pop() : context.go('/guest'),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: AppLoader()),
              error: (_, __) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.catalogLoadError,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(publicBranchesProvider),
                ),
              ),
              data: (branches) => branches.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.storefront_rounded,
                        title: l10n.branchesEmpty,
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: _BranchCard(branch: branches[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});
  final PublicBranch branch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = branch;
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.label,
                        style: AppTypography.labelLarge(color: AppColors.white),
                      ),
                      if (b.shortName.isNotEmpty && b.name != b.shortName)
                        Text(
                          b.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (b.address.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: context.themePrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b.address,
                          style: AppTypography.bodyMedium(
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (b.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.call_rounded,
                        size: 18,
                        color: context.themePrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        b.phone,
                        style: AppTypography.bodyMedium(
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (b.phone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(l10n.memberCall),
                          onPressed: () =>
                              launchUrl(Uri(scheme: 'tel', path: b.dialable)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(l10n.branchDirections),
                        onPressed: () => launchUrl(
                          b.directions,
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
