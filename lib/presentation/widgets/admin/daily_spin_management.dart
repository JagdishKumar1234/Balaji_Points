import 'dart:math';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'todays_eligible_carpenters.dart';

class DailySpinManagement extends StatefulWidget {
  const DailySpinManagement({super.key});

  @override
  State<DailySpinManagement> createState() => _DailySpinManagementState();
}

class _DailySpinManagementState extends State<DailySpinManagement>
    with TickerProviderStateMixin {
  bool _isSpinning = false;
  String? _winnerName;
  AnimationController? _spinAnimationController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _spinAnimation;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _spinAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _spinAnimation = Tween<double>(begin: 0, end: 8 * 3.14159).animate(
      CurvedAnimation(
        parent: _spinAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _spinAnimationController?.dispose();
    _pulseAnimationController?.dispose();
    super.dispose();
  }

  Future<bool> _canSpinToday() async {
    final recentSpins = await FirebaseFirestore.instance
        .collection('daily_prize_winners')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (recentSpins.docs.isEmpty) return true;

    final lastSpinData = recentSpins.docs.first.data();
    final lastSpinTimestamp = lastSpinData['timestamp'] as Timestamp?;
    if (lastSpinTimestamp == null) return true;

    final lastSpinTime = lastSpinTimestamp.toDate();
    final hoursSinceLastSpin = DateTime.now().difference(lastSpinTime).inHours;
    return hoursSinceLastSpin >= 24;
  }

  Future<void> _spinWheel() async {
    final canSpin = await _canSpinToday();
    if (!canSpin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Please wait 24 hours from the last spin'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSpinning = true;
      _winnerName = null;
    });

    _spinAnimationController?.reset();
    _spinAnimationController?.forward();

    try {
      // Get today's eligible carpenters (those with approved bills today)
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Query bills that were approved today
      final billsQuery = await FirebaseFirestore.instance
          .collection('bills')
          .where('status', isEqualTo: 'approved')
          .where('approvedDate', isEqualTo: todayStr)
          .get();

      if (billsQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('No carpenters with approved bills today'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _isSpinning = false);
        }
        return;
      }

      // Get unique carpenter IDs from approved bills
      final carpenterIds = <String>{};
      for (final doc in billsQuery.docs) {
        final data = doc.data();
        final carpenterId = data['carpenterId'] as String?;
        if (carpenterId != null && carpenterId.isNotEmpty) {
          carpenterIds.add(carpenterId);
        }
      }

      if (carpenterIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('No eligible carpenters found')),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _isSpinning = false);
        }
        return;
      }

      // Select random carpenter from eligible list
      final random = Random();
      final eligibleList = carpenterIds.toList();
      final randomIndex = random.nextInt(eligibleList.length);
      final selectedCarpenterId = eligibleList[randomIndex];

      final carpenterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedCarpenterId)
          .get();

      if (!carpenterDoc.exists) throw Exception('Carpenter not found');

      final carpenterData = carpenterDoc.data()!;
      final firstName = carpenterData['firstName'] ?? '';
      final lastName = carpenterData['lastName'] ?? '';
      final carpenterName = '$firstName $lastName'.trim().isEmpty
          ? 'Unknown'
          : '$firstName $lastName'.trim();
      final carpenterPhoto = carpenterData['profileImage'] ?? '';

      await Future.delayed(const Duration(seconds: 3));

      // Save winner to database
      await FirebaseFirestore.instance.collection('daily_prize_winners').add({
        'carpenterId': selectedCarpenterId,
        'carpenterName': carpenterName,
        'carpenterPhoto': carpenterPhoto,
        'date': todayStr,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also update a daily winner document for easy access on carpenter home screen
      await FirebaseFirestore.instance
          .collection('daily_winners')
          .doc(todayStr)
          .set({
            'carpenterId': selectedCarpenterId,
            'carpenterName': carpenterName,
            'carpenterPhoto': carpenterPhoto,
            'date': todayStr,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _winnerName = carpenterName;
          _isSpinning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 $carpenterName is today\'s winner!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isSpinning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.woodenBackground,
            AppColors.woodenBackground.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lightPrimary,
                    AppColors.lightPrimary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.casino,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily Spin',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  'Select a lucky winner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Spin Wheel Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildSpinSection(),
            ),
          ),

          // Today's Eligible Carpenters
          const SliverToBoxAdapter(child: TodaysEligibleCarpenters()),

          // Today's Winners
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTodaysWinners(),
            ),
          ),

          // Monthly Winners
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: _buildMonthlyWinners()),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinSection() {
    return FutureBuilder<bool>(
      future: _canSpinToday(),
      builder: (context, snapshot) {
        final canSpin = snapshot.data ?? false;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Spinning Wheel Animation
              if (_spinAnimation != null)
                AnimatedBuilder(
                  animation: _spinAnimation!,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinAnimation!.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade600,
                              Colors.red.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: _isSpinning ? 10 : 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Wheel segments
                            ...List.generate(8, (index) {
                              final angle = (index * 45) * (3.14159 / 180);
                              return Positioned.fill(
                                child: Transform.rotate(
                                  angle: angle,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: AppColors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Center
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSpinning
                                      ? const Icon(
                                          Icons.autorenew,
                                          size: 48,
                                          color: AppColors.orange,
                                        )
                                      : Icon(
                                          Icons.stars,
                                          size: 56,
                                          color: Colors.amber.shade700,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_spinAnimation == null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey500,
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),

              const SizedBox(height: 32),

              // Winner Display
              if (_winnerName != null && !_isSpinning)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade100,
                              Colors.orange.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.celebration,
                              size: 48,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Winner: $_winnerName',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              if (_winnerName == null || _isSpinning)
                const SizedBox(height: 24),

              // Status Badge
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('daily_prize_winners')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, lastSpinSnapshot) {
                  String statusText = 'No previous spins';
                  if (lastSpinSnapshot.hasData &&
                      lastSpinSnapshot.data!.docs.isNotEmpty) {
                    final lastSpinData =
                        lastSpinSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                    final lastSpinTimestamp =
                        lastSpinData['timestamp'] as Timestamp?;
                    if (lastSpinTimestamp != null) {
                      final lastSpinTime = lastSpinTimestamp.toDate();
                      final nextSpinTime = lastSpinTime.add(
                        const Duration(hours: 24),
                      );
                      final hoursRemaining = nextSpinTime
                          .difference(DateTime.now())
                          .inHours;
                      final minutesRemaining =
                          nextSpinTime.difference(DateTime.now()).inMinutes %
                          60;
                      statusText = canSpin
                          ? 'Ready to spin!'
                          : 'Next spin in: ${hoursRemaining}h ${minutesRemaining}m';
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: canSpin
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canSpin
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canSpin ? Icons.check_circle : Icons.schedule,
                          color: canSpin
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: canSpin
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Spin Button
              if (_pulseAnimation != null)
                AnimatedBuilder(
                  animation: _pulseAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: canSpin && !_isSpinning
                          ? _pulseAnimation!.value
                          : 1.0,
                      child: ElevatedButton(
                        onPressed: _isSpinning || !canSpin ? null : _spinWheel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSpin
                              ? AppColors.lightPrimary
                              : AppColors.grey500,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isSpinning ? 0 : 8,
                          shadowColor: AppColors.lightPrimary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSpinning)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.casino, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              _isSpinning ? 'Spinning...' : 'SPIN NOW',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_pulseAnimation == null)
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaysWinners() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppColors.lightSecondary, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Winners',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_prize_winners')
                .where('date', isEqualTo: todayStr)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No winners yet today',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade50, Colors.orange.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            image:
                                data['carpenterPhoto'] != null &&
                                    data['carpenterPhoto'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(data['carpenterPhoto']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              data['carpenterPhoto'] == null ||
                                  data['carpenterPhoto'].toString().isEmpty
                              ? const Icon(Icons.person, color: AppColors.grey500)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            data['carpenterName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyWinners() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayStr =
        '${firstDayOfMonth.year}-${firstDayOfMonth.month.toString().padLeft(2, '0')}-01';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: AppColors.lightSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Monthly Winners',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_prize_winners')
                .where('date', isGreaterThanOrEqualTo: firstDayStr)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No winners this month yet',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  ),
                );
              }

              final Map<String, List<Map<String, dynamic>>> groupedWinners = {};
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['date'] as String? ?? '';
                if (date.isNotEmpty) {
                  if (!groupedWinners.containsKey(date)) {
                    groupedWinners[date] = [];
                  }
                  groupedWinners[date]!.add(data);
                }
              }

              final sortedDates = groupedWinners.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return Column(
                children: sortedDates.take(5).map((date) {
                  final winners = groupedWinners[date]!;
                  final dateObj = DateTime.parse(date);
                  final formattedDate =
                      '${dateObj.day} ${_getMonthName(dateObj.month)} ${dateObj.year}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppColors.lightSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${winners.length} winner${winners.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grey500,
                        ),
                      ),
                      children: winners.map((winner) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                winner['carpenterPhoto']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? NetworkImage(winner['carpenterPhoto'])
                                : null,
                            child:
                                winner['carpenterPhoto']?.toString().isEmpty ??
                                    true
                                ? const Icon(Icons.person, color: AppColors.grey500)
                                : null,
                          ),
                          title: Text(
                            winner['carpenterName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
