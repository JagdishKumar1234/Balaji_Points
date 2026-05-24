import 'package:flutter/material.dart';
import 'package:balaji_points/config/theme.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/theme/design_token.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: DesignToken.spacing2XL,
          vertical: DesignToken.spacing3XL,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignToken.radius2XL),
            boxShadow: [
              BoxShadow(
                color: DesignToken.primary.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: DesignToken.shadow10,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignToken.radius2XL),
            child: Material(
              color: DesignToken.white,
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
                      DesignToken.spacing2XL,
                      52,
                      DesignToken.spacing2XL,
                      DesignToken.spacing2XL,
                    ),
                    child: Column(
                      children: [
                        Text(
                          forceUpdate
                              ? 'Update required'
                              : 'New version available',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.nunitoBold.copyWith(
                            fontSize: 22,
                            color: DesignToken.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: DesignToken.spacingSM),
                        Text(
                          forceUpdate
                              ? 'Please install the latest version of '
                                    '${AppConstants.appName} to continue.'
                              : 'A newer version is ready with improvements '
                                    'and fixes.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.nunitoRegular.copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: DesignToken.homeTextMuted,
                          ),
                        ),
                        const SizedBox(height: DesignToken.spacing2XL),
                        _VersionRow(
                          current: currentVersion,
                          target: target.isNotEmpty ? target : '—',
                          targetLabel: forceUpdate ? 'Required' : 'Latest',
                        ),
                        if (forceUpdate) ...[
                          const SizedBox(height: DesignToken.spacingLG),
                          _RequiredBanner(),
                        ],
                        const SizedBox(height: DesignToken.spacing2XL),
                        _PrimaryButton(
                          label: 'Update now',
                          onPressed: onUpdate,
                        ),
                        if (!forceUpdate && onLater != null) ...[
                          const SizedBox(height: DesignToken.spacingMD),
                          TextButton(
                            onPressed: onLater,
                            style: TextButton.styleFrom(
                              foregroundColor: DesignToken.homeTextMuted,
                              padding: const EdgeInsets.symmetric(
                                vertical: DesignToken.spacingMD,
                                horizontal: DesignToken.spacing2XL,
                              ),
                            ),
                            child: Text(
                              'Maybe later',
                              style: AppTextStyles.nunitoSemiBold.copyWith(
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
                colors: DesignToken.primaryGradient,
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
              color: DesignToken.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -24,
            child: _DecorCircle(
              size: 72,
              color: DesignToken.secondary.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(DesignToken.spacingMD),
              decoration: BoxDecoration(
                color: DesignToken.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignToken.white.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(
                forceUpdate
                    ? Icons.system_update_alt_rounded
                    : Icons.rocket_launch_rounded,
                color: DesignToken.white,
                size: 36,
              ),
            ),
          ),
          if (forceUpdate)
            Positioned(
              top: DesignToken.spacingMD,
              right: DesignToken.spacingMD,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignToken.spacingMD,
                  vertical: DesignToken.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: DesignToken.secondary,
                  borderRadius: BorderRadius.circular(DesignToken.radiusRound),
                  boxShadow: [
                    BoxShadow(
                      color: DesignToken.secondary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Required',
                  style: AppTextStyles.nunitoBold.copyWith(
                    fontSize: 11,
                    color: DesignToken.white,
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
        color: DesignToken.white,
        borderRadius: BorderRadius.circular(DesignToken.radiusLG),
        border: Border.all(color: DesignToken.homeCardBorder),
        boxShadow: [
          BoxShadow(
            color: DesignToken.homeTextMuted.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(DesignToken.spacingSM),
      child: Image.asset(
        AppConstants.logoPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.stars_rounded, color: DesignToken.primary, size: 40),
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
        horizontal: DesignToken.spacingLG,
        vertical: DesignToken.spacingMD,
      ),
      decoration: BoxDecoration(
        color: DesignToken.carpenterAppBackground,
        borderRadius: BorderRadius.circular(DesignToken.radiusLG),
        border: Border.all(color: DesignToken.homeCardBorder),
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
              horizontal: DesignToken.spacingSM,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: DesignToken.primary.withValues(alpha: 0.7),
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
          style: AppTextStyles.nunitoMedium.copyWith(
            fontSize: 11,
            color: DesignToken.homeTextMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: DesignToken.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignToken.spacingMD,
            vertical: DesignToken.spacingXS,
          ),
          decoration: BoxDecoration(
            color: emphasized
                ? DesignToken.primary.withValues(alpha: 0.1)
                : DesignToken.grey100,
            borderRadius: BorderRadius.circular(DesignToken.radiusMD),
            border: emphasized
                ? Border.all(color: DesignToken.primary.withValues(alpha: 0.25))
                : null,
          ),
          child: Text(
            'v$version',
            style: AppTextStyles.nunitoBold.copyWith(
              fontSize: 14,
              color: emphasized ? DesignToken.primary : DesignToken.textDark,
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
        horizontal: DesignToken.spacingMD,
        vertical: DesignToken.spacingMD,
      ),
      decoration: BoxDecoration(
        color: DesignToken.blueShade50,
        borderRadius: BorderRadius.circular(DesignToken.radiusMD),
        border: Border.all(color: DesignToken.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: DesignToken.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: DesignToken.spacingSM),
          Expanded(
            child: Text(
              'This update is mandatory to keep using the app.',
              style: AppTextStyles.nunitoMedium.copyWith(
                fontSize: 13,
                height: 1.35,
                color: DesignToken.textDark.withValues(alpha: 0.85),
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
            colors: DesignToken.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(DesignToken.radiusMD),
          boxShadow: [
            BoxShadow(
              color: DesignToken.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(DesignToken.radiusMD),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.nunitoBold.copyWith(
                      fontSize: 16,
                      color: DesignToken.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: DesignToken.spacingSM),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: DesignToken.white,
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
