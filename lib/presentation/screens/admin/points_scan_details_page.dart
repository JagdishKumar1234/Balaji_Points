import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class PointsScanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> report;

  const PointsScanDetailsPage({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final totalScanned = report['totalUsersScanned'] as int? ?? 0;
    final usersWithIssues = report['usersWithIssues'] as int? ?? 0;
    final issues = (report['issues'] as Map<String, dynamic>?) ?? {};

    final sortedUsers = issues.entries.toList()
      ..sort((a, b) {
        final aDiff = (a.value as Map)['pointsDifference'] as num? ?? 0;
        final bDiff = (b.value as Map)['pointsDifference'] as num? ?? 0;
        return bDiff.compareTo(aDiff); // Descending
      });

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AppText.h3('Scan Results - Full Details',
            color: context.themeTextPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary header
            _ScanSummaryHeader(
              totalScanned: totalScanned,
              usersWithIssues: usersWithIssues,
              totalDuplicates: report['totalDuplicates'] as int? ?? 0,
              totalPointsDiff:
                  report['totalPointsDifference'] as num? ?? 0,
            ),
            const SizedBox(height: 20),

            // Users list
            AppText.h5('Users with Issues', color: context.themeTextPrimary),
            const SizedBox(height: 12),

            if (issues.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.themeSoftSurface,
                  borderRadius: AppRadius.all16,
                ),
                child: AppText.body('No users with issues found',
                    color: context.themeTextSecondary),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = sortedUsers[index];
                  final userId = entry.key;
                  final userData = entry.value as Map<String, dynamic>;

                  return _UserScanCard(
                    userId: userId,
                    totalPoints: (userData['totalPoints'] as int?) ?? 0,
                    historySum: (userData['historySum'] as num?)?.toInt() ?? 0,
                    pointsDifference:
                        (userData['pointsDifference'] as num?)?.toInt() ?? 0,
                    historyLength: (userData['historyLength'] as int?) ?? 0,
                    uniqueBills: (userData['uniqueBills'] as int?) ?? 0,
                    duplicateCount: (userData['duplicateCount'] as int?) ?? 0,
                    duplicateBillIds:
                        (userData['duplicateBillIds'] as List<dynamic>?)
                                ?.cast<String>() ??
                            [],
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Summary header
class _ScanSummaryHeader extends StatelessWidget {
  final int totalScanned;
  final int usersWithIssues;
  final int totalDuplicates;
  final num totalPointsDiff;

  const _ScanSummaryHeader({
    required this.totalScanned,
    required this.usersWithIssues,
    required this.totalDuplicates,
    required this.totalPointsDiff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.themePrimary.withValues(alpha: 0.15),
            context.themePrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: context.themePrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h5('📊 Scan Summary', color: context.themeTextPrimary),
          const SizedBox(height: 16),
          _SummaryRow('Total Users Scanned', '$totalScanned'),
          const SizedBox(height: 10),
          _SummaryRow('Users with Issues', '$usersWithIssues',
              color: usersWithIssues > 0 ? AppColors.warning : AppColors.success),
          const SizedBox(height: 10),
          _SummaryRow('Total Duplicate Entries', '$totalDuplicates',
              color: totalDuplicates > 0 ? AppColors.warning : AppColors.success),
          const SizedBox(height: 10),
          _SummaryRow('Total Points Difference', '${totalPointsDiff.toInt()}',
              color: totalPointsDiff > 0 ? AppColors.warning : AppColors.success),
        ],
      ),
    );
  }
}

// Summary row
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(label, color: context.themeTextSecondary),
        AppText.body(
          value,
          color: color ?? context.themeTextPrimary,
        ),
      ],
    );
  }
}

// User scan card - detailed info with user profile
class _UserScanCard extends StatelessWidget {
  final String userId;
  final int totalPoints;
  final int historySum;
  final int pointsDifference;
  final int historyLength;
  final int uniqueBills;
  final int duplicateCount;
  final List<String> duplicateBillIds;

