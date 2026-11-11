import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';

/// Shows the signed-in user's complete branch name (wraps, never cut off).
/// Renders nothing for super admins or while the branch is unknown.
class BranchBanner extends ConsumerWidget {
  const BranchBanner({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(currentBranchProvider).asData?.value;
    if (branch == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: branch.name,
      excludeSemantics: true,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: AppRadius.forCard,
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.sm8,
              ),
              child: const Icon(
                Icons.store_rounded,
                size: 18,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: AppTypography.label(
                      color: context.themeTextPrimary,
                    ).copyWith(fontSize: 14, height: 1.35),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppLocalizations.of(context)!.branchId}: ${branch.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-line branch name for app bars (full name in the tooltip).
class BranchNameLine extends ConsumerWidget {
  const BranchNameLine({super.key, required this.style, this.fallback});

  final TextStyle style;
  final String? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(currentBranchProvider).asData?.value;
    final text = branch?.name ?? fallback;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: text,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
