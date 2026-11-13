import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';

/// Shown instead of signing in when a member account is waiting for the
/// branch admin's approval ("Request sent" right after sign-up) or was
/// rejected. Fits one screen; the only action is to go back to sign-in.
class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({
    super.key,
    required this.gate,
    this.justRegistered = false,
  });

  final AccountGate gate;
  final bool justRegistered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final branch = gate.branchName.isNotEmpty
        ? gate.branchName
        : l10n.yourBranchFallback;

    final (IconData icon, Color color, String title, String body) =
        gate.isRejected
        ? (
            Icons.block_rounded,
            context.themeError,
            l10n.accountRejectedTitle,
            l10n.accountRejectedBody(branch),
          )
        : justRegistered
        ? (
            Icons.mark_email_read_rounded,
            AppColors.success,
            l10n.accountRequestSentTitle,
            l10n.accountRequestSentBody(branch),
          )
        : (
            Icons.hourglass_top_rounded,
            AppColors.warning,
            l10n.accountPendingTitle,
            l10n.accountPendingBody(branch),
          );

    return AuthScaffold(
      onBack: () => context.go('/login'),
      child: ProfessionalAuthCard(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              key: const ValueKey('account-status-title'),
              textAlign: TextAlign.center,
              style: AppTypography.h4(color: context.themeTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: context.themeTextSecondary,
              ),
            ),
            if (gate.isRejected && gate.rejectReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.rejectReasonValue(gate.rejectReason),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(
                  color: context.themeTextSecondary,
                ),
              ),
            ],
            if (gate.branchPhone.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppButton.outline(
                label: l10n.callBranchPhone(gate.branchPhone),
                icon: Icons.call_rounded,
                onPressed: () => _call(gate.branchPhone),
              ),
            ],
            const SizedBox(height: 12),
            AppButton.primary(
              label: l10n.backToSignIn,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _call(String phone) async {
    try {
      await launchUrl(
        Uri(scheme: 'tel', path: BranchSupport.dialable(phone)),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // No dialer on this device.
    }
  }
}

/// The message for a phone number that already has an account.
String phoneTakenMessage(BuildContext context, PhoneSignupResult r) {
  final l10n = AppLocalizations.of(context)!;
  final branch = r.branchName.isNotEmpty
      ? r.branchName
      : l10n.yourBranchFallback;
  return switch (r.check) {
    PhoneSignupCheck.pendingSameBranch => l10n.phoneTakenPending(branch),
    PhoneSignupCheck.rejectedSameBranch => l10n.phoneTakenRejected(branch),
    PhoneSignupCheck.approvedSameBranch => l10n.phoneTakenApproved,
    PhoneSignupCheck.otherBranch => l10n.phoneTakenOtherBranch,
    PhoneSignupCheck.free => '',
  };
}

/// Dialog for a phone number that already has an account, with the branch
/// phone to call when it is the same branch.
Future<void> showPhoneTakenDialog(BuildContext context, PhoneSignupResult r) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.numberAlreadyRegistered),
      content: Text(phoneTakenMessage(ctx, r)),
      actions: [
        if (r.branchPhone.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.call_rounded),
            label: Text(r.branchPhone),
            onPressed: () => AccountStatusPage._call(r.branchPhone),
          ),
        if (r.check == PhoneSignupCheck.approvedSameBranch)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: Text(l10n.backToSignIn),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
      ],
    ),
  );
}
