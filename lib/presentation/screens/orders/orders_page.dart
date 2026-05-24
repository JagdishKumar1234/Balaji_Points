import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarFill =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    if (_loadingUser) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarFill,
          foregroundColor: DesignToken.textDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => context.pop(),
          ),
          title: const Text('My Orders'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: borderColor),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: DesignToken.primary),
        ),
      );
    }

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarFill,
          foregroundColor: DesignToken.textDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => context.pop(),
          ),
          title: const Text('My Orders'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: borderColor),
          ),
        ),
        body: const Center(child: Text('Please log in to view orders.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarFill,
        foregroundColor: DesignToken.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Orders'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
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
                  style: AppTextStyles.nunitoRegular.copyWith(
                    fontSize: 14,
                    color: DesignToken.error,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DesignToken.primary),
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
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: AppTextStyles.nunitoBold.copyWith(
                      fontSize: 20,
                      color: DesignToken.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place an order from your cart to see it here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.nunitoRegular.copyWith(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(
              MediaQuery.of(context),
            ),
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
                final createdDate = createdAt != null
                    ? createdAt.toDate()
                    : DateTime.now();
                final dateStr = DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(createdDate);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      context.push('/order-detail/$orderId');
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Colored stripe with icon
                          Container(
                            width: 6,
                            height: 82,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(18),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  DesignToken.primary,
                                  DesignToken.secondary,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.receipt_long,
                                              size: 16,
                                              color: DesignToken.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Order $orderId',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles
                                                    .nunitoSemiBold
                                                    .copyWith(
                                                      fontSize: 15,
                                                      color:
                                                          DesignToken.textDark,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: AppTextStyles.nunitoRegular
                                              .copyWith(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '₹${total.toStringAsFixed(0)}',
                                          style: AppTextStyles.nunitoBold
                                              .copyWith(
                                                fontSize: 16,
                                                color: DesignToken.primary,
                                              ),
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
                                        onPressed: () {
                                          context.push(
                                            '/order-detail/$orderId',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Details',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: DesignToken.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
              },
            ),
          );
        },
      ),
    );
  }

  /*
  Future<void> _openOrderDetail(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final createdAt = order['createdAt'] as Timestamp?;
    final createdDate =
        createdAt != null ? createdAt.toDate() : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final shopName = (order['shopName'] as String?) ?? '';
    final shopAddress = (order['shopAddress'] as String?) ?? '';
    final shopGstNo = (order['shopGstNo'] as String?) ?? '';
    final shopEmail = (order['shopEmail'] as String?) ?? '';
    final shopPhone = (order['shopPhone'] as String?) ?? '';
    final address = (order['address'] as String?) ?? '';
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${order['orderId'] ?? ''}',
                            style: AppTextStyles.nunitoBold.copyWith(
                              fontSize: 18,
                              color: DesignToken.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: AppTextStyles.nunitoRegular.copyWith(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (shopName.isNotEmpty || shopAddress.isNotEmpty) ...[
                            Text(
                              shopName.isNotEmpty ? shopName : 'Shop details',
                              style: AppTextStyles.nunitoSemiBold.copyWith(
                                fontSize: 14,
                                color: DesignToken.textDark,
                              ),
                            ),
                          if (shopAddress.isNotEmpty)
                              Text(
                                shopAddress,
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (shopGstNo.isNotEmpty)
                              Text(
                                'GST: $shopGstNo',
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (shopPhone.isNotEmpty)
                              Text(
                                'Phone: $shopPhone',
                                style:
                                    AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (shopEmail.isNotEmpty)
                              Text(
                                shopEmail,
                                style:
                                    AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if (carpenterName.isNotEmpty ||
                              carpenterPhone.isNotEmpty) ...[
                            Text(
                              'Carpenter',
                              style: AppTextStyles.nunitoSemiBold.copyWith(
                                fontSize: 14,
                                color: DesignToken.textDark,
                              ),
                            ),
                            if (carpenterName.isNotEmpty)
                              Text(
                                carpenterName,
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (carpenterPhone.isNotEmpty)
                              Text(
                                carpenterPhone,
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if (address.isNotEmpty) ...[
                            Text(
                              'Shipping address',
                              style: AppTextStyles.nunitoSemiBold.copyWith(
                                fontSize: 14,
                                color: DesignToken.textDark,
                              ),
                            ),
                            Text(
                              address,
                              style: AppTextStyles.nunitoRegular.copyWith(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            'Items',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 15,
                              color: DesignToken.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final name = item['name'] ?? '';
                            final qty = (item['quantity'] ?? 0) as int;
                            final price = (item['price'] ?? 0) as num;
                            final lineTotal =
                                (item['lineTotal'] ?? 0) as num? ??
                                    qty * price;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppTextStyles.nunitoRegular
                                          .copyWith(
                                        fontSize: 14,
                                        color: DesignToken.textDark,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'x$qty @ ₹${price.toStringAsFixed(0)}',
                                    style: AppTextStyles.nunitoRegular
                                        .copyWith(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${lineTotal.toStringAsFixed(0)}',
                                    style: AppTextStyles.nunitoSemiBold
                                        .copyWith(
                                      fontSize: 14,
                                      color: DesignToken.textDark,
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
                                style: AppTextStyles.nunitoSemiBold.copyWith(
                                  fontSize: 16,
                                  color: DesignToken.textDark,
                                ),
                              ),
                              Text(
                                '₹${total.toStringAsFixed(0)}',
                                style: AppTextStyles.nunitoBold.copyWith(
                                  fontSize: 18,
                                  color: DesignToken.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _generateAndSharePdf(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignToken.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download / Share PDF'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateAndSharePdf(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final createdAt = order['createdAt'] as Timestamp?;
    final createdDate =
        createdAt != null ? createdAt.toDate() : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final shopName = (order['shopName'] as String?) ?? '';
    final shopAddress = (order['shopAddress'] as String?) ?? '';
    final shopGstNo = (order['shopGstNo'] as String?) ?? '';
    final shopEmail = (order['shopEmail'] as String?) ?? '';
    final shopPhone = (order['shopPhone'] as String?) ?? '';
    final address = (order['address'] as String?) ?? '';
    final status = (order['status'] as String?) ?? 'pending';
    final orderId = order['orderId'] as String? ?? '';
    final carpenterName = (order['carpenterName'] as String?) ?? '';
    final carpenterPhone = (order['carpenterPhone'] as String?) ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (shopName.isNotEmpty)
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (shopAddress.isNotEmpty)
                pw.Text(
                  shopAddress,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (shopGstNo.isNotEmpty)
                pw.Text(
                  'GST: $shopGstNo',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (shopPhone.isNotEmpty)
                pw.Text(
                  'Phone: $shopPhone',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (shopEmail.isNotEmpty)
                pw.Text(
                  shopEmail,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Order ID: $orderId',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Date: $dateStr',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (address.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Shipping address:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          address,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
              if (carpenterName.isNotEmpty || carpenterPhone.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Carpenter details:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (carpenterName.isNotEmpty)
                  pw.Text(
                    carpenterName,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                if (carpenterPhone.isNotEmpty)
                  pw.Text(
                    carpenterPhone,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
              ],
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.6,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...items.map((item) {
                    final name = item['name'] ?? '';
                    final qty = (item['quantity'] ?? 0) as int;
                    final price = (item['price'] ?? 0) as num;
                    final lineTotal =
                        (item['lineTotal'] ?? qty * price) as num;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            name,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '$qty',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '₹${lineTotal.toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total amount',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'order_$orderId.pdf',
    );
  }
  */
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _backgroundForStatus() {
    switch (status) {
      case 'completed':
        return Colors.green.withValues(alpha: 0.15);
      case 'processing':
        return Colors.orange.withValues(alpha: 0.15);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.15);
      default:
        return Colors.blueGrey.withValues(alpha: 0.12);
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
        style: AppTextStyles.nunitoSemiBold.copyWith(
          fontSize: 11,
          color: _textColorForStatus(),
        ),
      ),
    );
  }
}
