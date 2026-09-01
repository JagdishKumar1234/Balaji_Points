import 'dart:math' as math;

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/auth_provider.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    super.dispose();
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
      if (isLoggedIn && loggedInPhone != null && _phoneController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhone());
      }
    }
  }

  Future<void> _checkPhone() async {
    final v = _phoneController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
      _showSnack(l10n.enterValidTenDigit, isError: true);
      return;
    }

    // Logged-in user — session already proves the account exists.
    if (_isLoggedIn && _loggedInPhone != null) {
      final a = _pinAuthService.normalizePhone(_loggedInPhone!);
      final b = _pinAuthService.normalizePhone(v);
      if (a != b) return;
      setState(() { _phoneChecked = true; _phoneExists = true; });
      return;
    }

    setState(() { _isCheckingPhone = true; _phoneChecked = false; });
    final hasPin = await _pinAuthService.hasPin(v);
    if (!mounted) return;
    setState(() { _isCheckingPhone = false; _phoneChecked = true; _phoneExists = hasPin; });
    if (!hasPin) _showSnack(l10n.noAccountFound, isError: true);
  }

  bool _hasPinData() =>
      _pinController.text.isNotEmpty ||
      _confirmPinController.text.isNotEmpty ||
      _currentPinController.text.isNotEmpty;

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _saveNewPin() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    if (!_phoneChecked || !_phoneExists) {
      _showSnack(l10n.pleaseVerifyMobile, isError: true);
      return;
    }

    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final currentPin = _currentPinController.text.trim();
    final phone = _phoneController.text.trim();

    if (pin != confirm) { _showSnack(l10n.pinsDoNotMatch, isError: true); return; }

    if (_isLoggedIn) {
      if (currentPin.isEmpty || currentPin.length != 4) {
        _showSnack(l10n.enterCurrentPin, isError: true); return;
      }
      if (currentPin == pin) {
        _showSnack(l10n.newPinMustBeDifferent, isError: true); return;
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
      _showSnack(l10n.pinResetSuccess);
      _pinController.clear();
      _confirmPinController.clear();
      context.pop();
    } else {
      _showSnack(l10n.failedToResetPin, isError: true);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Cannot make phone call to $phoneNumber', isError: true);
      }
    } catch (e) {
      _showSnack('Error making phone call: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is ResetPinSuccess) {
        _showSnack(l10n.pinResetSuccess);
        _currentPinController.clear();
        _pinController.clear();
        _confirmPinController.clear();
        context.pop();
      } else if (state is ResetPinError) {
        _showSnack(state.message, isError: true);
      }
    });

    final isSaving = ref.watch(authProvider) is ResetPinLoading || _isForgotSaving;
    final canSubmit = _phoneChecked && _phoneExists;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          if (_hasPinData()) {
            final shouldDiscard = await BackButtonHandler.showDiscardDialog(context);
            if (shouldDiscard == true && mounted) {
              _pinController.clear();
              _confirmPinController.clear();
              _currentPinController.clear();
            }
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Top Controls ──
                      AuthTopControls(
                        themeToggle: _ThemeToggleButton(isDark: isDark)
                            .fadeIn(delay: AppAnimations.stagger(0)),
                        languagePicker: _LanguagePicker()
                            .fadeIn(delay: AppAnimations.stagger(0)),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Professional Auth Card with Back Button ──
                      Stack(
                        children: [
                          ProfessionalAuthCard(
                            isDark: isDark,
                            securityMessage: 'Your data is 100% secure with us',
                            child: Column(
                              children: [
                                // Header
                                Column(
                                  children: [
                                    // Logo
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001F4D),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/balaji_point_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ).enterHero(delay: AppAnimations.stagger(1)),
                                const SizedBox(height: AppSpacing.lg),

                                // Title
                                Text(
                                  l10n.resetPinTitle,
                                  style: AppTypography.displaySmall(
                                    color: const Color(0xFF001F4D),
                                  ).copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ).fadeIn(delay: AppAnimations.stagger(2)),
                                const SizedBox(height: 8),

                                // Subtitle
                                Text(
                                  l10n.resetPinSubtitle,
                                  style: AppTypography.bodyMedium(
                                    color: const Color(0xFF78909C),
                                  ),
                                  textAlign: TextAlign.center,
                                ).fadeIn(delay: AppAnimations.stagger(3)),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.xl3),

                            // Phone field
                            AppTextField.phone(
                              controller: _phoneController,
                              label: l10n.mobileNumber,
                              enabled: !_isLoggedIn,
                            ).fadeIn(delay: AppAnimations.stagger(4)),

                            const SizedBox(height: AppSpacing.xl2),

                            // Check number button (only for non-logged-in)
                            if (!_isLoggedIn)
                              Align(
                                alignment: Alignment.centerRight,
                                child: AppButton(
                                  label: _phoneChecked && _phoneExists
                                      ? l10n.verified
                                      : l10n.checkNumber,
                                  onPressed: _isCheckingPhone ? null : _checkPhone,
                                  isLoading: _isCheckingPhone,
                                  variant: _phoneChecked && _phoneExists
                                      ? AppButtonVariant.outline
                                      : AppButtonVariant.primary,
                                  fullWidth: false,
                                  icon: _phoneChecked && _phoneExists
                                      ? Icons.check_circle
                                      : Icons.search,
                                  verticalPadding: 10,
                                ).fadeIn(delay: AppAnimations.stagger(5)),
                              ),

                            // Verified badge for logged-in user
                            if (_isLoggedIn && _loggedInPhone != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: AppRadius.sm8,
                                    border: Border.all(color: AppColors.success, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.verified,
                                        style: AppTypography.labelSmall(
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).fadeIn(delay: AppAnimations.stagger(5)),
                              ),

                            if (!_isLoggedIn || _isLoggedIn && _loggedInPhone != null)
                              const SizedBox(height: AppSpacing.xl2),

                            // ── Current PIN (logged-in change flow) ──────
                            if (_isLoggedIn) ...[
                              AppTextField.pin(
                                controller: _currentPinController,
                                label: l10n.currentPinLabel,
                                validator: (v) {
                                  final val = v?.trim() ?? '';
                                  if (val.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                                    return l10n.enter4Digits;
                                  }
                                  return null;
                                },
                              ).fadeIn(delay: AppAnimations.stagger(6)),
                              const SizedBox(height: AppSpacing.xl2),

                              // Forgot PIN info box
                              AppCard(
                                padding: const EdgeInsets.all(16),
                                showShadow: false,
                                color: context.themePrimary.withValues(alpha: 0.05),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.help_outline, size: 18, color: context.themePrimary),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.forgotCurrentPin,
                                          style: AppTypography.labelSmall(
                                            color: context.themePrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.forgotPinHelp,
                                      style: AppTypography.bodySmall(
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Admin support contacts
                                    AppCard(
                                      padding: const EdgeInsets.all(12),
                                      showShadow: false,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.support_agent, size: 18, color: context.themeSecondary),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.adminSupportInfo,
                                                style: AppTypography.labelSmall(
                                                  color: context.themeSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _supportPhoneRow(
                                            phone: AppConstants.supportPhone1,
                                            label: l10n.supportPhone1,
                                            color: AppColors.success,
                                            icon: Icons.phone_android,
                                          ),
                                          const SizedBox(height: 8),
                                          _supportPhoneRow(
                                            phone: AppConstants.supportPhone2,
                                            label: l10n.supportPhone2,
                                            color: context.themePrimary,
                                            icon: Icons.phone,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).fadeIn(delay: AppAnimations.stagger(7)),
                              const SizedBox(height: AppSpacing.xl2),
                            ],

                            // ── New PIN ──────────────────────────────────
                            AppTextField.pin(
                              controller: _pinController,
                              label: l10n.newPinLabel,
                              validator: (v) {
                                final val = v?.trim() ?? '';
                                if (val.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                                  return l10n.enter4Digits;
                                }
                                return null;
                              },
                            ).fadeIn(
                              delay: AppAnimations.stagger(_isLoggedIn ? 8 : 6),
                            ),

                            const SizedBox(height: AppSpacing.xl2),

                            // ── Confirm PIN ──────────────────────────────
                            AppTextField.pin(
                              controller: _confirmPinController,
                              label: l10n.confirmPin,
                              validator: (v) {
                                final val = v?.trim() ?? '';
                                if (val.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                                  return l10n.enter4Digits;
                                }
                                if (val != _pinController.text.trim()) {
                                  return l10n.pinsDoNotMatch;
                                }
                                return null;
                              },
                            ).fadeIn(
                              delay: AppAnimations.stagger(_isLoggedIn ? 9 : 7),
                            ),

                            const SizedBox(height: AppSpacing.xl2),

                            // ── Reset PIN button ─────────────────────────
                            AppButton.secondary(
                              label: l10n.resetPin,
                              onPressed: (isSaving || !canSubmit) ? null : _saveNewPin,
                              isLoading: isSaving,
                            ).fadeIn(
                              delay: AppAnimations.stagger(_isLoggedIn ? 10 : 8),
                            ),

                            if (!_isLoggedIn && !canSubmit) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.pleaseVerifyMobile,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(
                                  color: context.themeTextSecondary,
                                ),
                              ).fadeIn(
                                delay: AppAnimations.stagger(9),
                              ),
                            ],
                          ],
                        ),
                      ).enterCard(
                        delay: AppAnimations.stagger(_isLoggedIn ? 11 : 9),
                      ),
                          // Back button (top-left, not scrollable - icon only)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/login');
                                  }
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(99)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: context.themePrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ).fadeIn(delay: AppAnimations.stagger(0)),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl2),

                      // ── Footer ──
                      AuthFooter(
                        companyName: l10n.companyName,
                        isDark: isDark,
                      ).fadeIn(
                        delay: AppAnimations.stagger(_isLoggedIn ? 12 : 10),
                      ),

                      const SizedBox(height: AppSpacing.xl3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportPhoneRow({
    required String phone,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _makePhoneCall(phone.replaceAll('-', '')),
      borderRadius: AppRadius.sm8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelSmall(color: color),
              ),
            ),
            Icon(Icons.call, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Theme toggle button ───────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  final bool isDark;
  const _ThemeToggleButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            size: 22,
            color: isDark ? AppColors.warning : context.themePrimary,
          ),
        ),
      ),
    );
  }
}

