import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
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
  String _selectedStatusFilter =
      'all'; // all, pending, processing, completed, cancelled

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true);

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
    final createdDate = createdAt != null ? createdAt.toDate() : DateTime.now();
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
                        AppText.label('Order ${order['orderId'] ?? ''}'),
                        const Spacer(),
                        StatusChip(status: order['status'] as String? ?? ''),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: AppTypography.bodyMedium().copyWith(
                        fontSize: 13,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shopName.isNotEmpty || shopAddress.isNotEmpty) ...[
                      AppText.label(
                        shopName.isNotEmpty ? shopName : 'Shop details',
                      ),
                      if (shopAddress.isNotEmpty)
                        Text(
                          shopAddress,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      if (shopGstNo.isNotEmpty)
                        Text(
                          'GST: $shopGstNo',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      if (shopPhone.isNotEmpty)
                        Text(
                          'Phone: $shopPhone',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      if (shopEmail.isNotEmpty)
                        Text(
                          shopEmail,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (carpenterName.isNotEmpty ||
                        carpenterPhone.isNotEmpty) ...[
                      AppText.label('Carpenter'),
                      if (carpenterName.isNotEmpty)
                        Text(
                          carpenterName,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      if (carpenterPhone.isNotEmpty)
                        Text(
                          carpenterPhone,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    if (address.isNotEmpty) ...[
                      AppText.label('Shipping address'),
                      Text(
                        address,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppText.label('Items'),
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
                            Expanded(child: AppText.body(name)),
                            Text(
                              'x$qty @ ₹${price.toStringAsFixed(0)}',
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 13,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppText.label('₹${lineTotal.toStringAsFixed(0)}'),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.label('Total'),
                        AppText.label('₹${total.toStringAsFixed(0)}'),
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
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
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
                Text('Orders', style: AppTypography.labelLarge()),
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
                  child: AppText.body(
                    'Error loading orders:\n${snapshot.error}',
                    color: context.themeError,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.themeContentColor,
                  ),
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
                        color: context.themeBorder,
                      ),
                      const SizedBox(height: 12),
                      AppText.label('No orders yet'),
                      const SizedBox(height: 4),
                      AppText.body(
                        'New orders will appear here as carpenters place them.',
                        color: context.themeTextSecondary,
                        textAlign: TextAlign.center,
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
                  final createdDate = createdAt != null
                      ? createdAt.toDate()
                      : DateTime.now();
                  final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  final carpenterName =
                      (data['carpenterName'] as String?) ?? '';
                  final carpenterPhone =
                      (data['carpenterPhone'] as String?) ?? '';

                  final dateStr = DateFormat('dd MMM yyyy').format(createdDate);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.all16,
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
                                AppText.label(
                                  'Order $orderId',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                AppText.bodySmall(
                                  dateStr,
                                  color: context.themeTextSecondary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (carpenterName.isNotEmpty ||
                                    carpenterPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  AppText.bodySmall(
                                    [
                                      if (carpenterName.isNotEmpty)
                                        carpenterName,
                                      if (carpenterPhone.isNotEmpty)
                                        carpenterPhone,
                                    ].join(' • '),
                                    color: context.themeTextSecondary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ] else
                                  const SizedBox(height: 4),
                                AppText.label('₹${total.toStringAsFixed(0)}'),
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
                                  borderRadius: AppRadius.md12,
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
                                      color: context.themeBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.sm8,
                                    ),
                                  ),
                                  child: AppText.caption('View'),
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
