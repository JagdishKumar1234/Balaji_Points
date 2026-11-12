import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/branch_picker.dart';
import 'package:balaji_points/services/branch/public_branches.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';

/// Job application: pick a branch, name + mobile, position + experience,
/// a few lines about yourself. Saved as an enquiry of type `career`, so the
/// chosen branch's admin sees it in their Enquiries. One screen, no
/// scrolling, Send fixed at the bottom.
class CareersPage extends ConsumerStatefulWidget {
  const CareersPage({super.key});

  @override
  ConsumerState<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends ConsumerState<CareersPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _position = TextEditingController();
  final _experience = TextEditingController();
  final _about = TextEditingController();
  PublicBranch? _branch;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _position, _experience, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    setState(() => _sending = true);
    try {
      await ref
          .read(enquiryServiceProvider)
          .submit(
            sender: const EnquirySender.guest(),
            type: EnquiryType.career,
            name: _name.text,
            phone: _phone.text,
            message: _about.text,
            position: _position.text,
            experience: _experience.text,
            guestBranchId: _branch?.id,
            guestBranchName: _branch?.label ?? '',
          );
      if (mounted) setState(() => _sent = true);
    } on EnquiryTooSoon catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.enquiryTooSoon((e.wait.inSeconds / 60).ceil().clamp(1, 99)),
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Career application failed', e);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.enquiryFailed),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: l10n.guestCareers,
            subtitle: l10n.guestCareersSub,
            showLogo: false,
            showProfileButton: false,
            showBackButton: true,
            onBackTap: () =>
                context.canPop() ? context.pop() : context.go('/guest'),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + (_sent ? MediaQuery.paddingOf(context).bottom : 0),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: _sent ? _done(context) : _formBody(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_sent) _footer(context),
        ],
      ),
    );
  }

  Widget _formBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.careerIntro,
            style: AppTypography.bodyMedium(color: context.themeTextSecondary),
          ),
          const SizedBox(height: 12),
          BranchPicker(
            value: _branch,
            onChanged: (b) => setState(() => _branch = b),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  _name,
                  l10n.enquiryNameLabel,
                  l10n.enquiryNameHint,
                  maxLength: 60,
                  capitalize: true,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? l10n.enquiryNameRequired
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _phone,
                  l10n.enquiryPhoneLabel,
                  l10n.enquiryPhoneHint,
                  keyboardType: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '')
                      ? null
                      : l10n.enquiryPhoneInvalid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  _position,
                  l10n.careerPosition,
                  l10n.careerPositionHint,
                  maxLength: 60,
                  capitalize: true,
                  validator: (v) => (v ?? '').trim().length < 2
                      ? l10n.careerPositionRequired
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _experience,
                  l10n.careerExperience,
                  l10n.careerExperienceHint,
                  maxLength: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: TextFormField(
                controller: _about,
                expands: true,
                maxLines: null,
                minLines: null,
                maxLength: 1000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textAlignVertical: TextAlignVertical.top,
                validator: (v) => (v ?? '').trim().length < 10
                    ? l10n.enquiryMessageTooShort
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.careerAbout,
                  hintText: l10n.careerAboutHint,
                  alignLabelWithHint: true,
                  counterText: '',
                  filled: true,
                  fillColor: context.themeCard,
                  border: OutlineInputBorder(borderRadius: AppRadius.md12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    bool capitalize = false,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: c,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    maxLength: maxLength,
    textCapitalization: capitalize
        ? TextCapitalization.words
        : TextCapitalization.none,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      isDense: true,
      filled: true,
      fillColor: context.themeCard,
      border: OutlineInputBorder(borderRadius: AppRadius.md12),
    ),
  );

  Widget _footer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + (keyboardOpen ? 0 : MediaQuery.paddingOf(context).bottom),
      ),
      decoration: BoxDecoration(
        color: context.themeBackground,
        border: Border(top: BorderSide(color: context.themeBorder)),
      ),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppButton(
            label: l10n.careerSubmit,
            icon: Icons.send_rounded,
            isLoading: _sending,
            onPressed: _sending ? null : _send,
          ),
        ),
      ),
    );
  }

  Widget _done(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.themeGoldSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 36,
            color: context.themePrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.careerSentTitle,
          style: AppTypography.h5(color: context.themeTextPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.enquirySentBranch(_branch?.label ?? ''),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: l10n.done,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/guest'),
        ),
      ],
    );
  }
}