// ── Language picker ──────────────────────────────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(
            color: context.themeTextPrimary,
          ),
          dropdownColor: context.themeSurface,
          iconEnabledColor: isDark ? AppColors.white : context.themePrimary,
          icon: Icon(
            Icons.language_rounded,
            size: 22,
            color: isDark ? AppColors.white : context.themePrimary,
          ),
          onChanged: (locale) {
            if (locale != null) {
              ref.read(localeProvider.notifier).setLocale(locale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageEnglish),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageHindi),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageTamil),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Celebration painter (CustomPainter — no BuildContext, use raw AppColors) ──

enum FloatingType { coin, star, sparkle, points }

class FloatingElement {
  double x, y, speed, rotation;
  FloatingType type;

  FloatingElement({
    required this.x,
    required this.y,
    required this.speed,
    required this.type,
    this.rotation = 0,
  });
}

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
        ..color = _colorForType(element.type).withValues(alpha: 0.4 * opacity)
        ..style = PaintingStyle.fill;

      final pos = Offset(x * size.width, y * size.height);
      final rot = (animationValue * 2 * math.pi * element.speed) + element.rotation;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      switch (element.type) {
        case FloatingType.coin:
          canvas.drawCircle(Offset.zero, 8, paint);
          paint.color = AppColors.white.withValues(alpha: 0.6);
          canvas.drawCircle(const Offset(-3, -3), 2, paint);
        case FloatingType.star:
          final path = Path();
          for (int i = 0; i < 5; i++) {
            final a = (i * 4 * math.pi / 5) - math.pi / 2;
            final ix = math.cos(a) * 8.0;
            final iy = math.sin(a) * 8.0;
            i == 0 ? path.moveTo(ix, iy) : path.lineTo(ix, iy);
            final ia = a + (2 * math.pi / 5);
            path.lineTo(math.cos(ia) * 4.0, math.sin(ia) * 4.0);
          }
          path.close();
          canvas.drawPath(path, paint);
        case FloatingType.sparkle:
          canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), paint..strokeWidth = 2);
          canvas.drawLine(const Offset(0, -8), const Offset(0, 8), paint..strokeWidth = 2);
          canvas.drawCircle(Offset.zero, 3, paint);
        case FloatingType.points:
          final path = Path()
            ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 16, height: 12),
              const Radius.circular(8),
            ));
          canvas.drawPath(path, paint);
          paint.color = AppColors.white.withValues(alpha: 0.8);
          canvas.drawCircle(const Offset(-4, 0), 2, paint);
          canvas.drawCircle(const Offset(4, 0), 2, paint);
      }

      canvas.restore();
    }
  }

  Color _colorForType(FloatingType type) {
    switch (type) {
      case FloatingType.coin: return AppColors.warning;
      case FloatingType.star: return AppColors.gold;
      case FloatingType.sparkle: return AppColors.primary;
      case FloatingType.points: return AppColors.success;
    }
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter old) =>
      old.animationValue != animationValue;
}
