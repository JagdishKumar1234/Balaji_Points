import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:balaji_points/config/theme.dart' as LegacyTheme;
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
          backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.warning,
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
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isLoggedIn) {
      if (currentPin.isEmpty || currentPin.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.enterCurrentPin),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (currentPin == pin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.newPinMustBeDifferent),
            backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.success,
        ),
      );
      _pinController.clear();
      _confirmPinController.clear();
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToResetPin),
          backgroundColor: AppColors.error,
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
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: AppColors.error,
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
              SnackBar(content: Text(l10n.pinResetSuccess), backgroundColor: AppColors.success),
            );
            _currentPinController.clear();
            _pinController.clear();
            _confirmPinController.clear();
            context.pop();
          } else if (state is ResetPinError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        });

        final isSaving = ref.watch(authProvider) is ResetPinLoading || _isForgotSaving;
        final canSubmit = _phoneChecked && _phoneExists;

        return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              title: Text(l10n.resetPinTitle),
              leading: BackButton(
                color: AppColors.lightPrimary,
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
                    AppSpacing.xl2,
                    topInset + kToolbarHeight + AppSpacing.sm,
                    AppSpacing.xl2,
                    bottomInset + AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 8.0),

                        Text(
                          l10n.resetPinSubtitle,
                          textAlign: TextAlign.center,
                          style: LegacyTheme.AppTextStyles.nunitoRegular.copyWith(
                            fontSize: 12.0,
                            color: AppColors.lightTextPrimary.withOpacity(0.7),
                          ),
                        ),

                        SizedBox(height: 24.0),

                        // Glass Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.white.withOpacity(0.9),
                                    AppColors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12.0, offset: Offset(0, 6))].map((shadow) => shadow.copyWith(
                                  color: AppColors.lightPrimary.withOpacity(0.1),
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
                                        .copyWith(fontSize: 16.0),
                                    decoration: InputDecoration(
                                      labelText: l10n.mobileNumber,
                                      prefixText: "+91 ",
                                      counterText: "",
                                      filled: true,
                                      fillColor: _isLoggedIn
                                          ? AppColors.lightPrimary.withOpacity(0.1)
                                          : AppColors.lightPrimary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: const BorderSide(
                                          color: AppColors.lightPrimary,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.3),
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

                                  SizedBox(height: 12.0),

                                  if (!_isLoggedIn) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: _isCheckingPhone
                                            ? null
                                            : _checkPhone,
                                        icon: _isCheckingPhone
                                            ? SizedBox(
                                                width: 16.0,
                                                height: 16.0,
                                                child:
                                                    const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                            : Icon(
                                                _phoneChecked && _phoneExists
                                                    ? Icons.check_circle
                                                    : Icons.search,
                                                size: 16.0 + 2,
                                              ),
                                        label: Text(
                                          _phoneChecked && _phoneExists
                                              ? l10n.verified
                                              : l10n.checkNumber,
                                          style: LegacyTheme
                                              .AppTextStyles.nunitoSemiBold
                                              .copyWith(
                                                fontSize: 14.0,
                                              ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _phoneChecked &&
                                                  _phoneExists
                                              ? AppColors.success
                                              : AppColors.lightPrimary,
                                          foregroundColor: AppColors.white,
                                          padding: EdgeInsets.symmetric(horizontal: 16)
                                              .copyWith(
                                            top: AppSpacing.sm + 2,
                                            bottom: AppSpacing.sm + 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12.0),
                                  ],

                                  // Auto-verify if logged in
                                  if (_isLoggedIn && _loggedInPhone != null) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.1),
                                          borderRadius: AppRadius.forInput,
                                          border: Border.all(
                                            color: AppColors.success,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: AppColors.success,
                                            ),
                                            SizedBox(width: 8.0),
                                            Text(
                                              l10n.verified,
                                              style: LegacyTheme
                                                  .AppTextStyles
                                                  .nunitoSemiBold
                                                  .copyWith(
                                                    fontSize: 14.0,
                                                    color: AppColors.success,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: 20.0),

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
                                            fontSize: 20.0,
                                            letterSpacing: 8,
                                            color: AppColors.lightPrimary,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: l10n.currentPinLabel,
                                        counterText: "",
                                        filled: true,
                                        fillColor: AppColors.lightPrimary.withOpacity(0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.forCard,
                                          borderSide: BorderSide(
                                            color: AppColors.lightPrimary.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: AppRadius.forCard,
                                          borderSide: BorderSide(
                                            color: AppColors.lightPrimary.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: AppRadius.forCard,
                                          borderSide: const BorderSide(
                                            color: AppColors.lightPrimary,
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
                                    SizedBox(height: 16.0),
                                  ],

                                  // Admin Support Info (for users who forgot current PIN)
                                  if (_isLoggedIn) ...[
                                    SizedBox(height: 12.0),
                                    Container(
                                      padding: EdgeInsets.all(AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightPrimary.withOpacity(0.05),
                                        borderRadius: AppRadius.forInput,
                                        border: Border.all(
                                          color: AppColors.lightPrimary.withOpacity(0.2),
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
                                                color: AppColors.lightPrimary,
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                l10n.forgotCurrentPin,
                                                style: LegacyTheme
                                                    .AppTextStyles
                                                    .nunitoSemiBold
                                                    .copyWith(
                                                      fontSize: 14.0,
                                                      color: AppColors.lightPrimary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Text(
                                            l10n.forgotPinHelp,
                                            style: LegacyTheme
                                                .AppTextStyles
                                                .nunitoRegular
                                                .copyWith(
                                                  fontSize: 12.0,
                                                  color: AppColors.lightTextPrimary
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                          SizedBox(height: 12.0),
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.white,
                                              borderRadius: AppRadius.sm8,
                                              border: Border.all(
                                                color: AppColors.lightPrimary
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
                                                      color: AppColors.lightSecondary,
                                                    ),
                                                    SizedBox(width: 8.0),
                                                    Text(
                                                      l10n.adminSupportInfo,
                                                      style: LegacyTheme
                                                          .AppTextStyles
                                                          .nunitoSemiBold
                                                          .copyWith(
                                                            fontSize: 12.0,
                                                            color: AppColors.lightTextPrimary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.0),
                                                // Support Phone 1
                                                InkWell(
                                                  onTap: () => _makePhoneCall(
                                                    AppConstants.supportPhone1
                                                        .replaceAll('-', ''),
                                                  ),
                                                  borderRadius:
                                                      AppRadius.sm8,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(horizontal: 12),
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.success
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          AppRadius.sm8,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.phone_android,
                                                          size: 16,
                                                          color: AppColors.success,
                                                        ),
                                                        SizedBox(width: 8.0),
                                                        Expanded(
                                                          child: Text(
                                                            l10n.supportPhone1,
                                                            style: LegacyTheme
                                                                .AppTextStyles
                                                                .nunitoSemiBold
                                                                .copyWith(
                                                                  fontSize: 12.0,
                                                                  color:
                                                                      AppColors.success,
                                                                ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.call,
                                                          size: 16,
                                                          color: AppColors.success,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                // Support Phone 2
                                                InkWell(
                                                  onTap: () => _makePhoneCall(
                                                    AppConstants.supportPhone2
                                                        .replaceAll('-', ''),
                                                  ),
                                                  borderRadius:
                                                      AppRadius.sm8,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(horizontal: 12),
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.lightPrimary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          AppRadius.sm8,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.phone,
                                                          size: 16,
                                                          color: AppColors.lightPrimary,
                                                        ),
                                                        SizedBox(width: 8.0),
                                                        Expanded(
                                                          child: Text(
                                                            l10n.supportPhone2,
                                                            style: LegacyTheme
                                                                .AppTextStyles
                                                                .nunitoSemiBold
                                                                .copyWith(
                                                                  fontSize: 12.0,
                                                                  color:
                                                                      AppColors.lightPrimary,
                                                                ),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.call,
                                                          size: 16,
                                                          color: AppColors.lightPrimary,
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
                                    SizedBox(height: 16.0),
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
                                          fontSize: 20.0,
                                          letterSpacing: 8,
                                          color: AppColors.lightPrimary,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: l10n.newPinLabel,
                                      counterText: "",
                                      filled: true,
                                      fillColor: AppColors.lightPrimary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: const BorderSide(
                                          color: AppColors.lightPrimary,
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

                                  SizedBox(height: 16.0),

                                  // Confirm PIN Field
                                  TextFormField(
                                    controller: _confirmPinController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    maxLength: 4,
                                    textAlign: TextAlign.center,
                                    style: LegacyTheme.AppTextStyles.nunitoBold
                                        .copyWith(
                                          fontSize: 20.0,
                                          letterSpacing: 8,
                                          color: AppColors.lightPrimary,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: l10n.confirmPin,
                                      counterText: "",
                                      filled: true,
                                      fillColor: AppColors.lightPrimary.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: BorderSide(
                                          color: AppColors.lightPrimary.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: AppRadius.forCard,
                                        borderSide: const BorderSide(
                                          color: AppColors.lightPrimary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24.0),

                                  // Reset Button with Gradient
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: canSubmit
                                              ? [
                                                  AppColors.lightSecondary,
                                                  AppColors.lightSecondary
                                                      .withOpacity(0.8),
                                                ]
                                              : [
                                                  AppColors.grey500,
                                                  AppColors.grey500
                                                      .withValues(alpha: 0.8),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: AppRadius.forCard,
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8.0, offset: Offset(0, 4))]
                                            .map(
                                              (shadow) => shadow.copyWith(
                                                color: (canSubmit
                                                        ? AppColors.lightSecondary
                                                        : AppColors.grey500)
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
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: AppRadius.forCard,
                                          ),
                                        ),
                                        child: isSaving
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    AppColors.white,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                l10n.resetPin,
                                                style: LegacyTheme
                                                    .AppTextStyles
                                                    .nunitoBold
                                                    .copyWith(
                                                      color: AppColors.white,
                                                      fontSize: 18.0,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  if (!_isLoggedIn && !canSubmit) ...[
                                    SizedBox(height: 16.0),
                                    Text(
                                      l10n.pleaseVerifyMobile,
                                      textAlign: TextAlign.center,
                                      style: LegacyTheme.AppTextStyles.nunitoRegular
                                          .copyWith(
                                            fontSize: 12.0,
                                            color: AppColors.lightTextPrimary.withOpacity(0.7),
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
        return const Color(0xFFFFC107);
      case FloatingType.star:
        return AppColors.lightSecondary;
      case FloatingType.sparkle:
        return AppColors.lightPrimary;
      case FloatingType.points:
        return AppColors.success;
    }
  }

  void _drawCoin(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset.zero, 8, paint);
    paint.color = AppColors.white.withOpacity(0.6);
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
        Radius.circular(8.0),
      ),
    );
    canvas.drawPath(path, paint);

    paint.color = AppColors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(-4, 0), 2, paint);
    canvas.drawCircle(Offset(4, 0), 2, paint);
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
