import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/constants/app_constants.dart';

/// Branded force / optional update prompt matching Balaji Points theme.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.targetVersion,
    required this.onUpdate,
    this.onLater,
  });

  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final String targetVersion;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  String get _targetVersion {
    if (targetVersion.isNotEmpty) return targetVersion;
    if (forceUpdate && minimumVersion.isNotEmpty) return minimumVersion;
    if (latestVersion.isNotEmpty) return latestVersion;
    return minimumVersion;
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetVersion;

    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2,
          vertical: AppSpacing.xl3,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightPrimary.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Material(
              color: AppColors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      _Header(forceUpdate: forceUpdate),
                      Positioned(bottom: -36, child: _LogoBadge()),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl2,
                      52,
                      AppSpacing.xl2,
                      AppSpacing.xl2,
                    ),
                    child: Column(
                      children: [
                        Text(
                          forceUpdate
                              ? 'Update required'
                              : 'New version available',
                          textAlign: TextAlign.center,
                          style: AppTypography.buttonMedium().copyWith(
                            fontSize: 22,
                            color: AppColors.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          forceUpdate
                              ? 'Please install the latest version of '
                                    '${AppConstants.appName} to continue.'
                              : 'A newer version is ready with improvements '
                                    'and fixes.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl2),
                        _VersionRow(
                          current: currentVersion,
                          target: target.isNotEmpty ? target : '—',
                          targetLabel: forceUpdate ? 'Required' : 'Latest',
                        ),
                        if (forceUpdate) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _RequiredBanner(),
                        ],
                        const SizedBox(height: AppSpacing.xl2),
                        _PrimaryButton(
                          label: 'Update now',
                          onPressed: onUpdate,
                        ),
                        if (!forceUpdate && onLater != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: onLater,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.lightTextMuted,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                                horizontal: AppSpacing.xl2,
                              ),
                            ),
                            child: Text(
                              'Maybe later',
                              style: AppTypography.labelLarge().copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.forceUpdate});

  final bool forceUpdate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -28,
            right: -20,
            child: _DecorCircle(
              size: 88,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -24,
            child: _DecorCircle(
              size: 72,
              color: AppColors.lightSecondary.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(
                forceUpdate
                    ? Icons.system_update_alt_rounded
                    : Icons.rocket_launch_rounded,
                color: AppColors.white,
                size: 36,
              ),
            ),
          ),
          if (forceUpdate)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightSecondary,
                  borderRadius: BorderRadius.circular(999.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightSecondary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Required',
                  style: AppTypography.buttonMedium().copyWith(
                    fontSize: 11,
                    color: AppColors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightTextMuted.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Image.asset(
        AppConstants.logoPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.stars_rounded, color: AppColors.lightPrimary, size: 40),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.current,
    required this.target,
    required this.targetLabel,
  });

  final String current;
  final String target;
  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionChip(
              label: 'Installed',
              version: current,
              emphasized: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.lightPrimary.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: _VersionChip(
              label: targetLabel,
              version: target,
              emphasized: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.version,
    required this.emphasized,
  });

  final String label;
  final String version;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 11,
            color: AppColors.lightTextMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: emphasized
                ? AppColors.lightPrimary.withValues(alpha: 0.1)
                : AppColors.grey100,
            borderRadius: BorderRadius.circular(12.0),
            border: emphasized
                ? Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.25))
                : null,
          ),
          child: Text(
            'v$version',
            style: AppTypography.buttonMedium().copyWith(
              fontSize: 14,
              color: emphasized ? AppColors.lightPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.lightPrimary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This update is mandatory to keep using the app.',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 13,
                height: 1.35,
                color: AppColors.lightTextPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightPrimary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.buttonMedium().copyWith(
                      fontSize: 16,
                      color: AppColors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
