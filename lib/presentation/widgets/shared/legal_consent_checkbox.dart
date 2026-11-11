import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "I have read and agree to the Terms & Conditions and the Privacy Policy",
/// with both names as links. Registration needs it ticked.
class LegalConsentCheckbox extends StatefulWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Shows the "please accept" message (after a register attempt).
  final bool showError;

  @override
  State<LegalConsentCheckbox> createState() => _LegalConsentCheckboxState();
}

class _LegalConsentCheckboxState extends State<LegalConsentCheckbox> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => context.push('/terms');
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => context.push('/privacy');

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = AppTypography.bodySmall(color: context.themeTextPrimary);
    final link = base.copyWith(
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      color: context.themeTextPrimary,
    );
    final error = widget.showError && !widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                key: const ValueKey('legal-consent'),
                value: widget.value,
                isError: error,
                onChanged: (v) => widget.onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(text: l10n.legalAgreePrefix),
                      TextSpan(
                        text: l10n.legalTermsTitle,
                        style: link,
                        recognizer: _terms,
                      ),
                      TextSpan(text: l10n.legalAgreeAnd),
                      TextSpan(
                        text: l10n.legalPrivacyTitle,
                        style: link,
                        recognizer: _privacy,
                      ),
                      TextSpan(text: l10n.legalAgreeSuffix),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 4),
            child: Text(
              l10n.legalAcceptToContinue,
              style: AppTypography.caption(color: context.themeError),
            ),
          ),
      ],
    );
  }
}
