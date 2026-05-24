import 'package:balaji_points/core/design/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_points/presentation/providers/daily_spin_provider.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;

class DailySpinScanner extends ConsumerStatefulWidget {
  final VoidCallback? onSpinComplete;

  const DailySpinScanner({super.key, this.onSpinComplete});

  @override
  ConsumerState<DailySpinScanner> createState() => _DailySpinScannerState();
}

class _DailySpinScannerState extends ConsumerState<DailySpinScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _glowController;
  late Animation<double> _scanAnimation;
  late Animation<double> _glowAnimation;

  bool _isSpinning = false;
  int? _selectedPrizeIndex;

  // Prize items with icons and points
  final List<PrizeItem> _prizes = [
    PrizeItem(
      icon: Icons.local_fire_department,
      points: 10,
      color: Colors.orange,
    ),
    PrizeItem(icon: Icons.star, points: 20, color: Colors.amber),
    PrizeItem(icon: Icons.diamond, points: 30, color: Colors.cyan),
    PrizeItem(icon: Icons.emoji_events, points: 40, color: Colors.yellow),
    PrizeItem(icon: Icons.card_giftcard, points: 50, color: Colors.purple),
    PrizeItem(icon: Icons.auto_awesome, points: 60, color: Colors.pink),
    PrizeItem(icon: Icons.military_tech, points: 70, color: Colors.indigo),
    PrizeItem(
      icon: Icons.workspace_premium,
      points: 80,
      color: Colors.deepOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Scanner animation - moves up and down
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Glow animation for the selected prize
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isSpinning) return;

    final spinState = ref.read(dailySpinProvider);
    if (!spinState.canSpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already spun today. Come back tomorrow!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _selectedPrizeIndex = null;
    });

    // Randomly select a prize
    final random = math.Random();
    final selectedIndex = random.nextInt(_prizes.length);
    final selectedPrize = _prizes[selectedIndex];

    // Start the scanning animation - scan through items 3 times
    for (int cycle = 0; cycle < 3; cycle++) {
      for (int i = 0; i < _prizes.length; i++) {
        if (!mounted) return;

        setState(() {
          _selectedPrizeIndex = i;
        });

        // Speed up on last cycle
        final delay = cycle == 2 ? 200 : 150;
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    // Final selection - slow down to selected prize
    for (int i = 0; i <= selectedIndex; i++) {
      if (!mounted) return;

      setState(() {
        _selectedPrizeIndex = i;
      });

      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Start glow animation
    _glowController.repeat(reverse: true);

    // Perform the spin in Firebase
    final pointsWon = await ref
        .read(dailySpinProvider.notifier)
        .performSpin(selectedPrize.points);

    // Stop after short delay
    await Future.delayed(const Duration(milliseconds: 1500));

    _glowController.stop();

    setState(() {
      _isSpinning = false;
    });

    // Show result dialog
    if (mounted) {
      _showResultDialog(pointsWon > 0 ? pointsWon : selectedPrize.points);
    }

    // Refresh state
    ref.read(dailySpinProvider.notifier).refresh();
  }

  void _showResultDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 48,
                color: AppColors.lightSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.lightPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You won',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lightSecondary,
                    AppColors.lightSecondary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightSecondary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '$points Points!',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Points added to your account ✨',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSpinComplete?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.lightPrimary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.lightSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Prize Scan',
                style: AppTextStyles.nunitoBold.copyWith(
                  fontSize: 24,
                  color: AppColors.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            spinState.canSpin
                ? 'Tap to scan and win your daily prize!'
                : 'Come back tomorrow for another prize!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Scanner Display
          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.lightSecondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Top Scanner Line
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.lightSecondary,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Prize Items Grid
                Expanded(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prizes.length,
                    itemBuilder: (context, index) {
                      final prize = _prizes[index];
                      final isSelected = _selectedPrizeIndex == index;

                      return AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected && _isSpinning
                                  ? prize.color.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected && _isSpinning
                                    ? prize.color.withOpacity(
                                        _glowAnimation.value,
                                      )
                                    : Colors.white.withOpacity(0.1),
                                width: isSelected && _isSpinning ? 2 : 1,
                              ),
                              boxShadow: isSelected && _isSpinning
                                  ? [
                                      BoxShadow(
                                        color: prize.color.withOpacity(
                                          0.4 * _glowAnimation.value,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  prize.icon,
                                  color: isSelected && _isSpinning
                                      ? prize.color
                                      : Colors.white70,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '${prize.points} Points',
                                    style: TextStyle(
                                      color: isSelected && _isSpinning
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 18,
                                      fontWeight: isSelected && _isSpinning
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected && _isSpinning)
                                  Icon(
                                    Icons.check_circle,
                                    color: prize.color,
                                    size: 24,
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Scanner Line
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.lightSecondary,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Scan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: spinState.canSpin && !_isSpinning ? _startScan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSpinning
                    ? Colors.grey
                    : (spinState.canSpin
                          ? AppColors.lightSecondary
                          : Colors.grey.shade400),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: spinState.canSpin && !_isSpinning ? 4 : 0,
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
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Scanning...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          spinState.canSpin
                              ? 'Start Scan 🎁'
                              : 'Already Scanned Today',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrizeItem {
  final IconData icon;
  final int points;
  final Color color;

  PrizeItem({required this.icon, required this.points, required this.color});
}
