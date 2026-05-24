import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/fcm_service.dart';
import 'package:balaji_points/services/app_startup_service.dart';
import 'package:balaji_points/services/onboarding_prefs.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    // Short branded pause, then route as soon as session is resolved (was ~3s fixed).
    unawaited(_runSplashSequence());
  }

  Future<void> _runSplashSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    final blockedByStartup = await AppStartupService().runPreLaunchChecks(
      context,
    );
    if (!mounted || blockedByStartup) return;

    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    try {
      final isLoggedIn = await _sessionService.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        // Check if app was opened from a notification
        final fcmService = FCMService();
        fcmService.processPendingNavigation();

        await Future<void>.delayed(const Duration(milliseconds: 150));

        if (!mounted) return;

        // User is logged in - check role and navigate accordingly
        final role = await _sessionService.getUserRole();

        if (!mounted) return;

        final normalizedRole = role?.trim().toLowerCase();
        if (normalizedRole == 'admin') {
          context.go('/admin');
        } else {
          context.go('/');
        }
      } else {
        final onboardingDone = await OnboardingPrefs.isCompleted();
        if (!mounted) return;
        if (onboardingDone) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      // On error, go to login (avoid trapping user on splash)
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false, // Prevent back button on splash
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_image.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        'assets/images/balaji_point_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  DesignToken.primary,
                                  DesignToken.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Icon(
                              Icons.star,
                              color: DesignToken.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.appName ?? 'Balaji Points',
                      style: AppTextStyles.nunitoBold.copyWith(
                        fontSize: 32,
                        color: DesignToken.textDark,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: DesignToken.white,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.rewardsLoyaltyProgram ??
                          'Rewards & Loyalty Program',
                      style: AppTextStyles.nunitoRegular.copyWith(
                        fontSize: 16,
                        color: DesignToken.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: DesignToken.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        '${l10n?.poweredBy ?? 'Powered by'}\n${l10n?.companyName ?? 'Shri Balaji Plywood & Hardware'}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.nunitoSemiBold.copyWith(
                          fontSize: 14,
                          color: DesignToken.primary,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: DesignToken.white,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      // Calculate animated position
      final y = (element.y + animationValue * element.speed) % 1.2 - 0.1;
      final x = element.x;
      final opacity = (y < 0 || y > 1)
          ? 0.0
          : (y < 0.1 || y > 0.9 ? (y < 0.1 ? y / 0.1 : (1.0 - y) / 0.1) : 1.0);

      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = _getColorForType(element.type)
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
        return DesignToken.white;
      case FloatingType.points:
        return DesignToken.success;
    }
  }

  void _drawCoin(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset.zero, 10, paint);
    paint.color = DesignToken.white;
    canvas.drawCircle(Offset(-3, -3), 3, paint);
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final path = Path();
    final outerRadius = 10.0;
    final innerRadius = 5.0;
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
    canvas.drawLine(Offset(-10, 0), Offset(10, 0), paint..strokeWidth = 2);
    canvas.drawLine(Offset(0, -10), Offset(0, 10), paint..strokeWidth = 2);
    canvas.drawCircle(Offset.zero, 4, paint);
  }

  void _drawPoints(Canvas canvas, Paint paint) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 18, height: 14),
        const Radius.circular(7),
      ),
    );
    canvas.drawPath(path, paint);
    paint.color = DesignToken.white;
    canvas.drawCircle(Offset(-5, 0), 2.5, paint);
    canvas.drawCircle(Offset(5, 0), 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant CelebrationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
