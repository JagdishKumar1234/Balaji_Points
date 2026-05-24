import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';


class OrdersManagement extends StatefulWidget {
  const OrdersManagement({super.key});

  @override
  State<OrdersManagement> createState() => _OrdersManagementState();
}

class _OrdersManagementState extends State<OrdersManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedStatusFilter = 'all'; // all, pending, processing, completed, cancelled

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('orders').orderBy('createdAt', descending: true);

    if (_selectedStatusFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }

    return query.snapshots();
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _openOrderDetails(Map<String, dynamic> order) {
    final createdAt = order['createdAt'] as Timestamp?;
    final createdDate =
        createdAt != null ? createdAt.toDate() : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);

    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final address = (order['address'] as String?) ?? '';
    final shopName = (order['shopName'] as String?) ?? '';
    final shopAddress = (order['shopAddress'] as String?) ?? '';
    final shopGstNo = (order['shopGstNo'] as String?) ?? '';
    final shopEmail = (order['shopEmail'] as String?) ?? '';
    final shopPhone = (order['shopPhone'] as String?) ?? '';
    final carpenterName = (order['carpenterName'] as String?) ?? '';
    final carpenterPhone = (order['carpenterPhone'] as String?) ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order ${order['orderId'] ?? ''}',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 18,
                            color: AppColors.lightPrimary,
                          ),
                        ),
                        const Spacer(),
                        _StatusChip(status: order['status'] as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: AppTypography.bodyMedium().copyWith(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shopName.isNotEmpty || shopAddress.isNotEmpty) ...[
                      Text(
                        shopName.isNotEmpty ? shopName : 'Shop details',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      if (shopAddress.isNotEmpty)
                        Text(
                          shopAddress,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (shopGstNo.isNotEmpty)
                        Text(
                          'GST: $shopGstNo',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (shopPhone.isNotEmpty)
                        Text(
                          'Phone: $shopPhone',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (shopEmail.isNotEmpty)
                        Text(
                          shopEmail,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (carpenterName.isNotEmpty || carpenterPhone.isNotEmpty) ...[
                      Text(
                        'Carpenter',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      if (carpenterName.isNotEmpty)
                        Text(
                          carpenterName,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      if (carpenterPhone.isNotEmpty)
                        Text(
                          carpenterPhone,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (address.isNotEmpty) ...[
                      Text(
                        'Shipping address',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      Text(
                        address,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Items',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 15,
                        color: AppColors.lightPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final name = item['name'] ?? '';
                      final qty = (item['quantity'] ?? 0) as int;
                      final price = (item['price'] ?? 0) as num;
                      final lineTotal = (item['lineTotal'] ?? 0) as num;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 14,
                                  color: AppColors.lightPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'x$qty @ ₹${price.toStringAsFixed(0)}',
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${lineTotal.toStringAsFixed(0)}',
                              style: AppTypography.labelLarge().copyWith(
                                fontSize: 14,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 16,
                            color: AppColors.lightPrimary,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 18,
                            color: AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Orders',
                  style: AppTypography.labelLarge(),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedStatusFilter == 'all',
                  onSelected: (_) {
                    setState(() => _selectedStatusFilter = 'all');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _selectedStatusFilter == 'pending',
                  onSelected: (_) {
                    setState(() => _selectedStatusFilter = 'pending');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Processing'),
                  selected: _selectedStatusFilter == 'processing',
                  onSelected: (_) {
                    setState(() => _selectedStatusFilter = 'processing');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: _selectedStatusFilter == 'completed',
                  onSelected: (_) {
                    setState(() => _selectedStatusFilter = 'completed');
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Cancelled'),
                  selected: _selectedStatusFilter == 'cancelled',
                  onSelected: (_) {
                    setState(() => _selectedStatusFilter = 'cancelled');
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ordersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading orders:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.lightPrimary),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 72,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No orders yet',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 18,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New orders will appear here as carpenters place them.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final orderId = data['orderId'] as String? ?? doc.id;
                  final status = data['status'] as String? ?? 'pending';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final createdDate =
                      createdAt != null ? createdAt.toDate() : DateTime.now();
                  final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  final carpenterName =
                      (data['carpenterName'] as String?) ?? '';
                  final carpenterPhone =
                      (data['carpenterPhone'] as String?) ?? '';

                  final dateStr =
                      DateFormat('dd MMM yyyy').format(createdDate);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Order $orderId',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTypography.labelLarge().copyWith(
                                    fontSize: 15,
                                    color: AppColors.lightPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTypography.bodyMedium().copyWith(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (carpenterName.isNotEmpty ||
                                    carpenterPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      if (carpenterName.isNotEmpty)
                                        carpenterName,
                                      if (carpenterPhone.isNotEmpty)
                                        carpenterPhone,
                                    ].join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        AppTypography.bodyMedium().copyWith(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ] else
                                  const SizedBox(height: 4),
                                Text(
                                  '₹${total.toStringAsFixed(0)}',
                                  style:
                                      AppTypography.labelLarge().copyWith(
                                    fontSize: 16,
                                    color: AppColors.lightPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                DropdownButton<String>(
                                value: status,
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'processing',
                                    child: Text('Processing'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Completed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text('Cancelled'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  _updateStatus(doc.id, value);
                                },
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                onPressed: () => _openOrderDetails(data),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _backgroundForStatus() {
    switch (status) {
      case 'completed':
        return Colors.green.withValues(alpha: 0.2);
      case 'processing':
        return Colors.orange.withValues(alpha: 0.2);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.15);
      default:
        return Colors.blueGrey.withValues(alpha: 0.15);
    }
  }

  Color _textColorForStatus() {
    switch (status) {
      case 'completed':
        return Colors.green[800]!;
      case 'processing':
        return Colors.orange[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      default:
        return Colors.blueGrey[800]!;
    }
  }

  String _labelForStatus() {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundForStatus(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _labelForStatus(),
        style: AppTypography.labelLarge().copyWith(
          fontSize: 11,
          color: _textColorForStatus(),
        ),
      ),
    );
  }
}

