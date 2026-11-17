import 'dart:math' as math;

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/spin/spin_prizes.dart';
import 'package:flutter/material.dart';

/// Daily Buy Daily Win wheel: one slice per prize, product pictures only
/// (no text). [angle] turns the wheel clockwise, in radians; the gold
/// pointer at the top marks the result.
class PrizeWheel extends StatelessWidget {
  const PrizeWheel({
    super.key,
    required this.angle,
    this.size = 280,
    this.prizes = spinPrizes,
  });

  final double angle;
  final double size;
  final List<SpinPrize> prizes;

  /// Wheel angle that puts slice [index] under the pointer.
  static double angleFor(int index, int count) {
    final slice = 2 * math.pi / count;
    return -(index + 0.5) * slice;
  }

  @override
  Widget build(BuildContext context) {
    final slice = 2 * math.pi / prizes.length;
    final r = size / 2;
    final imageBox = size * 0.185;
    final imageRadius = r * 0.66;

    return SizedBox(
      width: size,
      height: size + 14,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 14,
            child: SizedBox(
              width: size,
              height: size,
              child: Transform.rotate(
                angle: angle,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _WheelPainter(prizes.length)),
                    ),
                    for (var i = 0; i < prizes.length; i++)
                      Builder(
                        builder: (_) {
                          // Slice centre, measured clockwise from the top.
                          final a = (i + 0.5) * slice;
                          final dx = r + imageRadius * math.sin(a);
                          final dy = r - imageRadius * math.cos(a);
                          return Positioned(
                            left: dx - imageBox / 2,
                            top: dy - imageBox / 2,
                            width: imageBox,
                            height: imageBox,
                            child: Transform.rotate(
                              angle: a,
                              child: _PrizePicture(
                                prize: prizes[i],
                                color:
                                    AppColors.spinWheelSlices[i %
                                        AppColors.spinWheelSlices.length],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Hub with the brand star.
          Positioned(
            top: 14 + r - size * 0.11,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppColors.spinWheelBulb, AppColors.gold],
                ),
                border: Border.all(color: AppColors.spinWheelRim, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.stars_rounded,
                color: AppColors.spinWheelRim,
                size: size * 0.12,
              ),
            ),
          ),
          // Pointer.
          const Positioned(top: 0, child: _Pointer()),
        ],
      ),
    );
  }
}

class _PrizePicture extends StatelessWidget {
  const _PrizePicture({required this.prize, required this.color});
  final SpinPrize prize;

  /// The slice colour: ring around the picture.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: prize.name,
      image: true,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
        ),
        padding: const EdgeInsets.all(5),
        child: ClipOval(
          child: Image.asset(
            prize.asset,
            fit: BoxFit.contain,
            // Until the product photo is added, a matching tool icon.
            errorBuilder: (_, __, ___) =>
                FittedBox(child: Icon(prize.fallbackIcon, color: color)),
          ),
        ),
      ),
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(30, 34), painter: _PointerPainter());
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, AppColors.black, 3, false);
    canvas.drawPath(path, Paint()..color = AppColors.gold);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alternating navy and gold slices with a gold rim and rim lights.
class _WheelPainter extends CustomPainter {
  _WheelPainter(this.count);
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final slice = 2 * math.pi / count;

    // Outer rim: dark red ring with a gold edge, like a casino wheel.
    canvas.drawCircle(c, r, Paint()..color = AppColors.gold);
    canvas.drawCircle(c, r - 3, Paint()..color = AppColors.spinWheelRim);
    final inner = r - 15;
    canvas.drawCircle(c, inner + 2, Paint()..color = AppColors.gold);
    final rect = Rect.fromCircle(center: c, radius: inner);
    const colors = AppColors.spinWheelSlices;

    for (var i = 0; i < count; i++) {
      // Canvas angles start at 3 o'clock; slice 0 starts at 12 o'clock.
      final start = -math.pi / 2 + i * slice;
      final base = colors[i % colors.length];
      // Lighter at the centre, deeper at the rim.
      canvas.drawArc(
        rect,
        start,
        slice,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: [Color.lerp(base, AppColors.white, 0.35)!, base],
            stops: const [0.15, 1],
          ).createShader(rect),
      );
      canvas.drawArc(
        rect,
        start,
        slice,
        true,
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Rim bulbs: two per slice, glowing.
    for (var i = 0; i < count * 2; i++) {
      final a = -math.pi / 2 + i * slice / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * (r - 8.5);
      canvas.drawCircle(
        p,
        5.5,
        Paint()
          ..color = AppColors.spinWheelBulb.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        p,
        3.2,
        Paint()..color = i.isEven ? AppColors.spinWheelBulb : AppColors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.count != count;
}
