import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/services/auth/session_service.dart';

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
      foregroundColor: context.themeTextPrimary,
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
        body: const Center(child: AppLoader()),
      );
    }

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: const Center(
          child: AppText.body('Please log in to view orders.'),
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
                child: AppText.body(
                  'Error loading orders:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  color: context.themeError,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoader());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: context.themeBorder),
                  const SizedBox(height: 16),
                  const AppText.h4('No orders yet'),
                  const SizedBox(height: 8),
                  const AppText.body(
                    'Place an order from your cart to see it here.',
                    textAlign: TextAlign.center,
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: onTap,
      child: Row(
            children: [
              // Gradient left stripe
              Container(
                width: 6,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: [context.themePrimary, context.themeSecondary],
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
                                Icon(
                                  Icons.receipt_long,
                                  size: 16,
                                  color: context.themePrimary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: AppText.label(
                                    'Order $orderId',
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            AppText.bodySmall(dateStr),
                            const SizedBox(height: 6),
                            AppText.label(
                              '₹${total.toStringAsFixed(0)}',
                              color: context.themePrimary,
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
                              foregroundColor: context.themePrimary,
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
      default: return AppColors.lightTextMuted.withValues(alpha: 0.15);
    }
  }

  static Color _fg(String s) {
    switch (s) {
      case 'completed': return AppColors.success;
      case 'processing': return const Color(0xFF92400E);
      case 'cancelled': return const Color(0xFF991B1B);
      default: return AppColors.lightTextSecondary;
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
