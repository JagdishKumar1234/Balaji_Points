import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import '../../../services/bill_service.dart';
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
      backgroundColor: DesignToken.woodenBackground,
      body: Column(
        children: [
          // Filter Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
                      style: AppTextStyles.nunitoRegular.copyWith(
                        color: Colors.red,
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
                          color: DesignToken.textDark.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Bills Found',
                          style: AppTextStyles.nunitoSemiBold.copyWith(
                            fontSize: 18,
                            color: DesignToken.textDark.withOpacity(0.7),
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
                    final points = data['pointsEarned'] ?? data['points'] ?? 0;
                    final status = data['status'] ?? 'pending';
                    final billImage =
                        data['imageUrl'] ?? data['billImage'] ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final billDate = data['billDate'] as Timestamp?;
                    final storeName = data['storeName'] ?? '';
                    final billNumber = data['billNumber'] ?? '';
                    final notes = data['notes'] ?? '';

                    // compute points from amount and prepare both displays
                    final int pointsFromAmount = (amount / 1000).floor();
                    final String rupeeText = '₹${amount.toStringAsFixed(0)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                            color: DesignToken.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: DesignToken.primary,
                            size: 24,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: AppTextStyles.nunitoBold.copyWith(
                                fontSize: 16,
                                color: DesignToken.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$pointsFromAmount pts',
                                  style: AppTextStyles.nunitoSemiBold.copyWith(
                                    fontSize: 18,
                                    color: DesignToken.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rupeeText,
                                  style: AppTextStyles.nunitoRegular.copyWith(
                                    fontSize: 14,
                                    color: DesignToken.textDark.withOpacity(
                                      0.6,
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
                            'Points: $points',
                            style: AppTextStyles.nunitoRegular.copyWith(
                              fontSize: 13,
                              color: DesignToken.textDark.withOpacity(0.6),
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(status).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 11,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
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
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: Colors.grey[400],
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
                                        color: Colors.red.shade300,
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
                                      style: AppTextStyles.nunitoSemiBold
                                          .copyWith(
                                            fontSize: 14,
                                            color: Colors.red.shade700,
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
                                      backgroundColor: DesignToken.secondary,
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
                                      style: AppTextStyles.nunitoBold.copyWith(
                                        fontSize: 14,
                                        color: Colors.white,
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
              ? DesignToken.primary
              : DesignToken.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? DesignToken.primary
                : DesignToken.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.nunitoSemiBold.copyWith(
              fontSize: 13,
              color: isSelected ? Colors.white : DesignToken.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignToken.textDark.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.nunitoMedium.copyWith(
            fontSize: 13,
            color: DesignToken.textDark.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.nunitoSemiBold.copyWith(
              fontSize: 13,
              color: DesignToken.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveBill(
    String billId,
    String userId,
    double amount,
    int points,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Approve Bill',
          style: AppTextStyles.nunitoBold.copyWith(
            fontSize: 20,
            color: DesignToken.primary,
          ),
        ),
        content: Text(
          'Approve this bill of ₹${amount.toStringAsFixed(0)}?\n\n$points points will be added to the user.',
          style: AppTextStyles.nunitoRegular.copyWith(
            fontSize: 16,
            color: DesignToken.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.nunitoSemiBold.copyWith(
                color: DesignToken.textDark,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignToken.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Approve',
              style: AppTextStyles.nunitoBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('❌ UI (BillManagement): User cancelled approval');
      return;
    }

    print('✅ UI (BillManagement): User confirmed approval');
    print('   Parameters: billId="$billId", userId="$userId", amount=$amount');

    try {
      print('📞 UI (BillManagement): Calling _billService.approveBill()...');
      final success = await _billService.approveBill(billId, userId, amount);
      print('📥 UI (BillManagement): approveBill returned: $success');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? Colors.green : Colors.red,
            content: Text(
              success
                  ? 'Bill approved and points added successfully'
                  : 'Failed to approve bill',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      print('❌ UI (BillManagement): Exception caught');
      print('   Error: $e');
      print('   StackTrace: $st');
      AppLogger.error('Error approving bill', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
          style: AppTextStyles.nunitoBold.copyWith(
            fontSize: 20,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          'Are you sure you want to reject this bill?',
          style: AppTextStyles.nunitoRegular.copyWith(
            fontSize: 16,
            color: DesignToken.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.nunitoSemiBold.copyWith(
                color: DesignToken.textDark,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: AppTextStyles.nunitoBold.copyWith(color: Colors.white),
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
          const SnackBar(
            content: Text('Bill rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error rejecting bill', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
