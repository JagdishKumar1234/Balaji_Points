import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/services/session_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final SessionService _sessionService = SessionService();
  String? _userId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await _sessionService.getUserId();
    if (!mounted) return;
    setState(() {
      _userId = id;
      _loadingUser = false;
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        onPressed: () => context.pop(),
      ),
      title: Text('My Orders', style: AppTypography.h5()),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: borderColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingUser) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lightPrimary),
        ),
      );
    }

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Please log in to view orders.',
            style: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading orders:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.error),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightPrimary),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTypography.h4()),
                  const SizedBox(height: 8),
                  Text(
                    'Place an order from your cart to see it here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(MediaQuery.of(context)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final orderId = data['orderId'] as String? ?? doc.id;
                final status = data['status'] as String? ?? 'pending';
                final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                final createdAt = data['createdAt'] as Timestamp?;
                final createdDate = createdAt?.toDate() ?? DateTime.now();
                final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);

                return _OrderCard(
                  orderId: orderId,
                  status: status,
                  total: total,
                  dateStr: dateStr,
                  onTap: () => context.push('/order-detail/$orderId'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order card
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final double total;
  final String dateStr;
  final VoidCallback onTap;

  const _OrderCard({
    required this.orderId,
    required this.status,
    required this.total,
    required this.dateStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: AppColors.grey200, width: 0.8),
          ),
          child: Row(
            children: [
              // Gradient left stripe
              Container(
                width: 6,
                height: 82,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 16,
                                  color: AppColors.lightPrimary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Order $orderId',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelLarge(
                                      color: AppColors.lightTextPrimary,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: AppTypography.bodySmall(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: AppTypography.labelLarge(
                                color: AppColors.lightPrimary,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatusChip(status: status),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            label: const Text('Details', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.lightPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static Color _bg(String s) {
    switch (s) {
      case 'completed': return AppColors.success.withValues(alpha: 0.15);
      case 'processing': return AppColors.warning.withValues(alpha: 0.15);
      case 'cancelled': return AppColors.error.withValues(alpha: 0.15);
      default: return AppColors.grey400.withValues(alpha: 0.15);
    }
  }

  static Color _fg(String s) {
    switch (s) {
      case 'completed': return const Color(0xFF166534);
      case 'processing': return const Color(0xFF92400E);
      case 'cancelled': return const Color(0xFF991B1B);
      default: return AppColors.grey700;
    }
  }

  static String _label(String s) {
    switch (s) {
      case 'completed': return 'Completed';
      case 'processing': return 'Processing';
      case 'cancelled': return 'Cancelled';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(status),
        style: AppTypography.labelSmall(color: _fg(status))
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
