import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';

class DuplicateAccountsScreen extends StatefulWidget {
  const DuplicateAccountsScreen({super.key});

  @override
  State<DuplicateAccountsScreen> createState() => _DuplicateAccountsScreenState();
}

class _DuplicateAccountsScreenState extends State<DuplicateAccountsScreen> {
  late Future<Map<String, dynamic>> _duplicatesFuture;

  @override
  void initState() {
    super.initState();
    _duplicatesFuture = _fetchDuplicates();
  }

  Future<Map<String, dynamic>> _fetchDuplicates() async {
    final db = FirebaseFirestore.instance;
    final usersSnapshot = await db.collection('users').get();

    final phoneMap = <String, List<Map<String, dynamic>>>{};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final phone = data['phone'] ?? data['phoneNumber'] ?? '';
      final role = data['role'] ?? '';

      if (phone.isNotEmpty && (role == 'carpenter' || role.isEmpty)) {
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
        });
      }
    }

    final duplicates = <String, List<Map<String, dynamic>>>{};
    phoneMap.forEach((phone, users) {
      if (users.length > 1) {
        users.sort((a, b) => (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
        duplicates[phone] = users;
      }
    });

    return {
      'duplicates': duplicates,
      'totalAccounts': usersSnapshot.docs.length,
      'duplicateCount': duplicates.values.fold(0, (total, list) => total + list.length),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          'Duplicate Accounts',
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
        centerTitle: !isMobile,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _duplicatesFuture,
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
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTypography.bodyMedium().copyWith(
                  color: context.themeError,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final duplicates = data['duplicates'] as Map<String, dynamic>? ?? {};
          final totalAccounts = data['totalAccounts'] as int? ?? 0;
          final duplicateCount = data['duplicateCount'] as int? ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/admin/export-users'),
                        icon: const Icon(Icons.backup, size: 20),
                        label: const Text('Export Users'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/admin/cleanup-duplicates'),
                        icon: const Icon(Icons.delete_sweep, size: 20),
                        label: const Text('Clean Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        label: 'Total Accounts',
                        value: '$totalAccounts',
                        color: context.themePrimary,
                      ),
                      _StatCard(
                        label: 'Duplicate Phones',
                        value: '${duplicates.length}',
                        color: Colors.orange,
                      ),
                      _StatCard(
                        label: 'Affected Accounts',
                        value: '$duplicateCount',
                        color: Colors.red,
                      ),
                    ],
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
                              size: 48,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No duplicate accounts found!',
                              style: AppTypography.bodyLarge(),
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
                          'Duplicate Phone Numbers',
                          style: AppTypography.h3(),
                        ),
                        const SizedBox(height: 16),
                        ...duplicates.entries.mapIndexed((index, entry) {
                          final phone = entry.key;
                          final users = entry.value as List<dynamic>;

                          return _DuplicatePhoneGroup(
                            phone: phone,
                            users: users.cast<Map<String, dynamic>>(),
                            groupIndex: index + 1,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.h2().copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall().copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicatePhoneGroup extends StatelessWidget {
  final String phone;
  final List<Map<String, dynamic>> users;
  final int groupIndex;

  const _DuplicatePhoneGroup({
    required this.phone,
    required this.users,
    required this.groupIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        border: Border.all(
          color: context.themePrimary.withValues(alpha: 0.3),
        ),
        borderRadius: AppRadius.all24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.themePrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$groupIndex. Phone: $phone (${users.length} accounts)',
                  style: AppTypography.bodyLarge().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: users.asMap().entries.map((entry) {
                final idx = entry.key;
                final user = entry.value;
                final isOldest = idx == 0;

                return Container(
                  margin: EdgeInsets.only(bottom: idx < users.length - 1 ? 12 : 0),
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
                              'Account ${idx + 1}',
                              style: AppTypography.labelLarge(),
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
                              isOldest ? '⭐ Keep' : '🗑️ Review',
                              style: AppTypography.labelSmall().copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoRow('Name', user['name'] as String),
                      _InfoRow('Points', '${user['points']}'),
                      _InfoRow('Tier', user['tier'] as String),
                      _InfoRow(
                        'Created',
                        _formatDate(user['createdAt'] as DateTime),
                      ),
                      _InfoRow('ID', user['id'] as String, mono: true),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _InfoRow(this.label, this.value, {this.mono = false});

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
