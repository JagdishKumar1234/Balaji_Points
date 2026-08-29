import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';

class CleanupDuplicateAccountsScreen extends StatefulWidget {
  const CleanupDuplicateAccountsScreen({super.key});

  @override
  State<CleanupDuplicateAccountsScreen> createState() => _CleanupDuplicateAccountsScreenState();
}

class _CleanupDuplicateAccountsScreenState extends State<CleanupDuplicateAccountsScreen> {
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

  Future<void> _deleteAccount(String accountId, String accountName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(
          'Delete Duplicate Account',
          style: AppTypography.h3(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this duplicate account?',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: AppRadius.md12,
              ),
              child: Text(
                'Account: $accountName\nID: $accountId',
                style: AppTypography.bodySmall().copyWith(
                  color: Colors.red[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ This action cannot be undone!',
              style: AppTypography.labelSmall().copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: context.themeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: context.themePrimary,
          ),
        ),
      );

      await FirebaseFirestore.instance.collection('users').doc(accountId).delete();

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Duplicate account deleted: $accountName'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the list
      setState(() {
        _duplicatesFuture = _fetchDuplicates();
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          'Clean Up Duplicates',
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
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
          final duplicateCount = data['duplicateCount'] as int? ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (duplicates.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        borderRadius: AppRadius.md12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duplicates Found',
                                  style: AppTypography.labelLarge().copyWith(
                                    color: Colors.red[700],
                                  ),
                                ),
                                Text(
                                  '$duplicateCount accounts across ${duplicates.length} phone numbers',
                                  style: AppTypography.bodySmall().copyWith(
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
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
                              'All carpenter accounts are unique.',
                              style: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (duplicates.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Duplicate Groups',
                      style: AppTypography.h3(),
                    ),
                    const SizedBox(height: 12),
                    ...duplicates.entries.mapIndexed((index, entry) {
                      final phone = entry.key;
                      final users = entry.value as List<dynamic>;

                      return _DuplicateGroup(
                        phone: phone,
                        users: users.cast<Map<String, dynamic>>(),
                        groupIndex: index + 1,
                        onDelete: _deleteAccount,
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DuplicateGroup extends StatelessWidget {
  final String phone;
  final List<Map<String, dynamic>> users;
  final int groupIndex;
  final Future<void> Function(String id, String name) onDelete;

  const _DuplicateGroup({
    required this.phone,
    required this.users,
    required this.groupIndex,
    required this.onDelete,
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
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Text(
              '$groupIndex. Phone: $phone (${users.length} accounts)',
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] as String,
                                  style: AppTypography.labelLarge(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${user['points']} pts • ${user['tier']}',
                                  style: AppTypography.bodySmall().copyWith(
                                    color: context.themeTextMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isOldest)
                            ElevatedButton.icon(
                              onPressed: () => onDelete(
                                user['id'] as String,
                                user['name'] as String,
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: AppRadius.sm8,
                              ),
                              child: Text(
                                '⭐ Keep',
                                style: AppTypography.labelSmall().copyWith(
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                        ],
                      ),
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
}

extension on Iterable {
  Iterable<E> mapIndexed<E>(E Function(int, dynamic) f) =>
      toList().asMap().entries.map((e) => f(e.key, e.value));
}
