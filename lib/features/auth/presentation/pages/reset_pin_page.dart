import 'dart:math' as math;
import 'dart:ui';

import 'package:balaji_points/config/theme.dart' as LegacyTheme;
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/pin_auth_service.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class ResetPINPage extends ConsumerStatefulWidget {
  final String? phoneNumber;

  const ResetPINPage({super.key, this.phoneNumber});

  @override
  ConsumerState<ResetPINPage> createState() => _ResetPINPageState();
}

class _ResetPINPageState extends ConsumerState<ResetPINPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _sessionService = SessionService();
  final _pinAuthService = PinAuthService();

  bool _isLoggedIn = false;
  String? _loggedInPhone;
  bool _phoneChecked = false;
  bool _phoneExists = false;
  bool _isCheckingPhone = false;
  bool _isForgotSaving = false;

  @override
  void initState() {
    super.initState();

    _checkLoginStatus();

    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhone());
    }
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _sessionService.isLoggedIn();
    String? loggedInPhone;

    if (isLoggedIn) {
      loggedInPhone = await _sessionService.getPhoneNumber();
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _loggedInPhone = loggedInPhone;

        if (loggedInPhone != null && _phoneController.text.isEmpty) {
          _phoneController.text = loggedInPhone;
        }
      });

      if (isLoggedIn &&
          loggedInPhone != null &&
          _phoneController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhone());
      }
    }
  }

  Future<void> _checkPhone() async {
    final v = _phoneController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidTenDigit),
          backgroundColor: DesignToken.error,
        ),
      );
      return;
    }

    if (_isLoggedIn && _loggedInPhone != null) {
      final a = _pinAuthService.normalizePhone(_loggedInPhone!);
      final b = _pinAuthService.normalizePhone(v);
      if (a != b) {
        return;
      }
    }

    setState(() {
      _isCheckingPhone = true;
      _phoneChecked = false;
    });

    final hasPin = await _pinAuthService.hasPin(v);

    if (!mounted) return;

    setState(() {
      _isCheckingPhone = false;
      _phoneChecked = true;
      _phoneExists = hasPin;
    });

    if (!hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noAccountFound),
          backgroundColor: DesignToken.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  bool _hasPinData() {
    return _pinController.text.trim().isNotEmpty ||
        _confirmPinController.text.trim().isNotEmpty ||
        _currentPinController.text.trim().isNotEmpty;
  }

  Future<void> _saveNewPin() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    if (!_phoneChecked || !_phoneExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseVerifyMobile),
          backgroundColor: DesignToken.orange,
        ),
      );
      return;
    }

    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final currentPin = _currentPinController.text.trim();
    final phone = _phoneController.text.trim();

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinsDoNotMatch),
          backgroundColor: DesignToken.error,
        ),
      );
      return;
    }

    if (_isLoggedIn) {
      if (currentPin.isEmpty || currentPin.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.enterCurrentPin),
            backgroundColor: DesignToken.error,
          ),
        );
        return;
      }

      if (currentPin == pin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newPinMustBeDifferent),
            backgroundColor: DesignToken.error,
          ),
        );
        return;
      }

      ref.read(authProvider.notifier).resetPin(
        phoneNumber: phone,
        oldPin: currentPin,
        newPin: pin,
      );
      return;
    }

    setState(() => _isForgotSaving = true);
    final ok = await _pinAuthService.setPinForPhone(phone: phone, pin: pin);
    if (!mounted) return;
    setState(() => _isForgotSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinResetSuccess),
          backgroundColor: DesignToken.success,
        ),
      );
      _pinController.clear();
      _confirmPinController.clear();
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToResetPin),
          backgroundColor: DesignToken.error,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make phone call to $phoneNumber'),
              backgroundColor: DesignToken.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: DesignToken.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }

          if (_hasPinData()) {
            final shouldDiscard = await BackButtonHandler.showDiscardDialog(
              context,
            );
            if (shouldDiscard == true && mounted) {
              setState(() {
                _pinController.clear();
                _confirmPinController.clear();
                _currentPinController.clear();
              });
            }
          } else {
            context.pop();
          }
        }
      },
      child: Builder(builder: (context) {
        ref.listen<AuthState>(authProvider, (_, state) {
          if (state is ResetPinSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.pinResetSuccess), backgroundColor: DesignToken.success),
            );
            _currentPinController.clear();
            _pinController.clear();
            _confirmPinController.clear();
            context.pop();
          } else if (state is ResetPinError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: DesignToken.error),
            );
          }
        });

        final isSaving = ref.watch(authProvider) is ResetPinLoading || _isForgotSaving;
        final canSubmit = _phoneChecked && _phoneExists;

        return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: DesignToken.transparent,
              elevation: DesignToken.elevationNone,
              title: Text(l10n.resetPinTitle),
              leading: BackButton(
                color: DesignToken.primary,
                onPressed: () {
                  if (_hasPinData()) {
                    Navigator.of(context).maybePop();
                  } else {
                    context.pop();
                  }
                },
              ),
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background_image.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Main Content
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    DesignToken.spacing2XL,
                    topInset + kToolbarHeight + DesignToken.spacingSM,
                    DesignToken.spacing2XL,
                    bottomInset + DesignToken.spacingXL,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: DesignToken.heightSM),

                        Text(
                          l10n.resetPinSubtitle,
                          textAlign: TextAlign.center,
                          style: LegacyTheme.AppTextStyles.nunitoRegular.copyWith(
                            fontSize: DesignToken.fontSizeSM,
                            color: DesignToken.textDark.withOpacity(0.7),
                          ),
                        ),

                        SizedBox(height: DesignToken.height2XL),

                        // Glass Card
                        ClipRRect(
                          borderRadius: DesignToken.borderRadius2XL,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: DesignToken.paddingAll2XL,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    DesignToken.white.withOpacity(0.9),
                                    DesignToken.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: DesignToken.borderRadius2XL,
                                border: Border.all(
                                  color: DesignToken.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: DesignToken.shadowLG.map((shadow) => shadow.copyWith(
                                  color: DesignToken.primary.withOpacity(0.1),
                                )).toList(),
                              ),
                              child: Column(
                                children: [
                                  // Phone Number Field
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    enabled: !_isLoggedIn,
                                    style: LegacyTheme.AppTextStyles.nunitoSemiBold
                                        .copyWith(fontSize: DesignToken.fontSizeLG),
                                    decoration: InputDecoration(
                                      labelText: l10n.mobileNumber,
                                      prefixText: "+91 ",
                                      counterText: "",
                                      filled: true,
                                      fillColor: _isLoggedIn
                                          ? DesignToken.primary.withOpacity(0.1)
                                          : DesignToken.primary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: const BorderSide(
                                          color: DesignToken.primary,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.length != 10 ||
                                          !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                        return l10n.enterValidTenDigit;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: DesignToken.heightMD),

                                  if (!_isLoggedIn) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: _isCheckingPhone
                                            ? null
                                            : _checkPhone,
                                        icon: _isCheckingPhone
                                            ? SizedBox(
                                                width: DesignToken.iconSizeSM,
                                                height: DesignToken.iconSizeSM,
                                                child:
                                                    const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: DesignToken.white,
                                                ),
                                              )
                                            : Icon(
                                                _phoneChecked && _phoneExists
                                                    ? Icons.check_circle
                                                    : Icons.search,
                                                size: DesignToken.iconSizeSM + 2,
                                              ),
                                        label: Text(
                                          _phoneChecked && _phoneExists
                                              ? l10n.verified
                                              : l10n.checkNumber,
                                          style: LegacyTheme
                                              .AppTextStyles.nunitoSemiBold
                                              .copyWith(
                                                fontSize: DesignToken.fontSizeMD,
                                              ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _phoneChecked &&
                                                  _phoneExists
                                              ? DesignToken.success
                                              : DesignToken.primary,
                                          foregroundColor: DesignToken.white,
                                          padding: DesignToken.paddingHorizontalLG
                                              .copyWith(
                                            top: DesignToken.paddingSM + 2,
                                            bottom: DesignToken.paddingSM + 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: DesignToken.heightMD),
                                  ],

                                  // Auto-verify if logged in
                                  if (_isLoggedIn && _loggedInPhone != null) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: DesignToken.paddingHorizontalLG,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: DesignToken.success.withOpacity(0.1),
                                          borderRadius: DesignToken.borderRadiusMD,
                                          border: Border.all(
                                            color: DesignToken.success,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: DesignToken.success,
                                            ),
                                            SizedBox(width: DesignToken.widthSM),
                                            Text(
                                              l10n.verified,
                                              style: LegacyTheme
                                                  .AppTextStyles
                                                  .nunitoSemiBold
                                                  .copyWith(
                                                    fontSize: DesignToken.fontSizeMD,
                                                    color: DesignToken.success,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: DesignToken.heightXL),

                                  // Current PIN Field (Required for logged-in users)
                                  if (_isLoggedIn) ...[
                                    TextFormField(
                                      controller: _currentPinController,
                                      keyboardType: TextInputType.number,
                                      obscureText: true,
                                      maxLength: 4,
                                      textAlign: TextAlign.center,
                                      style: LegacyTheme.AppTextStyles.nunitoBold
                                          .copyWith(
                                            fontSize: DesignToken.fontSize2XL,
                                            letterSpacing: 8,
                                            color: DesignToken.primary,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: l10n.currentPinLabel,
                                        counterText: "",
                                        filled: true,
                                        fillColor: DesignToken.primary.withOpacity(0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: DesignToken.borderRadiusLG,
                                          borderSide: BorderSide(
                                            color: DesignToken.primary.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: DesignToken.borderRadiusLG,
                                          borderSide: BorderSide(
                                            color: DesignToken.primary.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: DesignToken.borderRadiusLG,
                                          borderSide: const BorderSide(
                                            color: DesignToken.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        final v = value?.trim() ?? "";
                                        if (v.length != 4 ||
                                            !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                          return l10n.enter4Digits;
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: DesignToken.heightLG),
                                  ],

                                  // Admin Support Info (for users who forgot current PIN)
                                  if (_isLoggedIn) ...[
                                    SizedBox(height: DesignToken.heightMD),
                                    Container(
                                      padding: EdgeInsets.all(DesignToken.paddingLG),
                                      decoration: BoxDecoration(
                                        color: DesignToken.primary.withOpacity(0.05),
                                        borderRadius: DesignToken.borderRadiusMD,
                                        border: Border.all(
                                          color: DesignToken.primary.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.help_outline,
                                                size: 20,
                                                color: DesignToken.primary,
                                              ),
                                              SizedBox(width: DesignToken.widthSM),
                                              Text(
                                                l10n.forgotCurrentPin,
                                                style: LegacyTheme
                                                    .AppTextStyles
                                                    .nunitoSemiBold
                                                    .copyWith(
                                                      fontSize: DesignToken.fontSizeMD,
                                                      color: DesignToken.primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: DesignToken.heightSM),
                                          Text(
                                            l10n.forgotPinHelp,
                                            style: LegacyTheme
                                                .AppTextStyles
                                                .nunitoRegular
                                                .copyWith(
                                                  fontSize: DesignToken.fontSizeSM,
                                                  color: DesignToken.textDark
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                          SizedBox(height: DesignToken.heightMD),
                                          Container(
                                            padding: DesignToken.paddingAllSM,
                                            decoration: BoxDecoration(
                                              color: DesignToken.white,
                                              borderRadius: DesignToken.borderRadiusSM,
                                              border: Border.all(
                                                color: DesignToken.primary
                                                    .withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.support_agent,
                                                      size: 18,
                                                      color: DesignToken.secondary,
                                                    ),
                                                    SizedBox(width: DesignToken.widthSM),
                                                    Text(
                                                      l10n.adminSupportInfo,
                                                      style: LegacyTheme
                                                          .AppTextStyles
                                                          .nunitoSemiBold
                                                          .copyWith(
                                                            fontSize: DesignToken.fontSizeSM,
                                                            color: DesignToken.textDark,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: DesignToken.heightSM),
                                                // Support Phone 1
                                                InkWell(
                                                  onTap: () => _makePhoneCall(
                                                    AppConstants.supportPhone1
                                                        .replaceAll('-', ''),
                                                  ),
                                                  borderRadius:
                                                      DesignToken.borderRadiusSM,
                                                  child: Container(
                                                    padding:
                                                        DesignToken.paddingHorizontalMD,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: DesignToken.success
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          DesignToken.borderRadiusSM,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.phone_android,
                                                          size: 16,
                                                          color: DesignToken.success,
                                                        ),
                                                        SizedBox(width: DesignToken.widthSM),
                                                        Expanded(
                                                          child: Text(
                                                            l10n.supportPhone1,
                                                            style: LegacyTheme
                                                                .AppTextStyles
                                                                .nunitoSemiBold
                                                                .copyWith(
                                                                  fontSize: DesignToken.fontSizeSM,
                                                                  color:
                                                                      DesignToken.success,
                                                                ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.call,
                                                          size: 16,
                                                          color: DesignToken.success,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: DesignToken.heightSM),
                                                // Support Phone 2
                                                InkWell(
                                                  onTap: () => _makePhoneCall(
                                                    AppConstants.supportPhone2
                                                        .replaceAll('-', ''),
                                                  ),
                                                  borderRadius:
                                                      DesignToken.borderRadiusSM,
                                                  child: Container(
                                                    padding:
                                                        DesignToken.paddingHorizontalMD,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: DesignToken.primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          DesignToken.borderRadiusSM,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.phone,
                                                          size: 16,
                                                          color: DesignToken.primary,
                                                        ),
                                                        SizedBox(width: DesignToken.widthSM),
                                                        Expanded(
                                                          child: Text(
                                                            l10n.supportPhone2,
                                                            style: LegacyTheme
                                                                .AppTextStyles
                                                                .nunitoSemiBold
                                                                .copyWith(
                                                                  fontSize: DesignToken.fontSizeSM,
                                                                  color:
                                                                      DesignToken.primary,
                                                                ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.call,
                                                          size: 16,
                                                          color: DesignToken.primary,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: DesignToken.heightLG),
                                  ],

                                  // New PIN Field
                                  TextFormField(
                                    controller: _pinController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    style: LegacyTheme.AppTextStyles.nunitoBold
                                        .copyWith(
                                          fontSize: DesignToken.fontSize2XL,
                                          letterSpacing: 8,
                                          color: DesignToken.primary,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: l10n.newPinLabel,
                                      counterText: "",
                                      filled: true,
                                      fillColor: DesignToken.primary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: const BorderSide(
                                          color: DesignToken.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value?.trim() ?? "";
                                      if (v.length != 4 ||
                                          !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                        return l10n.enter4Digits;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: DesignToken.heightLG),

                                  // Confirm PIN Field
                                  TextFormField(
                                    controller: _confirmPinController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    style: LegacyTheme.AppTextStyles.nunitoBold
                                        .copyWith(
                                          fontSize: DesignToken.fontSize2XL,
                                          letterSpacing: 8,
                                          color: DesignToken.primary,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: l10n.confirmPin,
                                      counterText: "",
                                      filled: true,
                                      fillColor: DesignToken.primary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: const BorderSide(
                                          color: DesignToken.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: DesignToken.height2XL),

                                  // Reset Button with Gradient
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: canSubmit
                                              ? [
                                                  DesignToken.secondary,
                                                  DesignToken.secondary
                                                      .withOpacity(0.8),
                                                ]
                                              : [
                                                  DesignToken.grey500,
                                                  DesignToken.grey500
                                                      .withValues(alpha: 0.8),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: DesignToken.borderRadiusLG,
                                        boxShadow: DesignToken.shadowMD
                                            .map(
                                              (shadow) => shadow.copyWith(
                                                color: (canSubmit
                                                        ? DesignToken.secondary
                                                        : DesignToken.grey500)
                                                    .withOpacity(0.4),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: (isSaving || !canSubmit)
                                            ? null
                                            : () => _saveNewPin(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DesignToken.transparent,
                                          shadowColor: DesignToken.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: DesignToken.borderRadiusLG,
                                          ),
                                        ),
                                        child: isSaving
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    DesignToken.white,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                l10n.resetPin,
                                                style: LegacyTheme
                                                    .AppTextStyles
                                                    .nunitoBold
                                                    .copyWith(
                                                      color: DesignToken.white,
                                                      fontSize: DesignToken.fontSizeXL,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  if (!_isLoggedIn && !canSubmit) ...[
                                    SizedBox(height: DesignToken.heightLG),
                                    Text(
                                      l10n.pleaseVerifyMobile,
                                      textAlign: TextAlign.center,
                                      style: LegacyTheme.AppTextStyles.nunitoRegular
                                          .copyWith(
                                            fontSize: DesignToken.fontSizeSM,
                                            color: DesignToken.textDark.withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
      }),
    );
  }
}

// Floating Element Types
enum FloatingType { coin, star, sparkle, points }

// Floating Element Data
class FloatingElement {
  double x;
  double y;
  double speed;
  FloatingType type;
  double rotation = 0;

  FloatingElement({
    required this.x,
    required this.y,
    required this.speed,
    required this.type,
  });
}

// Celebration Background Painter
class CelebrationPainter extends CustomPainter {
  final double animationValue;
  final List<FloatingElement> elements;

  CelebrationPainter({required this.animationValue, required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    for (var element in elements) {
      final y = (element.y + animationValue * element.speed) % 1.2 - 0.1;
      final x = element.x;

      final opacity = (y < 0 || y > 1)
          ? 0.0
          : (y < 0.1 || y > 0.9 ? (y < 0.1 ? y / 0.1 : (1.0 - y) / 0.1) : 1.0);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = _getColorForType(element.type).withOpacity(0.4 * opacity)
        ..style = PaintingStyle.fill;

      final position = Offset(x * size.width, y * size.height);
      final rotation =
          (animationValue * 2 * math.pi * element.speed) + element.rotation;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      switch (element.type) {
        case FloatingType.coin:
          _drawCoin(canvas, paint);
          break;
        case FloatingType.star:
          _drawStar(canvas, paint);
          break;
        case FloatingType.sparkle:
          _drawSparkle(canvas, paint);
          break;
        case FloatingType.points:
          _drawPoints(canvas, paint);
          break;
      }

      canvas.restore();
    }
  }

  Color _getColorForType(FloatingType type) {
    switch (type) {
      case FloatingType.coin:
        return DesignToken.amber;
      case FloatingType.star:
        return DesignToken.secondary;
      case FloatingType.sparkle:
        return DesignToken.primary;
      case FloatingType.points:
        return DesignToken.success;
    }
  }

  void _drawCoin(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset.zero, 8, paint);
    paint.color = DesignToken.white.withOpacity(0.6);
    canvas.drawCircle(Offset(-3, -3), 2, paint);
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final path = Path();
    final outerRadius = 8.0;
    final innerRadius = 4.0;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final x = math.cos(angle) * outerRadius;
      final y = math.sin(angle) * outerRadius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final innerAngle =
          (i * 4 * math.pi / 5) - math.pi / 2 + (2 * math.pi / 5);
      final innerX = math.cos(innerAngle) * innerRadius;
      final innerY = math.sin(innerAngle) * innerRadius;
      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Paint paint) {
    canvas.drawLine(Offset(-8, 0), Offset(8, 0), paint..strokeWidth = 2);
    canvas.drawLine(Offset(0, -8), Offset(0, 8), paint..strokeWidth = 2);
    canvas.drawCircle(Offset.zero, 3, paint);
  }

  void _drawPoints(Canvas canvas, Paint paint) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 12),
        Radius.circular(DesignToken.radiusSM),
      ),
    );
    canvas.drawPath(path, paint);

    paint.color = DesignToken.white.withOpacity(0.8);
    canvas.drawCircle(Offset(-4, 0), 2, paint);
    canvas.drawCircle(Offset(4, 0), 2, paint);
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
