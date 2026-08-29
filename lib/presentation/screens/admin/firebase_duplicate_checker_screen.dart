import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';

class FirebaseDuplicateCheckerScreen extends StatefulWidget {
  const FirebaseDuplicateCheckerScreen({super.key});

  @override
  State<FirebaseDuplicateCheckerScreen> createState() =>
      _FirebaseDuplicateCheckerScreenState();
}

class _FirebaseDuplicateCheckerScreenState
    extends State<FirebaseDuplicateCheckerScreen> {
  late Future<Map<String, dynamic>> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = _checkDuplicates();
  }

  Future<Map<String, dynamic>> _checkDuplicates() async {
    final db = FirebaseFirestore.instance;
    final usersSnapshot = await db.collection('users').get();

    final phoneMap = <String, List<Map<String, dynamic>>>{};
    int totalCarpenters = 0;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final phone = data['phone'] ?? data['phoneNumber'] ?? '';
      final role = data['role'] ?? '';

      if (phone.isNotEmpty && (role == 'carpenter' || role.isEmpty)) {
        totalCarpenters++;
        if (!phoneMap.containsKey(phone)) {
          phoneMap[phone] = [];
        }

        final createdAt = data['createdAt'] as Timestamp?;
        phoneMap[phone]!.add({
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'phone': phone,
          'points': data['totalPoints'] ?? 0,
          'createdAt': createdAt?.toDate() ?? DateTime.now(),
          'tier': data['tier'] ?? 'Bronze',
          'email': data['email'] ?? 'N/A',
          'isActive': data['isActive'] ?? true,
        });
      }
    }

    final duplicates = <String, List<Map<String, dynamic>>>{};
    phoneMap.forEach((phone, users) {
      if (users.length > 1) {
        users.sort((a, b) =>
            (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
        duplicates[phone] = users;
      }
    });

    return {
      'duplicates': duplicates,
      'totalCarpenters': totalCarpenters,
      'uniquePhones': phoneMap.length,
      'duplicatePhones': duplicates.length,
      'totalDuplicates': duplicates.values.fold(0, (sum, list) => sum + list.length),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          'Firebase Duplicate Check',
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _checkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: context.themePrimary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: AppTypography.bodyMedium().copyWith(
                    color: context.themeError,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final duplicates = data['duplicates'] as Map<String, dynamic>? ?? {};
          final totalCarpenters = data['totalCarpenters'] as int? ?? 0;
          final uniquePhones = data['uniquePhones'] as int? ?? 0;
          final duplicatePhones = data['duplicatePhones'] as int? ?? 0;
          final totalDuplicates = data['totalDuplicates'] as int? ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themePrimary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.3),
                      ),
                      borderRadius: AppRadius.md12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Firebase Database Summary',
                          style: AppTypography.labelLarge().copyWith(
                            color: context.themePrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatRow('Total Carpenters:', '$totalCarpenters'),
                        _StatRow('Unique Phone Numbers:', '$uniquePhones'),
                        _StatRow('Duplicate Phone Numbers:', '$duplicatePhones',
                            color: Colors.orange),
                        _StatRow('Total Duplicate Accounts:', '$totalDuplicates',
                            color: Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (duplicates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: context.themeSoftSurface,
                        borderRadius: AppRadius.all24,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Duplicates Found!',
                              style: AppTypography.h3(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All phone numbers are unique.',
                              style: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔍 Duplicate Mobile Numbers',
                          style: AppTypography.h3(),
                        ),
                        const SizedBox(height: 16),
                        ...duplicates.entries.mapIndexed((index, entry) {
                          final phone = entry.key;
                          final users = entry.value as List<dynamic>;

                          return _DuplicatePhoneCard(
                            phone: phone,
                            users: users.cast<Map<String, dynamic>>(),
                            groupIndex: index + 1,
                            totalGroups: duplicates.length,
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (color ?? context.themePrimary).withValues(alpha: 0.2),
              borderRadius: AppRadius.sm8,
            ),
            child: Text(
              value,
              style: AppTypography.labelLarge().copyWith(
                color: color ?? context.themePrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicatePhoneCard extends StatelessWidget {
  final String phone;
  final List<Map<String, dynamic>> users;
  final int groupIndex;
  final int totalGroups;

  const _DuplicatePhoneCard({
    required this.phone,
    required this.users,
    required this.groupIndex,
    required this.totalGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: AppRadius.all24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$groupIndex/$totalGroups - Mobile: $phone',
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${users.length} accounts with same phone number',
                      style: AppTypography.bodySmall().copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: AppRadius.sm8,
                  ),
                  child: Text(
                    '${users.length}x',
                    style: AppTypography.labelLarge().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Accounts List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: users.asMap().entries.map((entry) {
                final idx = entry.key;
                final user = entry.value;
                final isOldest = idx == 0;

                return Container(
                  margin: EdgeInsets.only(
                    bottom: idx < users.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.themeBackground,
                    border: Border.all(
                      color: isOldest
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.red.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              user['name'] as String,
                              style: AppTypography.labelLarge(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOldest ? Colors.green : Colors.red,
                              borderRadius: AppRadius.sm8,
                            ),
                            child: Text(
                              isOldest ? '⭐ Main' : '❌ Duplicate',
                              style: AppTypography.labelSmall().copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoText('Email', user['email'] as String),
                      _InfoText('Points', '${user['points']}'),
                      _InfoText('Tier', user['tier'] as String),
                      _InfoText('Status', user['isActive'] ? 'Active' : 'Inactive',
                          color: user['isActive'] ? Colors.green : Colors.orange),
                      _InfoText(
                        'Created',
                        _formatDate(user['createdAt'] as DateTime),
                      ),
                      _InfoText('ID', user['id'] as String, mono: true),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final Color? color;

  const _InfoText(this.label, this.value, {this.mono = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTypography.bodySmall().copyWith(
              color: context.themeTextMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall().copyWith(
              fontFamily: mono ? 'monospace' : null,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Iterable {
  Iterable<E> mapIndexed<E>(E Function(int, dynamic) f) =>
      toList().asMap().entries.map((e) => f(e.key, e.value));
}
