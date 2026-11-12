import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';

/// Contact Us on one screen, no scrolling needed to send:
/// * Logged-in member: a strip with their branch's phone and email (tap to
///   call / mail), a topic, and a message. Name, phone, branch and role go
///   with it automatically, so it lands with that branch's admin.
/// * Guest: Balaji Points support strip, topic, name + mobile, message.
///   The enquiry has no branch or role and goes to the super admin.
/// The message box takes the space that is left; with the keyboard open
/// the page scrolls instead.
class ContactUsPage extends ConsumerStatefulWidget {
  const ContactUsPage({super.key});

  @override
  ConsumerState<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends ConsumerState<ContactUsPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  EnquiryType? _type;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  static String _tenDigits(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  /// A member whose saved profile lacks a name still types it. The mobile
  /// field is always shown: pre-filled with the login number for members,
  /// who can change it to be called back on another number.
  static bool _needsName(EnquirySender s) => !s.isMember || s.name.length < 2;
  bool _phonePrefilled = false;

  void _prefillPhone(EnquirySender s) {
    if (_phonePrefilled) return;
    _phonePrefilled = true;
    if (s.isMember) _phone.text = _tenDigits(s.phone);
  }

  Future<void> _send(EnquirySender sender) async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_form.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    setState(() => _sending = true);
    try {
      var version = '';
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}
      await ref
          .read(enquiryServiceProvider)
          .submit(
            sender: sender,
            type: _type ?? EnquiryType.other,
            name: _needsName(sender) ? _name.text : sender.name,
            phone: _tenDigits(_phone.text),
            message: _message.text,
            appVersion: version,
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
      AppLogger.error('Enquiry send failed', e);
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
    final sender = ref.watch(enquirySenderProvider).asData?.value;
    if (sender != null) _prefillPhone(sender);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeNavBar(
            title: l10n.contactUs,
            showLogo: false,
            showProfileButton: false,
            showBackButton: true,
            onBackTap: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          Expanded(
            child: sender == null
                ? const Center(child: AppLoader())
                : CustomScrollView(
                    slivers: [
                      // Padding inside the fill (not a SliverPadding),
                      // or it adds scroll room and the page scrolls.
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            // The footer pads for the system bar; when it is
                            // hidden (after sending) this does.
                            12 +
                                (_sent
                                    ? MediaQuery.paddingOf(context).bottom
                                    : 0),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  sender.isMember
                                      ? const _BranchStrip()
                                      : const _SupportStrip(),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _sent
                                        ? _Sent(
                                            sender: sender,
                                            onAnother: () => setState(() {
                                              _sent = false;
                                              _type = null;
                                              _message.clear();
                                            }),
                                          )
                                        : _formBody(context, sender),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (sender != null && !_sent) _footer(context, sender),
        ],
      ),
    );
  }

  Widget _formBody(BuildContext context, EnquirySender sender) {
    final l10n = AppLocalizations.of(context)!;
    final askName = _needsName(sender);
    final types = sender.isMember
        ? EnquiryType.forMember
        : EnquiryType.forGuest;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.enquiryTypeLabel,
            style: AppTypography.labelLarge(color: context.themeTextPrimary),
          ),
          const SizedBox(height: 8),
          FormField<EnquiryType>(
            validator: (_) => _type == null ? l10n.enquiryTypeLabel : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // One row of topics; swipe for more on narrow phones.
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: types.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = types[i];
                      final on = _type == t;
                      return ChoiceChip(
                        label: Text(enquiryTypeLabel(l10n, t)),
                        selected: on,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selectedColor: context.themePrimary,
                        backgroundColor: context.themeCard,
                        side: BorderSide(
                          color: on
                              ? context.themePrimary
                              : field.hasError
                              ? context.themeError
                              : context.themeBorder,
                        ),
                        labelStyle: AppTypography.labelMedium(
                          color: on
                              ? context.themeOnPrimary
                              : context.themeTextPrimary,
                        ),
                        onSelected: (_) {
                          setState(() => _type = t);
                          field.didChange(t);
                        },
                      );
                    },
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      field.errorText!,
                      style: AppTypography.caption(color: context.themeError),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (sender.isMember && !askName) ...[
            Text(
              l10n.contactSendingAs(
                [
                  sender.name,
                  enquiryRoleLabel(context, sender.role),
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (askName) ...[
                Expanded(
                  child: _field(
                    controller: _name,
                    label: l10n.enquiryNameLabel,
                    hint: l10n.enquiryNameHint,
                    maxLength: 60,
                    capitalize: true,
                    validator: (v) => (v ?? '').trim().length < 2
                        ? l10n.enquiryNameRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _field(
                  controller: _phone,
                  label: l10n.enquiryPhoneLabel,
                  hint: l10n.enquiryPhoneHint,
                  icon: askName ? null : Icons.phone_android_rounded,
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
          // Fills the space left, so Send sits at the bottom of the screen.
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 110),
              child: TextFormField(
                controller: _message,
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
                  labelText: l10n.enquiryMessageLabel,
                  hintText: l10n.enquiryMessageHint,
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

  /// Send stays fixed at the bottom (above the keyboard too); the form
  /// above it uses the rest of the screen.
  Widget _footer(BuildContext context, EnquirySender sender) {
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppButton(
            label: l10n.enquirySend,
            icon: Icons.send_rounded,
            isLoading: _sending,
            onPressed: _sending ? null : () => _send(sender),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    bool capitalize = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
        // Icon only when the field has the full row (members), so two
        // fields side by side keep room for their labels.
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: context.themeCard,
        border: OutlineInputBorder(borderRadius: AppRadius.md12),
      ),
    );
  }
}

/// Enquiry type in the current language (used by the admin inbox).
String enquiryTypeLabel(AppLocalizations l10n, EnquiryType t) => switch (t) {
  EnquiryType.product => l10n.enquiryTypeProduct,
  EnquiryType.quotation => l10n.enquiryTypeQuotation,
  EnquiryType.pointsBills => l10n.enquiryTypePointsBills,
  EnquiryType.appHelp => l10n.enquiryTypeAppHelp,
  EnquiryType.membership => l10n.enquiryTypeMembership,
  EnquiryType.other => l10n.enquiryTypeOther,
};

/// Role name for an id in the current language (custom roles: the id).
String enquiryRoleLabel(BuildContext context, String? id) {
  if (id == null || id.isEmpty) return '';
  final builtIn = AppRole.builtInDefault(id);
  return builtIn == null ? id : roleDisplayName(context, builtIn);
}

/// The member's branch in one compact strip: name, phone and email, with
/// Call and Email buttons. Falls back to Balaji Points support if the
/// branch has no contact details.
class _BranchStrip extends ConsumerWidget {
  const _BranchStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(branchSupportProvider);
    if (async.isLoading && !async.hasValue) {
      return const SizedBox(height: 76, child: Center(child: AppLoader()));
    }
    final s = async.asData?.value;
    if (s == null || !s.hasAnyContact) return const _SupportStrip();
    final phone = s.branch.phone.isNotEmpty ? s.branch.phone : s.adminPhone;
    return _ContactStrip(
      caption: l10n.contactYourBranch,
      name: s.branch.name,
      phone: phone,
      dial: phone.isEmpty ? null : BranchSupport.dialable(phone),
      email: s.adminEmail,
    );
  }
}

class _SupportStrip extends StatelessWidget {
  const _SupportStrip();

  @override
  Widget build(BuildContext context) => _ContactStrip(
    caption: AppLocalizations.of(context)!.appSupport,
    name: AppConstants.companyName,
    phone: AppConstants.supportPhoneDisplay,
    dial: AppConstants.supportPhoneE164,
    email: AppConstants.supportEmail,
  );
}

class _ContactStrip extends StatelessWidget {
  const _ContactStrip({
    required this.caption,
    required this.name,
    required this.phone,
    required this.dial,
    required this.email,
  });

  final String caption;
  final String name;
  final String phone;
  final String? dial;
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.forCard,
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$caption · $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          if (dial != null)
            _RoundAction(
              icon: Icons.call_rounded,
              tooltip: l10n.enquiryCall,
              uri: Uri(scheme: 'tel', path: dial),
            ),
          if (email.isNotEmpty)
            _RoundAction(
              icon: Icons.email_outlined,
              tooltip: l10n.email,
              uri: Uri(scheme: 'mailto', path: email),
            ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.uri,
  });

  final IconData icon;
  final String tooltip;
  final Uri uri;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: IconButton.filled(
      tooltip: tooltip,
      onPressed: () => launchUrl(uri),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primary,
      ),
      icon: Icon(icon, size: 20),
    ),
  );
}

class _Sent extends StatelessWidget {
  const _Sent({required this.sender, required this.onAnother});
  final EnquirySender sender;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = sender.isMember && sender.branchName.isNotEmpty
        ? l10n.enquirySentBranch(sender.branchName)
        : l10n.enquirySentTeam;
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
          l10n.enquirySentTitle,
          style: AppTypography.h5(color: context.themeTextPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: l10n.done,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        TextButton(onPressed: onAnother, child: Text(l10n.enquirySendAnother)),
      ],
    );
  }
}
