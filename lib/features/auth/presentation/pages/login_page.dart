import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/presentation/providers/locale_provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _checkUserAndNavigate() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    ref.read(authProvider.notifier).checkUserExists(phone);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthUserExists) {
        context.push('/pin-login?phone=${state.phoneNumber}');
      } else if (state is AuthUserNotFound) {
        context.push('/pin-setup?phone=${state.phoneNumber}');
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${state.message}'),
            backgroundColor: DesignToken.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isChecking = authState is AuthCheckingUser;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          final shouldExit = await BackButtonHandler.showExitConfirmation(context);
          if (shouldExit == true && mounted) BackButtonHandler.exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/images/background_image.png', fit: BoxFit.cover),
                  ),
                  SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: bottomInset + DesignToken.spacingXL),
                      child: Padding(
                        padding: DesignToken.paddingHorizontal2XL,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(height: DesignToken.heightXL),

                              // Language switcher
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: DesignToken.paddingHorizontalMD,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: DesignToken.white,
                                    borderRadius: DesignToken.borderRadiusMD,
                                    border: Border.all(color: DesignToken.primary.withOpacity(0.3)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Locale>(
                                      value: ref.watch(localeProvider),
                                      onChanged: (Locale? newLocale) {
                                        if (newLocale != null) {
                                          ref.read(localeProvider.notifier).setLocale(newLocale);
                                        }
                                      },
                                      items: [
                                        DropdownMenuItem(value: const Locale('en'), child: Text(l10n.languageEnglish)),
                                        DropdownMenuItem(value: const Locale('hi'), child: Text(l10n.languageHindi)),
                                        DropdownMenuItem(value: const Locale('ta'), child: Text(l10n.languageTamil)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: DesignToken.heightXL),

                              ClipRRect(
                                borderRadius: DesignToken.borderRadiusSM,
                                child: Image.asset('assets/images/balaji_point_logo.png', width: 100, height: 100),
                              ),
                              SizedBox(height: DesignToken.heightLG),
                              Text(
                                'Balaji Points',
                                style: AppTextStyles.nunitoBold.copyWith(
                                  fontSize: DesignToken.fontSize5XL,
                                  color: DesignToken.primary,
                                ),
                              ),

                              SizedBox(height: DesignToken.height2XL),
                              Text(
                                l10n.enterPhoneNumber,
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: DesignToken.fontSizeLG,
                                  color: DesignToken.textDark,
                                ),
                              ),
                              SizedBox(height: DesignToken.height3XL),

                              // Glass card
                              ClipRRect(
                                borderRadius: DesignToken.borderRadius2XL,
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: EdgeInsets.all(DesignToken.padding3XL),
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
                                      border: Border.all(color: DesignToken.white.withOpacity(0.5), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: DesignToken.primary.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        TextFormField(
                                          controller: _phoneController,
                                          maxLength: 10,
                                          keyboardType: TextInputType.phone,
                                          style: AppTextStyles.nunitoSemiBold.copyWith(
                                            fontSize: DesignToken.fontSizeXL,
                                            color: DesignToken.textDark,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: l10n.mobileNumber,
                                            labelStyle: AppTextStyles.nunitoMedium.copyWith(fontSize: DesignToken.fontSizeLG),
                                            prefixText: '+91 ',
                                            prefixStyle: AppTextStyles.nunitoSemiBold.copyWith(
                                              fontSize: DesignToken.fontSizeXL,
                                              color: DesignToken.primary,
                                            ),
                                            counterText: '',
                                            filled: true,
                                            fillColor: DesignToken.primary.withOpacity(0.05),
                                            border: OutlineInputBorder(
                                              borderRadius: DesignToken.borderRadiusLG,
                                              borderSide: BorderSide(color: DesignToken.primary.withOpacity(0.3), width: 1.5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: DesignToken.borderRadiusLG,
                                              borderSide: BorderSide(color: DesignToken.primary.withOpacity(0.2), width: 1.5),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: DesignToken.borderRadiusLG,
                                              borderSide: const BorderSide(color: DesignToken.primary, width: 2),
                                            ),
                                          ),
                                          validator: (value) {
                                            final v = value?.trim() ?? '';
                                            if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                              return l10n.enterValidTenDigit;
                                            }
                                            return null;
                                          },
                                        ),

                                        SizedBox(height: DesignToken.height2XL),

                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [DesignToken.secondary, DesignToken.secondary.withOpacity(0.8)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: DesignToken.borderRadiusLG,
                                            boxShadow: [
                                              BoxShadow(
                                                color: DesignToken.secondary.withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isChecking ? null : _checkUserAndNavigate,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: DesignToken.transparent,
                                              shadowColor: DesignToken.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(borderRadius: DesignToken.borderRadiusLG),
                                            ),
                                            child: Text(
                                              l10n.continueWithPin,
                                              style: AppTextStyles.nunitoBold.copyWith(
                                                fontSize: DesignToken.fontSizeXL,
                                                color: isChecking ? DesignToken.white.withOpacity(0.7) : DesignToken.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: DesignToken.height2XL),
                              Text(
                                '${l10n.poweredBy} ${l10n.companyName}',
                                style: DesignToken.labelMedium.copyWith(
                                  color: DesignToken.primary,
                                  fontWeight: FontWeight.w700,
                                  shadows: [Shadow(color: DesignToken.white, blurRadius: 10, offset: const Offset(0, 2))],
                                ),
                              ),
                              SizedBox(height: DesignToken.height3XL),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating animation helpers (unchanged) ────────────────────────────────────

enum FloatingType { coin, star, sparkle, points }

class FloatingElement {
  double x, y, speed;
  FloatingType type;
  double rotation = 0;
  FloatingElement({required this.x, required this.y, required this.speed, required this.type});
}

class CelebrationPainter extends CustomPainter {
  final double animationValue;
  final List<FloatingElement> elements;
  CelebrationPainter({required this.animationValue, required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    for (var element in elements) {
      final y = (element.y + animationValue * element.speed) % 1.2 - 0.1;
      final opacity = (y < 0 || y > 1) ? 0.0 : (y < 0.1 || y > 0.9 ? (y < 0.1 ? y / 0.1 : (1.0 - y) / 0.1) : 1.0);
      if (opacity <= 0) continue;
      final paint = Paint()
        ..color = _colorFor(element.type).withOpacity(0.4 * opacity)
        ..style = PaintingStyle.fill;
      final pos = Offset(element.x * size.width, y * size.height);
      final rot = (animationValue * 2 * math.pi * element.speed) + element.rotation;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      switch (element.type) {
        case FloatingType.coin: _drawCoin(canvas, paint); break;
        case FloatingType.star: _drawStar(canvas, paint); break;
        case FloatingType.sparkle: _drawSparkle(canvas, paint); break;
        case FloatingType.points: _drawPoints(canvas, paint); break;
      }
      canvas.restore();
    }
  }

  Color _colorFor(FloatingType t) => switch (t) {
    FloatingType.coin => DesignToken.amber,
    FloatingType.star => DesignToken.secondary,
    FloatingType.sparkle => DesignToken.primary,
    FloatingType.points => DesignToken.success,
  };

  void _drawCoin(Canvas c, Paint p) { c.drawCircle(Offset.zero, 8, p); p.color = DesignToken.white.withOpacity(0.6); c.drawCircle(const Offset(-3, -3), 2, p); }
  void _drawStar(Canvas c, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = (i * 4 * math.pi / 5) - math.pi / 2;
      i == 0 ? path.moveTo(math.cos(a) * 8, math.sin(a) * 8) : path.lineTo(math.cos(a) * 8, math.sin(a) * 8);
      final ia = a + (2 * math.pi / 5);
      path.lineTo(math.cos(ia) * 4, math.sin(ia) * 4);
    }
    path.close();
    c.drawPath(path, p);
  }
  void _drawSparkle(Canvas c, Paint p) { c.drawLine(const Offset(-8, 0), const Offset(8, 0), p..strokeWidth = 2); c.drawLine(const Offset(0, -8), const Offset(0, 8), p); c.drawCircle(Offset.zero, 3, p); }
  void _drawPoints(Canvas c, Paint p) { c.drawPath(Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 16, height: 12), Radius.circular(DesignToken.radiusSM))), p); p.color = DesignToken.white.withOpacity(0.8); c.drawCircle(const Offset(-4, 0), 2, p); c.drawCircle(const Offset(4, 0), 2, p); }

  @override
  bool shouldRepaint(covariant CelebrationPainter old) => old.animationValue != animationValue;
}
