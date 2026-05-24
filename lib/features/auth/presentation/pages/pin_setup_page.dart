import 'dart:math' as math;
import 'dart:ui';

import 'package:balaji_points/config/theme.dart' as LegacyTheme;
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class PINSetupPage extends ConsumerStatefulWidget {
  final String? phoneNumber;

  const PINSetupPage({super.key, this.phoneNumber});

  @override
  ConsumerState<PINSetupPage> createState() => _PINSetupPageState();
}

class _PINSetupPageState extends ConsumerState<PINSetupPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _savePin() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinsDoNotMatch),
          backgroundColor: DesignToken.error,
        ),
      );
      return;
    }

    ref.read(authProvider.notifier).setupPin(
      phoneNumber: phone,
      pin: pin,
      firstName: '',
    );
  }

  bool _hasFormData() {
    return _phoneController.text.trim().isNotEmpty ||
        _pinController.text.trim().isNotEmpty ||
        _confirmPinController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is PinSetupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.pinCreatedSuccess), backgroundColor: DesignToken.success),
            );
            context.go('/');
          } else if (state is PinSetupError) {
            ScaffoldMessenger.of(context).clearSnackBars();
            String errorMessage = state.message;
            if (errorMessage.contains('already exists') || errorMessage.contains('User already exists')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.accountExistsUseReset),
                  backgroundColor: DesignToken.orange,
                  duration: const Duration(seconds: 6),
                  behavior: SnackBarBehavior.floating,
                  margin: DesignToken.paddingHorizontalLG,
                  dismissDirection: DismissDirection.horizontal,
                  action: SnackBarAction(
                    label: l10n.resetPin,
                    textColor: DesignToken.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      context.push('/reset-pin', extra: _phoneController.text.trim());
                    },
                  ),
                ),
              );
            } else {
              if (errorMessage.contains('permission-denied')) {
                errorMessage = 'Permission denied. Please check Firebase configuration or contact support.';
              } else if (errorMessage.contains('network')) {
                errorMessage = l10n.networkError;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: DesignToken.error,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: DesignToken.paddingHorizontalLG,
                  dismissDirection: DismissDirection.horizontal,
                ),
              );
            }
          }
        });

        final isSaving = ref.watch(authProvider) is PinSetupLoading;

        return Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: DesignToken.transparent,
              elevation: DesignToken.elevationNone,
              leading: BackButton(
                color: DesignToken.primary,
                onPressed: () => context.pop(),
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

                        // Logo
                        ClipRRect(
                          borderRadius: DesignToken.borderRadiusSM,
                          child: Image.asset(
                            'assets/images/balaji_point_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: DesignToken.heightMD),

                        Text(
                          l10n.createPinTitle,
                          style: LegacyTheme.AppTextStyles.nunitoBold.copyWith(
                            fontSize: DesignToken.fontSize3XL,
                            color: DesignToken.primary,
                          ),
                        ),

                        SizedBox(height: DesignToken.heightXS),
                        Text(
                          l10n.createPinSubtitle,
                          style: LegacyTheme.AppTextStyles.nunitoRegular.copyWith(
                            fontSize: DesignToken.fontSizeMD,
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
                                  // Phone Number
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    style: LegacyTheme.AppTextStyles.nunitoSemiBold
                                        .copyWith(fontSize: DesignToken.fontSizeLG),
                                    decoration: InputDecoration(
                                      labelText: l10n.mobileNumber,
                                      prefixText: "+91 ",
                                      counterText: "",
                                      filled: true,
                                      fillColor: DesignToken.primary.withOpacity(
                                        0.05,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.2,
                                          ),
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
                                      final v = value?.trim() ?? '';
                                      if (v.length != 10 ||
                                          !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                        return l10n.enterValidTenDigit;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: DesignToken.heightXL),

                                  // PIN
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
                                      labelText: l10n.fourDigitPin,
                                      counterText: '',
                                      filled: true,
                                      fillColor: DesignToken.primary.withOpacity(
                                        0.05,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.2,
                                          ),
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
                                      if (value == null || value.length != 4) {
                                        return l10n.enter4Digits;
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: DesignToken.heightLG),

                                  // Confirm PIN
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
                                      counterText: '',
                                      filled: true,
                                      fillColor: DesignToken.primary.withOpacity(
                                        0.05,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: DesignToken.borderRadiusLG,
                                        borderSide: BorderSide(
                                          color: DesignToken.primary.withOpacity(
                                            0.2,
                                          ),
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

                                  // Save Button with Gradient
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            DesignToken.secondary,
                                            DesignToken.secondary.withOpacity(0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: DesignToken.borderRadiusLG,
                                        boxShadow: DesignToken.shadowMD.map((shadow) => shadow.copyWith(
                                          color: DesignToken.secondary.withOpacity(0.4),
                                        )).toList(),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: isSaving ? null : _savePin,
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
                                                  color: DesignToken.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                l10n.savePin,
                                                style: LegacyTheme
                                                    .AppTextStyles
                                                    .nunitoBold
                                                    .copyWith(
                                                      fontSize: DesignToken.fontSizeXL,
                                                      color: DesignToken.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: DesignToken.heightXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
