import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:intl/intl.dart';

class BillDuplicateDetailsPage extends StatelessWidget {
  final String billId;
  final String userId;

  const BillDuplicateDetailsPage({
    super.key,
    required this.billId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AppText.h3('Bill Details - $billId',
            color: context.themeTextPrimary),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('bills')
            .where('billId', isEqualTo: billId)
            .where('carpenterId', isEqualTo: userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.themePrimary),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  AppText.body('Error loading bill details',
                      color: AppColors.error),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      color: context.themeTextSecondary, size: 48),
                  const SizedBox(height: 16),
                  AppText.body('No bill found',
                      color: context.themeTextSecondary),
                ],
              ),
            );
          }

          final bills = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: AppRadius.all16,
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.h5('Bill Summary', color: context.themeTextPrimary),
                      const SizedBox(height: 12),
                      _SummaryRow('Bill ID', billId, context),
                      const SizedBox(height: 8),
                      _SummaryRow('Total Instances', '${bills.length}',
                          context),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bill instances
                AppText.h5('Bill Entries', color: context.themeTextPrimary),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bill =
                        bills[index].data() as Map<String, dynamic>;
                    final billDate = bill['createdAt'] as Timestamp?;
                    final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
                    final points = (bill['points'] as num?)?.toDouble() ?? 0.0;
                    final description = bill['description'] as String? ?? '';
                    final status = bill['status'] as String? ?? 'unknown';

                    final dateTime = billDate?.toDate();
                    final dateStr = dateTime != null
                        ? DateFormat('dd/MM/yyyy').format(dateTime)
                        : 'N/A';
                    final timeStr = dateTime != null
                        ? DateFormat('HH:mm:ss').format(dateTime)
                        : 'N/A';

                    return Container(
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: AppRadius.all16,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with index
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.body('Instance ${index + 1}',
                                  color: context.themeTextPrimary),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: AppRadius.sm8,
                                ),
                                child: AppText.label(
                                  status.toUpperCase(),
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Date and Time
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.themePrimary
                                  .withValues(alpha: 0.08),
                              borderRadius: AppRadius.sm8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.label('Date',
                                    color: context.themeTextSecondary),
                                const SizedBox(height: 2),
                                AppText.body(dateStr,
                                    color: context.themeTextPrimary),
                                const SizedBox(height: 8),
                                AppText.label('Time',
                                    color: context.themeTextSecondary),
                                const SizedBox(height: 2),
                                AppText.body(timeStr,
                                    color: context.themeTextPrimary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Amount and Points
                          Row(
                            children: [
                              Expanded(
                                child: _DetailCard(
                                  label: 'Amount',
                                  value: '₹${amount.toStringAsFixed(2)}',
                                  context: context,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DetailCard(
                                  label: 'Points',
                                  value: '$points',
                                  context: context,
                                  highlight: true,
                                ),
                              ),
                            ],
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            AppText.label('Description',
                                color: context.themeTextSecondary),
                            const SizedBox(height: 4),
                            AppText.body(description,
                                color: context.themeTextPrimary),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _SummaryRow(this.label, this.value, this.context);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(label, color: context.themeTextSecondary),
        AppText.body(value, color: context.themeTextPrimary),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final bool highlight;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.context,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? context.themePrimary.withValues(alpha: 0.1)
            : context.themeBackground,
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: highlight
              ? context.themePrimary.withValues(alpha: 0.3)
              : context.themeBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.label(label, color: context.themeTextSecondary),
          const SizedBox(height: 4),
          AppText.h5(value,
              color: highlight ? context.themePrimary : context.themeTextPrimary),
        ],
      ),
    );
  }
}
