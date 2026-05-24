import 'dart:math' as math;
import 'package:flutter/material.dart';

class WoodenTexture extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final double opacity;

  const WoodenTexture({
    super.key,
    required this.child,
    this.baseColor,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Wooden texture background
        CustomPaint(
          painter: _WoodenTexturePainter(
            baseColor: baseColor ?? const Color(0xFFD4A574),
            opacity: opacity,
          ),
          child: Container(),
        ),
        // Content on top
        child,
      ],
    );
  }
}

class _WoodenTexturePainter extends CustomPainter {
  final Color baseColor;
  final double opacity;

  _WoodenTexturePainter({required this.baseColor, this.opacity = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    // Base background with gradient
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.95),
        Color.lerp(baseColor, Colors.brown.shade700, 0.1)!,
      ],
    );

    final baseRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final basePaint = Paint()..shader = baseGradient.createShader(baseRect);
    canvas.drawRect(baseRect, basePaint);

    // Draw realistic wood grain with highlights and shadows
    final random = math.Random(42);

    // Draw multiple layers of grain for depth
    for (int layer = 0; layer < 3; layer++) {
      final grainSpacing = 6.0 + (layer * 2);
      final grainOpacity = opacity * (0.8 - layer * 0.2);

      for (
        double y = -grainSpacing;
        y < size.height + grainSpacing;
        y += grainSpacing
      ) {
        final variation = math.sin(y * 0.008 + layer * 0.5) * 3;
        final grainWidth = 0.8 + random.nextDouble() * 0.4;

        // Main grain line with varying intensity
        final grainPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = grainWidth
          ..color = baseColor.withOpacity(grainOpacity * 0.6);

        final path = Path();
        final startX = variation - grainSpacing;
        path.moveTo(startX, y);

        // Create natural wavy grain pattern
        for (double x = startX; x < size.width + grainSpacing; x += 8) {
          final wave = math.sin(x * 0.08 + y * 0.03 + layer) * 2;
          final wave2 = math.cos(x * 0.12 + y * 0.02) * 1;
          path.lineTo(x, y + wave + wave2);
        }

        canvas.drawPath(path, grainPaint);

        // Add highlight (lighter) lines on top of grain
        if (layer == 0 && y % (grainSpacing * 3) == 0) {
          final highlightPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5
            ..color = Colors.white.withOpacity(grainOpacity * 0.3);

          final highlightPath = Path();
          highlightPath.moveTo(variation, y - 1);
          for (double x = variation; x < size.width; x += 6) {
            final wave = math.sin(x * 0.1 + y * 0.05) * 1.5;
            highlightPath.lineTo(x, y - 1 + wave);
          }
          canvas.drawPath(highlightPath, highlightPaint);
        }

        // Add shadow (darker) lines for depth
        if (layer == 2 && y % (grainSpacing * 4) == 0) {
          final shadowPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.brown.shade800.withOpacity(grainOpacity * 0.4);

          final shadowPath = Path();
          shadowPath.moveTo(variation + 2, y + 1);
          for (double x = variation; x < size.width; x += 10) {
            final wave = math.sin(x * 0.09 + y * 0.04) * 2;
            shadowPath.lineTo(x + 2, y + 1 + wave);
          }
          canvas.drawPath(shadowPath, shadowPaint);
        }
      }
    }

    // Draw realistic wood knots/imperfections with depth
    for (int i = 0; i < 20; i++) {
      final knotX = random.nextDouble() * size.width;
      final knotY = random.nextDouble() * size.height;
      final knotRadius = 4 + random.nextDouble() * 8;

      // Knot shadow
      final shadowPaint = Paint()
        ..color = Colors.brown.shade900.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(knotX + 1, knotY + 1), knotRadius, shadowPaint);

      // Knot base
      final knotPaint = Paint()
        ..color = baseColor.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(knotX, knotY), knotRadius, knotPaint);

      // Knot center (darker)
      final centerPaint = Paint()
        ..color = Colors.brown.shade800.withOpacity(opacity * 1.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(knotX, knotY), knotRadius * 0.4, centerPaint);

      // Knot highlight (lighter edge)
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(knotX, knotY), knotRadius * 0.7, highlightPaint);
    }

    // Draw plywood layer lines (vertical divisions)
    final plankWidth = size.width / 2.5;
    for (int i = 1; i < 3; i++) {
      final x = plankWidth * i;

      // Shadow line
      final shadowLinePaint = Paint()
        ..color = Colors.brown.shade900.withOpacity(opacity * 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x + 1, 0),
        Offset(x + 1, size.height),
        shadowLinePaint,
      );

      // Main division line
      final linePaint = Paint()
        ..color = baseColor.withOpacity(opacity * 0.5)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

      // Highlight line (top edge)
      final highlightLinePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.2)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x - 0.5, 0),
        Offset(x - 0.5, size.height),
        highlightLinePaint,
      );
    }

    // Add subtle overall highlight gradient for 3D effect
    final highlightGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(opacity * 0.15),
        Colors.transparent,
        Colors.transparent,
        Colors.brown.shade900.withOpacity(opacity * 0.1),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(baseRect);
    canvas.drawRect(baseRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wooden container that applies texture to its background
class WoodenContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? baseColor;
  final double opacity;

  const WoodenContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.baseColor,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Stack(
          children: [
            // Wooden texture background
            Positioned.fill(
              child: CustomPaint(
                painter: _WoodenTexturePainter(
                  baseColor: baseColor ?? const Color(0xFFD4A574),
                  opacity: opacity,
                ),
              ),
            ),
            // Content
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}
