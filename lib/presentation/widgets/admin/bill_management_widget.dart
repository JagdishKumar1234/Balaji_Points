import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/platform/bill_service.dart';
import '../../../core/logger.dart';
import 'package:balaji_points/core/utils/bill_query_utils.dart';

class BillManagementWidget extends StatefulWidget {
  const BillManagementWidget({super.key});

  @override
  State<BillManagementWidget> createState() => _BillManagementWidgetState();
}

class _BillManagementWidgetState extends State<BillManagementWidget> {
  final BillService _billService = BillService();
  String _filterStatus = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: Column(
        children: [
          // Filter Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: context.themeBackground,
            child: Row(
              children: [
                Expanded(child: _buildFilterButton('All', 'all')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton('Pending', 'pending')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterButton('Approved', 'approved')),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'all'
                  ? FirebaseFirestore.instance.collection('bills').snapshots()
                  : FirebaseFirestore.instance
                        .collection('bills')
                        .where('status', isEqualTo: _filterStatus)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: context.themePrimary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Bills Found',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 18,
                            color: context.themePrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bills = sortBillsByCreatedAtDesc(snapshot.data!.docs);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final doc = bills[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final billId = doc.id;
                    final userId = data['carpenterId'] ?? data['userId'] ?? '';
                    final userName = data['userName'] ?? 'Unknown';
                    final phone = data['carpenterPhone'] ?? data['phone'] ?? '';
                    final amount = data['amount'] ?? 0.0;
                    final points = (data['pointsEarned'] ?? data['points'] ?? 0) is num
                        ? (data['pointsEarned'] ?? data['points'] ?? 0 as num).toDouble()
                        : 0.0;
                    final status = data['status'] ?? 'pending';
                    final billImage =
                        data['imageUrl'] ?? data['billImage'] ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final billDate = data['billDate'] as Timestamp?;
                    final storeName = data['storeName'] ?? '';
                    final billNumber = data['billNumber'] ?? '';
                    final notes = data['notes'] ?? '';

                    // compute points from amount and prepare both displays
                    final double pointsFromAmount = amount / 1000;
                    final String rupeeText = '₹${amount.toStringAsFixed(0)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: context.themePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: context.themeContentColor,
                            size: 24,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.label(userName),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AppText.label('${pointsFromAmount.toStringAsFixed(2)} pts'),
                                const SizedBox(width: 8),
                                Text(
                                  rupeeText,
                                  style: AppTypography.bodyMedium().copyWith(
                                    fontSize: 14,
                                    color: context.themePrimary.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Points: ${points.toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 13,
                              color: context.themePrimary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                        trailing: StatusChip(status: status, compact: true),
                        children: [
                          _buildDetailRow(Icons.phone, 'Phone', phone),
                          if (billDate != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Bill Date',
                              _formatDate(billDate.toDate()),
                            ),
                          ],
                          if (storeName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.store,
                              'Store/Vendor',
                              storeName,
                            ),
                          ],
                          if (billNumber.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.receipt,
                              'Bill Number',
                              billNumber,
                            ),
                          ],
                          if (createdAt != null) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.access_time,
                              'Submitted',
                              _formatDate(createdAt.toDate()),
                            ),
                          ],
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.note, 'Notes', notes),
                          ],
                          if (billImage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                billImage,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: context.themeBorder,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: context.themeTextMuted,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (status == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectBill(billId),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: context.themeError,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: AppTypography.labelLarge()
                                          .copyWith(
                                            fontSize: 14,
                                            color: context.themeError,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () => _approveBill(
                                      billId,
                                      userId,
                                      amount,
                                      points,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.themeSecondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Approve',
                                      style: AppTypography.labelLarge()
                                          .copyWith(
                                            fontSize: 14,
                                            color: AppColors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themePrimary
              : context.themePrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.themePrimary
                : context.themePrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge().copyWith(
              fontSize: 13,
              color: isSelected ? AppColors.white : context.themePrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.themePrimary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall().copyWith(
            fontSize: 13,
            color: context.themePrimary.withValues(alpha: 0.7),
          ),
        ),
        Expanded(child: AppText.label(value)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveBill(
    String billId,
    String userId,
    double amount,
    double points,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText.label('Approve Bill'),
        content: AppText.body(
          'Approve this bill of ₹${amount.toStringAsFixed(0)}?\n\n${points.toStringAsFixed(2)} points will be added to the user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Approve',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      AppLogger.debug('❌ UI (BillManagement): User cancelled approval');
      return;
    }

    AppLogger.debug('✅ UI (BillManagement): User confirmed approval');
    AppLogger.debug(
      '   Parameters: billId="$billId", userId="$userId", amount=$amount',
    );

    try {
      AppLogger.debug(
        '📞 UI (BillManagement): Calling _billService.approveBill()...',
      );
      final success = await _billService.approveBill(billId, userId, amount);
      AppLogger.debug('📥 UI (BillManagement): approveBill returned: $success');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? AppColors.success : context.themeError,
            content: Text(
              success
                  ? 'Bill approved and points added successfully'
                  : 'Failed to approve bill',
              style: const TextStyle(color: AppColors.white),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      AppLogger.debug('❌ UI (BillManagement): Exception caught');
      AppLogger.debug('   Error: $e');
      AppLogger.debug('   StackTrace: $st');
      AppLogger.error('Error approving bill', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _rejectBill(String billId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject Bill',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: context.themeError,
          ),
        ),
        content: AppText.body('Are you sure you want to reject this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: AppTypography.labelLarge().copyWith(
                color: context.themeOnError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _billService.rejectBill(billId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error rejecting bill', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }
}
