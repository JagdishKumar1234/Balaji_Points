import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_points/providers/daily_spin_provider.dart';

class DailySpinWheel extends ConsumerStatefulWidget {
  final VoidCallback? onSpinComplete;

  const DailySpinWheel({super.key, this.onSpinComplete});

  @override
  ConsumerState<DailySpinWheel> createState() => _DailySpinWheelState();
}

class _DailySpinWheelState extends ConsumerState<DailySpinWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isSpinning = false;
  double _totalRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;

    final spinState = ref.read(dailySpinProvider);
    if (!spinState.canSpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have already spun today. Come back tomorrow!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    // Wheel has 8 segments with values: [10, 20, 30, 40, 50, 60, 70, 80]
    final pointValues = [10, 20, 30, 40, 50, 60, 70, 80];
    final segments = 8;
    final segmentAngle = (2 * math.pi) / segments;

    // First, randomly select which segment to land on (this ensures valid points)
    final random = math.Random();
    final selectedSegmentIndex = random.nextInt(segments);
    final pointsWon = pointValues[selectedSegmentIndex];

    debugPrint(
      'Selected segment: index=$selectedSegmentIndex, points=$pointsWon',
    );

    // Now calculate rotation to land on this segment
    // The pointer is at top (-pi/2), segments start at -pi/2
    // We want the selected segment's center to end up at the top pointer
    final segmentCenterAngle =
        -math.pi / 2 +
        (selectedSegmentIndex * segmentAngle) +
        (segmentAngle / 2);

    // Calculate rotation needed: we want segmentCenterAngle + rotation = -pi/2 (mod 2pi)
    // So rotation = -pi/2 - segmentCenterAngle (mod 2pi)
    var targetRotation = (-math.pi / 2 - segmentCenterAngle) % (2 * math.pi);
    if (targetRotation < 0) targetRotation += 2 * math.pi;

    // Add multiple full rotations for visual effect (5-8 rotations)
    final fullRotations = 5 + random.nextDouble() * 3;
    _totalRotation = (fullRotations * 2 * math.pi) + targetRotation;

    debugPrint(
      'Rotation calculation: segmentCenterAngle=$segmentCenterAngle, targetRotation=$targetRotation, totalRotation=$_totalRotation',
    );

    _controller.reset();
    _controller.forward();

    // Perform the spin with calculated points - pass points BEFORE animation completes
    final pointsReturned = await ref
        .read(dailySpinProvider.notifier)
        .performSpin(pointsWon);

    debugPrint(
      'Points passed to provider: $pointsWon, Points returned: $pointsReturned',
    );

    // Use the points we calculated, not what provider returns (unless provider returned valid points)
    // This ensures we always show the correct points even if provider has issues
    final finalPoints = (pointsReturned > 0) ? pointsReturned : pointsWon;

    debugPrint(
      'Final points to display: $finalPoints (calculated: $pointsWon, returned: $pointsReturned)',
    );

    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isSpinning = false;
    });

    // Show result dialog with the correct points
    if (mounted) {
      _showResultDialog(finalPoints, () {
        // Callback to refresh home page data after dialog is closed
        widget.onSpinComplete?.call();
      });
    }

    // Refresh state
    ref.read(dailySpinProvider.notifier).refresh();
  }

  void _showResultDialog(int points, VoidCallback? onClose) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(
          '🎉 Congratulations!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.themeSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You won',
              style: TextStyle(fontSize: 18, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              '${points > 0 ? points : "10"} Points!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.themeSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Points have been added to your account!',
              style: TextStyle(fontSize: 14, color: context.themeTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                debugPrint('Dialog closed, calling onClose callback');
                Navigator.of(context).pop();
                if (onClose != null) {
                  debugPrint('Executing onClose callback');
                  onClose();
                } else {
                  debugPrint('WARNING: onClose callback is null!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themeSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md12,
                ),
              ),
              child: const Text('Great!', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spinState = ref.watch(dailySpinProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.all24,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.casino_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Spin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.themePrimary,
                ).merge(const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            spinState.canSpin
                ? 'Spin and win exciting points!'
                : 'Already spun today. Come back tomorrow!',
            style: TextStyle(fontSize: 14, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 24),

          // Spin Wheel
          Stack(
            alignment: Alignment.center,
            children: [
              // Wheel
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _totalRotation * _rotationAnimation.value,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CustomPaint(painter: SpinWheelPainter()),
                    ),
                  );
                },
              ),

              // Pointer/Arrow at top
              Positioned(
                top: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),

              // Center circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(color: AppColors.warning, width: 3),
                ),
                child: Icon(Icons.star, color: AppColors.warning, size: 32),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Spin Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: spinState.canSpin && !_isSpinning ? _spin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSpinning
                    ? context.themeTextSecondary
                    : (spinState.canSpin
                          ? AppColors.warning
                          : context.themeTextMuted),
                disabledBackgroundColor: context.themeBorder,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 40,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.all24,
                ),
              ),
              child: _isSpinning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Spinning...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      spinState.canSpin ? 'Spin Now! 🎰' : 'Already Spun Today',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpinWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segments = 8;
    final segmentAngle = (2 * math.pi) / segments;

    final colors = [
      AppColors.error,
      AppColors.gold,
      AppColors.warning,
      AppColors.success,
      AppColors.primary,
      AppColors.primary,
      AppColors.primary,
      AppColors.gold,
    ];

    final pointValues = [10, 20, 30, 40, 50, 60, 70, 80];

    // Draw segments
    for (int i = 0; i < segments; i++) {
      final paint = Paint()..style = PaintingStyle.fill;
      paint.color = colors[i % colors.length];

      final startAngle = i * segmentAngle - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw borders between segments
      final borderPaint = Paint()
        ..color = AppColors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.95 * math.cos(startAngle),
          center.dy + radius * 0.95 * math.sin(startAngle),
        ),
        borderPaint,
      );

      // Draw point values
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.75;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${pointValues[i]}',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.black.withValues(alpha: 0.54),
                blurRadius: 3,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Outer border
    final borderPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
