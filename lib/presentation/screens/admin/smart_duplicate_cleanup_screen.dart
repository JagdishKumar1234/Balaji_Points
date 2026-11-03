import 'package:flutter/material.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
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
        users.sort(
          (a, b) => (b['points'] as num).compareTo(a['points'] as num),
        );

        duplicateGroups.add({
          'phone': phone,
          'users': users,
          'keepUser': users[0], // Highest points
          'reviewUsers': users.skip(1).toList(),
          'reviewCount': users.length - 1,
          'pointsDifference':
              (users[0]['points'] as num) - (users[1]['points'] as num),
        });
      }
    });

    // Sort by points difference (highest first - biggest cleanup impact)
    duplicateGroups.sort(
      (a, b) => (b['pointsDifference'] as num).compareTo(
        a['pointsDifference'] as num,
      ),
    );

    return {
      'duplicateGroups': duplicateGroups,
      'totalDuplicatePhones': duplicateGroups.length,
      'totalAccountsForReview': duplicateGroups.fold(
        0,
        (subtotal, group) => subtotal + (group['reviewCount'] as int),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.smartDuplicateCleanup,
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analysisFuture,
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
          final duplicateGroups =
              data['duplicateGroups'] as List<dynamic>? ?? [];
          final totalForReview = data['totalAccountsForReview'] as int? ?? 0;

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
                              )!.allCarpentersHaveUniquePhoneNumbers,
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        borderRadius: AppRadius.md12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.potentialDuplicateAccountsReviewRequired,
                            style: AppTypography.labelLarge().copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.foundDuplicateMobileNumbers(
                              '${duplicateGroups.length}',
                            ),
                            style: AppTypography.bodyMedium(),
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.accountsToReview('$totalForReview'),
                            style: AppTypography.bodyMedium().copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.allRecordsAreRetainedTheHighest,
                            style: AppTypography.bodySmall().copyWith(
                              color: context.themeTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.potentialDuplicateGroups('${duplicateGroups.length}'),
                      style: AppTypography.h3(),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(duplicateGroups.length, (index) {
                      final group =
                          duplicateGroups[index] as Map<String, dynamic>;
                      return _DuplicateGroupCard(
                        group: group,
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

class _DuplicateGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final int groupIndex;

  const _DuplicateGroupCard({required this.group, required this.groupIndex});

  @override
  Widget build(BuildContext context) {
    final keepUser = group['keepUser'] as Map<String, dynamic>;
    final reviewUsers = group['reviewUsers'] as List<dynamic>;
    final phone = group['phone'] as String;
    final pointsDiff = group['pointsDifference'] as num;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
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
              color: AppColors.error.withValues(alpha: 0.1),
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
                      AppLocalizations.of(
                        context,
                      )!.mobile3('$groupIndex', '$phone'),
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.similarAccountsPointsDiff(
                        '${reviewUsers.length + 1}',
                        '${pointsDiff.toStringAsFixed(0)}',
                      ),
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.error,
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
                    color: AppColors.error,
                    borderRadius: AppRadius.sm8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.reviewOnly,
                    style: AppTypography.labelSmall().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggested primary account; retain every record until reviewed.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.suggestedPrimaryAccountHighestPoints,
                  style: AppTypography.labelLarge().copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                _AccountCard(user: keepUser, isKeep: true),
              ],
            ),
          ),

          // No records are deleted from this screen.
          if (reviewUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.otherMatchingAccountsManualReviewRequired,
                    style: AppTypography.labelLarge().copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(reviewUsers.length, (idx) {
                    final user = reviewUsers[idx] as Map<String, dynamic>;
                    return Column(
                      children: [
                        _AccountCard(user: user, isKeep: false),
                        if (idx < reviewUsers.length - 1)
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

  const _AccountCard({required this.user, required this.isKeep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeBackground,
        border: Border.all(
          color: isKeep
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: AppRadius.sm8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.keep,
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.success,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppRadius.sm8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.reviewOnly,
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoText(
            AppLocalizations.of(context)!.email,
            user['email'] as String,
          ),
          _InfoText(
            AppLocalizations.of(context)!.status,
            user['isActive']
                ? AppLocalizations.of(context)!.active
                : AppLocalizations.of(context)!.inactive,
            color: user['isActive'] ? AppColors.success : AppColors.warning,
          ),
          _InfoText(
            AppLocalizations.of(context)!.createdLabel,
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
