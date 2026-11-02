import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:intl/intl.dart';

class DailySpinHistoryScreen extends StatefulWidget {
  const DailySpinHistoryScreen({super.key});

  @override
  State<DailySpinHistoryScreen> createState() => _DailySpinHistoryScreenState();
}

class _DailySpinHistoryScreenState extends State<DailySpinHistoryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    if (!isCurrentMonth) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AppText.title('Daily Spin History'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Month Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: AppTypography.labelLarge().copyWith(fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Calendar Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildCalendarGrid(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay = _selectedMonth;
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingDayOfWeek = firstDay.weekday;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_prize_winners')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Build spin map for the month
        final Map<int, List<Map<String, dynamic>>> spinsByDate = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] as String?;
            if (dateStr != null) {
              try {
                final date = DateTime.parse(dateStr);
                if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
                  if (!spinsByDate.containsKey(date.day)) {
                    spinsByDate[date.day] = [];
                  }
                  spinsByDate[date.day]!.add(data);
                }
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
        }

        return Column(
          children: [
            // Weekday headers
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) {
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: AppTypography.labelSmall().copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar days
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              itemBuilder: (context, index) {
                int? day;
                if (index >= startingDayOfWeek - 1 && index < startingDayOfWeek - 1 + daysInMonth) {
                  day = index - (startingDayOfWeek - 1) + 1;
                }

                if (day == null) {
                  return const SizedBox();
                }

                final hasSpin = spinsByDate.containsKey(day) && spinsByDate[day]!.isNotEmpty;
                final spinData = hasSpin ? spinsByDate[day]![0] : null;

                return _buildDayCard(context, day, hasSpin, spinData);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    int day,
    bool hasSpin,
    Map<String, dynamic>? spinData,
  ) {
    return GestureDetector(
      onTap: hasSpin ? () => _showSpinDetails(context, spinData!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: hasSpin ? context.themeSurface : context.themeSoftSurface,
          borderRadius: AppRadius.md12,
          border: Border.all(
            color: hasSpin
                ? AppColors.success.withValues(alpha: 0.4)
                : context.themeBorder,
            width: 1.5,
          ),
          boxShadow: hasSpin
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTypography.labelLarge().copyWith(
                fontSize: 16,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (hasSpin) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Spinned',
                      style: AppTypography.bodySmall().copyWith(
                        fontSize: 9,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.themeError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'No Spin',
                  style: AppTypography.bodySmall().copyWith(
                    fontSize: 9,
                    color: context.themeError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSpinDetails(BuildContext context, Map<String, dynamic> spinData) {
    final carpenterName = spinData['carpenterName'] ?? 'Unknown';
    final carpenterPhoto = spinData['carpenterPhoto'] ?? '';
    final dateStr = spinData['date'] as String?;
    final timestamp = spinData['timestamp'] as Timestamp?;

    String formattedDate = '-';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        //
      }
    }

    String formattedTime = '-';
    if (timestamp != null) {
      formattedTime = DateFormat('hh:mm a').format(timestamp.toDate());
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spin Winner',
                          style: AppTypography.labelSmall().copyWith(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 14,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formattedTime,
                      style: AppTypography.labelSmall().copyWith(
                        fontSize: 10,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Divider
              Container(
                height: 1,
                color: context.themeBorder,
              ),
              const SizedBox(height: 16),
              // Winner Info
              Row(
                children: [
                  if (carpenterPhoto.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        carpenterPhoto,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.themeBackground,
                          ),
                          child: Icon(
                            Icons.person,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.themeBackground,
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Winner Name',
                          style: AppTypography.bodySmall().copyWith(
                            color: context.themeTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          carpenterName,
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.themePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
