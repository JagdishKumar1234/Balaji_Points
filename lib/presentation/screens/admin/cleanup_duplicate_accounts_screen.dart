import 'package:flutter/material.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';

class CleanupDuplicateAccountsScreen extends StatefulWidget {
  const CleanupDuplicateAccountsScreen({super.key});

  @override
  State<CleanupDuplicateAccountsScreen> createState() =>
      _CleanupDuplicateAccountsScreenState();
}

class _CleanupDuplicateAccountsScreenState
    extends State<CleanupDuplicateAccountsScreen> {
  late Future<Map<String, dynamic>> _duplicatesFuture;

  @override
  void initState() {
    super.initState();
    _duplicatesFuture = _fetchDuplicates();
  }

  Future<Map<String, dynamic>> _fetchDuplicates() async {
    final db = FirebaseFirestore.instance;
    final usersSnapshot = await db.collection('users').forAdminBranch().get();

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
        users.sort(
          (a, b) => (a['createdAt'] as DateTime).compareTo(
            b['createdAt'] as DateTime,
          ),
        );
        duplicates[phone] = users;
      }
    });

    return {
      'duplicates': duplicates,
      'totalAccounts': usersSnapshot.docs.length,
      'duplicateCount': duplicates.values.fold(
        0,
        (total, list) => total + list.length,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.cleanUpDuplicates,
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _duplicatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.themePrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.error3('${snapshot.error}'),
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        borderRadius: AppRadius.md12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.duplicatesFound,
                                  style: AppTypography.labelLarge().copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.accountsAcrossPhoneNumbers(
                                    '$duplicateCount',
                                    '${duplicates.length}',
                                  ),
                                  style: AppTypography.bodySmall().copyWith(
                                    color: AppColors.error,
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
                              Icons.check_circle_rounded,
                              size: 64,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noDuplicatesFound,
                              style: AppTypography.h3(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.allCarpenterAccountsAreUnique,
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
                      AppLocalizations.of(context)!.duplicateGroups,
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

  const _DuplicateGroup({
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
        border: Border.all(color: context.themePrimary.withValues(alpha: 0.3)),
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
              AppLocalizations.of(
                context,
              )!.phoneAccounts('$groupIndex', '$phone', '${users.length}'),
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
                  margin: EdgeInsets.only(
                    bottom: idx < users.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.themeBackground,
                    border: Border.all(
                      color: isOldest
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.error.withValues(alpha: 0.5),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: AppRadius.sm8,
                            ),
                            child: Text(
                              isOldest
                                  ? AppLocalizations.of(context)!.keep
                                  : AppLocalizations.of(context)!.reviewOnly,
                              style: AppTypography.labelSmall().copyWith(
                                color: isOldest
                                    ? AppColors.success
                                    : AppColors.warning,
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