  const _UserScanCard({
    required this.userId,
    required this.totalPoints,
    required this.historySum,
    required this.pointsDifference,
    required this.historyLength,
    required this.uniqueBills,
    required this.duplicateCount,
    required this.duplicateBillIds,
  });

  @override
  Widget build(BuildContext context) {
    final hasDuplicates = duplicateCount > 0;
    final pointsMismatch = (historySum - totalPoints).abs() > 0.1;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: hasDuplicates || pointsMismatch
              ? AppColors.warning.withValues(alpha: 0.3)
              : context.themeBorder,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header with profile
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get(),
            builder: (context, snapshot) {
              String displayName = 'Loading...';
              String phoneNumber = '';
              String? profileImage;
              bool isLoading = snapshot.connectionState == ConnectionState.waiting;

              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data != null) {
                final userData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                // Build full name from firstName and lastName
                final firstName = userData['firstName'] as String? ?? '';
                final lastName = userData['lastName'] as String? ?? '';
                final fullName = '$firstName $lastName'.trim();

                displayName = fullName.isEmpty ? (userData['displayName'] as String? ?? userId) : fullName;
                phoneNumber = userData['phoneNumber'] as String? ?? userData['phone'] as String? ?? '';
                profileImage = userData['profileImage'] as String?;
              } else if (snapshot.hasError) {
                displayName = userId;
              }

              return Row(
                children: [
                  // User image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasDuplicates
                            ? AppColors.warning
                            : AppColors.success,
                        width: 2,
                      ),
                      color: context.themePrimary.withValues(alpha: 0.1),
                    ),
                    child: ClipOval(
                      child: isLoading
                          ? Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      context.themePrimary),
                                ),
                              ),
                            )
                          : profileImage != null &&
                                  (profileImage.startsWith('http://') ||
                                      profileImage.startsWith('https://'))
                              ? Image.network(
                                  profileImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.person_rounded,
                                        color: context.themePrimary,
                                        size: 28),
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.person_rounded,
                                      color: context.themePrimary, size: 28),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.body(displayName,
                            color: context.themeTextPrimary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (phoneNumber.isNotEmpty)
                          AppText.bodySmall(phoneNumber,
                              color: context.themeTextSecondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                        else
                          AppText.bodySmall(userId,
                              color: context.themeTextSecondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  // Issue badge
                  if (hasDuplicates)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: AppRadius.sm8,
                      ),
                      child: AppText.label('$duplicateCount dup',
                          color: AppColors.warning),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Points comparison
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.themePrimary.withValues(alpha: 0.08),
              borderRadius: AppRadius.sm8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('totalPoints', '$totalPoints'),
                const SizedBox(height: 6),
                _DetailRow('History Sum', '$historySum'),
                const SizedBox(height: 6),
                _DetailRow(
                  'Difference',
                  '$pointsDifference',
                  highlight: pointsDifference > 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // History details
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total Entries',
                  value: '$historyLength',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Unique Bills',
                  value: '$uniqueBills',
                ),
              ),
            ],
          ),

          if (duplicateBillIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppText.label('Duplicate Bills:', color: context.themeTextSecondary),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: duplicateBillIds
                  .map((billId) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: AppRadius.sm8,
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child:
                            AppText.bodySmall(billId, color: AppColors.warning),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// Detail row
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow(
    this.label,
    this.value, {
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodySmall(label, color: context.themeTextSecondary),
        AppText.bodySmall(
          value,
          color: highlight ? AppColors.warning : context.themeTextPrimary,
        ),
      ],
    );
  }
}

// Stat tile
class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.themeBackground,
        borderRadius: AppRadius.sm8,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelSmall(label, color: context.themeTextSecondary),
          const SizedBox(height: 4),
          AppText.h5(value, color: context.themeTextPrimary),
        ],
      ),
    );
  }
}
