import 'package:balaji_points/core/design/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/providers/daily_spin_provider.dart';

class DailySpinPage extends ConsumerStatefulWidget {
  const DailySpinPage({super.key});

  @override
  ConsumerState<DailySpinPage> createState() => _DailySpinPageState();
}

class _DailySpinPageState extends ConsumerState<DailySpinPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isSpinning = false;

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

    setState(() {
      _isSpinning = true;
    });

    _controller.reset();
    _controller.forward();

    // Perform the spin and get points
    final points = await ref.read(dailySpinProvider.notifier).performSpin();

    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isSpinning = false;
    });

    // Show result dialog
    if (mounted) {
      _showResultDialog(points);
    }

    // Refresh state
    ref.read(dailySpinProvider.notifier).refresh();
  }

  void _showResultDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Congratulations!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.lightSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You won',
              style: TextStyle(fontSize: 18, color: AppColors.grey700),
            ),
            const SizedBox(height: 10),
            Text(
              '$points Points!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.lightSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Points have been added to your account.',
              style: TextStyle(fontSize: 14, color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final carpenterBg = light ? AppColors.lightBackground : theme.scaffoldBackgroundColor;
    final appBarBg = light
        ? AppColors.lightBackground
        : (theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor);

    return PopScope(
      canPop: !_isSpinning,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Check for dialogs first
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }

          if (_isSpinning) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please wait for spin to complete'),
                backgroundColor: AppColors.warning,
              ),
            );
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: carpenterBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Daily Spin'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Spin & Win Points!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Get your daily spin and win exciting points',
                    style: TextStyle(fontSize: 16, color: AppColors.grey600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Spin Wheel
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 20 * 3.14159,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF06292),
                                const Color(0xFFE91E63),
                                AppColors.lightSecondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lightSecondary
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Segments (simplified - you can make this more elaborate)
                              CustomPaint(
                                size: const Size(280, 280),
                                painter: SpinWheelPainter(),
                              ),
                              // Center circle
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.radio_button_checked,
                                  size: 40,
                                  color: AppColors.lightSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Spin Button
                  if (!spinState.isLoading)
                    ElevatedButton(
                      onPressed: spinState.canSpin && !_isSpinning
                          ? _spin
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightSecondary,
                        disabledBackgroundColor: AppColors.grey300,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isSpinning ? 'Spinning...' : 'Spin Now!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const CircularProgressIndicator(),

                  const SizedBox(height: 30),

                  // Info
                  if (!spinState.canSpin && spinState.lastSpinDate != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: const Color(0xFF1976D2)),
                          const SizedBox(width: 10),
                          Text(
                            'You\'ve already spun today!\nCome back tomorrow for another chance.',
                            style: TextStyle(
                              color: const Color(0xFF1976D2),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpinWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw 8 segments with different colors
    final segments = 8;
    final segmentAngle = (2 * 3.14159) / segments;

    final colors = [
      const Color(0xFFE57373),
      const Color(0xFFFFB74D),
      const Color(0xFFFFF176),
      const Color(0xFF81C784),
      const Color(0xFF64B5F6),
      const Color(0xFF7986CB),
      const Color(0xFFBA68C8),
      const Color(0xFFF06292),
    ];

    for (int i = 0; i < segments; i++) {
      paint.color = colors[i % colors.length];
      final startAngle = i * segmentAngle - 3.14159 / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw lines between segments
      final linePaint = Paint()
        ..color = AppColors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.9 * math.cos(i * segmentAngle - 3.14159 / 2),
          center.dy + radius * 0.9 * math.sin(i * segmentAngle - 3.14159 / 2),
        ),
        linePaint,
      );
    }

    // Draw points text on segments
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < segments; i++) {
      final angle = i * segmentAngle + segmentAngle / 2 - 3.14159 / 2;
      final points = (i + 1) * 10;
      textPainter.text = TextSpan(
        text: '$points',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final x =
          center.dx + (radius * 0.7) * math.cos(angle) - textPainter.width / 2;
      final y =
          center.dy + (radius * 0.7) * math.sin(angle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
