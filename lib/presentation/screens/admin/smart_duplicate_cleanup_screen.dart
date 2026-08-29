import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';

class SmartDuplicateCleanupScreen extends StatefulWidget {
  const SmartDuplicateCleanupScreen({super.key});

  @override
  State<SmartDuplicateCleanupScreen> createState() =>
      _SmartDuplicateCleanupScreenState();
}

class _SmartDuplicateCleanupScreenState
    extends State<SmartDuplicateCleanupScreen> {
  late Future<Map<String, dynamic>> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _analysisFuture = _analyzeAndRecommend();
  }

  Future<Map<String, dynamic>> _analyzeAndRecommend() async {
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
          'email': data['email'] ?? 'N/A',
          'isActive': data['isActive'] ?? true,
        });
      }
    }

    // Find duplicates with recommendations
    final duplicateGroups = <Map<String, dynamic>>[];

    phoneMap.forEach((phone, users) {
      if (users.length > 1) {
        // Sort by points descending to find highest
        users.sort((a, b) => (b['points'] as num).compareTo(a['points'] as num));

        duplicateGroups.add({
          'phone': phone,
          'users': users,
          'keepUser': users[0], // Highest points
          'deleteUsers': users.skip(1).toList(), // Rest to delete
          'totalToDelete': users.length - 1,
          'pointsDifference':
              (users[0]['points'] as num) - (users[1]['points'] as num),
        });
      }
    });

    // Sort by points difference (highest first - biggest cleanup impact)
    duplicateGroups.sort((a, b) =>
        (b['pointsDifference'] as num).compareTo(a['pointsDifference'] as num));

    return {
      'duplicateGroups': duplicateGroups,
      'totalDuplicatePhones': duplicateGroups.length,
      'totalAccountsToDelete': duplicateGroups.fold(0,
          (sum, group) => sum + (group['totalToDelete'] as int)),
    };
  }

  Future<void> _deleteAccount(String accountId, String accountName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(
          'Delete Account',
          style: AppTypography.h3(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete this duplicate account?',
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
          content: Text('✅ Account deleted: $accountName'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the list
      setState(() {
        _analysisFuture = _analyzeAndRecommend();
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
          'Smart Duplicate Cleanup',
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analysisFuture,
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
          final duplicateGroups =
              data['duplicateGroups'] as List<dynamic>? ?? [];
          final totalToDelete = data['totalAccountsToDelete'] as int? ?? 0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (duplicateGroups.isEmpty)
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
                              'All carpenters have unique phone numbers.',
                              style: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        borderRadius: AppRadius.md12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Smart Cleanup Recommendation',
                            style: AppTypography.labelLarge().copyWith(
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Found ${duplicateGroups.length} duplicate mobile numbers',
                            style: AppTypography.bodyMedium(),
                          ),
                          Text(
                            'Ready to delete: $totalToDelete accounts',
                            style: AppTypography.bodyMedium().copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📋 Strategy: Keep highest points account, delete lower points duplicates',
                            style: AppTypography.bodySmall().copyWith(
                              color: context.themeTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cleanup List (${duplicateGroups.length})',
                      style: AppTypography.h3(),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(duplicateGroups.length, (index) {
                      final group = duplicateGroups[index] as Map<String, dynamic>;
                      return _DuplicateGroupCard(
                        group: group,
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

class _DuplicateGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final int groupIndex;
  final Future<void> Function(String id, String name) onDelete;

  const _DuplicateGroupCard({
    required this.group,
    required this.groupIndex,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final keepUser = group['keepUser'] as Map<String, dynamic>;
    final deleteUsers = group['deleteUsers'] as List<dynamic>;
    final phone = group['phone'] as String;
    final pointsDiff = group['pointsDifference'] as num;

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
                      '$groupIndex. Mobile: $phone',
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deleteUsers.length + 1} accounts | Points diff: ${pointsDiff.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall().copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: AppRadius.sm8,
                  ),
                  child: Text(
                    'Delete ${deleteUsers.length}',
                    style: AppTypography.labelSmall().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Keep Account (Highest Points)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ KEEP - Highest Points Account',
                  style: AppTypography.labelLarge().copyWith(
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                _AccountCard(
                  user: keepUser,
                  isKeep: true,
                ),
              ],
            ),
          ),

          // Delete Accounts (Lower Points)
          if (deleteUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ DELETE - Lower Points Accounts',
                    style: AppTypography.labelLarge().copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(deleteUsers.length, (idx) {
                    final user = deleteUsers[idx] as Map<String, dynamic>;
                    return Column(
                      children: [
                        _AccountCard(
                          user: user,
                          isKeep: false,
                          onDelete: () => onDelete(
                            user['id'] as String,
                            user['name'] as String,
                          ),
                        ),
                        if (idx < deleteUsers.length - 1)
                          const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isKeep;
  final VoidCallback? onDelete;

  const _AccountCard({
    required this.user,
    required this.isKeep,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeBackground,
        border: Border.all(
          color: isKeep
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
                    const SizedBox(height: 4),
                    Text(
                      '${user['points']} points • ${user['tier']}',
                      style: AppTypography.bodySmall().copyWith(
                        color: context.themeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isKeep)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                )
              else
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoText('Email', user['email'] as String),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
