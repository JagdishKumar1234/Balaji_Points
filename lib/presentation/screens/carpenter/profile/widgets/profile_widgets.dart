import 'package:balaji_points/core/profile/profile_completeness.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:flutter/material.dart';

/// Navy header with the member's identity and a points card overlapping it.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.roleName,
    required this.points,
    required this.tier,
    this.imageUrl,
    this.displayId,
    this.phone,
  });

  final String name;
  final String roleName;
  final String points;
  final String tier;
  final String? imageUrl;
  final String? displayId;
  final String? phone;

  static const double _cardOverlap = 40;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (displayId != null && displayId!.isNotEmpty) '#BP$displayId',
      if (phone != null && phone!.isNotEmpty) phone!,
    ].join('  ·  ');

    return Stack(
      children: [
        Positioned.fill(
          bottom: _cardOverlap,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: MemberAvatar(name: name, imageUrl: imageUrl, size: 92),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTypography.h4(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              Center(child: RoleTag(label: roleName)),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  details,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(
                    color: AppColors.onPrimaryMuted,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _PointsCard(points: points, tier: tier),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points, required this.tier});

  final String points;
  final String tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
        boxShadow: context.themeShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _PointsStat(
                icon: Icons.stars_rounded,
                value: points,
                label: l10n.myPoints,
              ),
            ),
            VerticalDivider(width: 1, color: context.themeBorder),
            Expanded(
              child: _PointsStat(
                icon: Icons.workspace_premium_rounded,
                value: tier,
                label: l10n.member,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsStat extends StatelessWidget {
  const _PointsStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          // Shrinks a very large balance rather than cutting it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.h4(color: context.themeContentColor),
            ),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: context.themeTextSecondary),
        ),
      ],
    );
  }
}

/// A titled card of [ProfileMenuTile] rows.
class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.overline(color: context.themeTextSecondary),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: AppRadius.all16,
            border: Border.all(color: context.themeBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 66, color: context.themeBorder),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row: icon in a soft square, title, then [trailing] or a chevron.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSoftSurface
                        : AppColors.primarySoft,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(icon, size: 20, color: context.themeContentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge(
                      color: context.themeTextPrimary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.themeTextMuted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile status: phone, email, name and photo, each marked added or
/// missing, with which ones bills need. Shown on Profile and Edit Profile.
class ProfileChecklist extends StatelessWidget {
  const ProfileChecklist({
    super.key,
    required this.completeness,
    this.onComplete,
  });

  final ProfileCompleteness completeness;

  /// Opens Edit Profile; hidden when null (already on that screen).
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = completeness;
    final ready = c.isReadyForBills;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(
          color: ready ? context.themeBorder : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.verified_rounded : Icons.error_outline_rounded,
                color: ready ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.profileStatus,
                  style: AppTypography.labelLarge(
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              Text(
                '${c.completedCount}/4',
                style: AppTypography.labelMedium(
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ready ? l10n.profileReadyForBills : l10n.profileMissingForBills,
            style: AppTypography.bodySmall(color: context.themeTextSecondary),
          ),
          const SizedBox(height: 10),
          _ChecklistRow(
            icon: Icons.phone_android_rounded,
            label: l10n.mobileNumber,
            ok: c.hasPhone,
            okLabel: l10n.verified,
            missingLabel: l10n.missing,
            required: true,
          ),
          _ChecklistRow(
            icon: Icons.email_outlined,
            label: l10n.email,
            ok: c.hasEmail,
            okLabel: l10n.verified,
            missingLabel: l10n.notAdded,
            required: false,
          ),
          _ChecklistRow(
            icon: Icons.badge_outlined,
            label: l10n.fullName,
            ok: c.hasFullName,
            okLabel: l10n.added,
            missingLabel: l10n.missing,
            required: true,
          ),
          _ChecklistRow(
            icon: Icons.account_circle_outlined,
            label: l10n.profilePhoto,
            ok: c.hasPhoto,
            okLabel: l10n.added,
            missingLabel: l10n.missing,
            required: true,
          ),
          if (!ready && onComplete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(l10n.completeProfile),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.label,
    required this.ok,
    required this.okLabel,
    required this.missingLabel,
    required this.required,
  });

  final IconData icon;
  final String label;
  final bool ok;
  final String okLabel;
  final String missingLabel;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ok ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.themeTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              required ? '$label *' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(color: context.themeTextPrimary),
            ),
          ),
          if (required && !ok)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                l10n.requiredForBills,
                style: AppTypography.caption(color: AppColors.warning),
              ),
            ),
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            ok ? okLabel : missingLabel,
            style: AppTypography.labelSmall(color: color),
          ),
        ],
      ),
    );
  }
}
