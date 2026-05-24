import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarFill =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarFill,
        foregroundColor: DesignToken.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Order Details'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading order:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.nunitoRegular.copyWith(
                    fontSize: 14,
                    color: DesignToken.error,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: CircularProgressIndicator(color: DesignToken.primary),
            );
          }

          final data = snapshot.data!.data() ?? {};
          final items =
              (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final createdAt = data['createdAt'] as Timestamp?;
          final createdDate = createdAt != null
              ? createdAt.toDate()
              : DateTime.now();
          final dateStr = DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(createdDate);
          final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final shopName = (data['shopName'] as String?) ?? '';
          final shopAddress = (data['shopAddress'] as String?) ?? '';
          final shopGstNo = (data['shopGstNo'] as String?) ?? '';
          final shopEmail = (data['shopEmail'] as String?) ?? '';
          final shopPhone = (data['shopPhone'] as String?) ?? '';
          final address = (data['address'] as String?) ?? '';
          final status = (data['status'] as String?) ?? 'pending';
          final carpenterName = (data['carpenterName'] as String?) ?? '';
          final carpenterPhone = (data['carpenterPhone'] as String?) ?? '';
          final orderNo = data['orderId'] as String? ?? orderId;

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(
              MediaQuery.of(context),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Order meta + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order $orderNo',
                              style: AppTextStyles.nunitoBold.copyWith(
                                fontSize: 20,
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
                          ],
                        ),
                      ),
                      _OrderDetailStatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shop block
                  if (shopName.isNotEmpty || shopAddress.isNotEmpty) ...[
                    Text(
                      shopName.isNotEmpty ? shopName : 'Shop details',
                      style: AppTextStyles.nunitoSemiBold.copyWith(
                        fontSize: 16,
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
                        style: AppTextStyles.nunitoRegular.copyWith(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    if (shopEmail.isNotEmpty)
                      Text(
                        shopEmail,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // Carpenter block
                  if (carpenterName.isNotEmpty ||
                      carpenterPhone.isNotEmpty) ...[
                    Text(
                      'Carpenter',
                      style: AppTextStyles.nunitoSemiBold.copyWith(
                        fontSize: 15,
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
                    const SizedBox(height: 16),
                  ],

                  // Shipping address
                  if (address.isNotEmpty) ...[
                    Text(
                      'Shipping address',
                      style: AppTextStyles.nunitoSemiBold.copyWith(
                        fontSize: 15,
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
                    const SizedBox(height: 16),
                  ],

                  // Items table
                  Text(
                    'Items',
                    style: AppTextStyles.nunitoSemiBold.copyWith(
                      fontSize: 15,
                      color: DesignToken.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Item',
                                  style: AppTextStyles.nunitoSemiBold.copyWith(
                                    fontSize: 12,
                                    color: DesignToken.textDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Qty',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.nunitoSemiBold.copyWith(
                                    fontSize: 12,
                                    color: DesignToken.textDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Price',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.nunitoSemiBold.copyWith(
                                    fontSize: 12,
                                    color: DesignToken.textDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Total',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.nunitoSemiBold.copyWith(
                                    fontSize: 12,
                                    color: DesignToken.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final item in items) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    (item['name'] ?? '') as String,
                                    style: AppTextStyles.nunitoRegular.copyWith(
                                      fontSize: 12,
                                      color: DesignToken.textDark,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item['quantity'] ?? 0}',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.nunitoRegular.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${(item['price'] ?? 0).toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.nunitoRegular.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Builder(
                                    builder: (context) {
                                      final numPrice =
                                          (item['price'] ?? 0) as num;
                                      final numQty =
                                          (item['quantity'] ?? 0) as num;
                                      final numLine =
                                          (item['lineTotal'] as num?) ??
                                          (numPrice * numQty);
                                      return Text(
                                        '₹${numLine.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: AppTextStyles.nunitoSemiBold
                                            .copyWith(
                                              fontSize: 12,
                                              color: DesignToken.textDark,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _generateAndSharePdf(data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignToken.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download / Share PDF'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateAndSharePdf(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final createdAt = order['createdAt'] as Timestamp?;
    final createdDate = createdAt != null ? createdAt.toDate() : DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final shopName = (order['shopName'] as String?) ?? '';
    final shopAddress = (order['shopAddress'] as String?) ?? '';
    final shopGstNo = (order['shopGstNo'] as String?) ?? '';
    final shopEmail = (order['shopEmail'] as String?) ?? '';
    final shopPhone = (order['shopPhone'] as String?) ?? '';
    final address = (order['address'] as String?) ?? '';
    final status = (order['status'] as String?) ?? 'pending';
    final orderNo = order['orderId'] as String? ?? '';
    final carpenterName = (order['carpenterName'] as String?) ?? '';
    final carpenterPhone = (order['carpenterPhone'] as String?) ?? '';

    // Optional extended payment fields
    final advance = (order['advanceAmount'] as num?)?.toDouble() ?? 0.0;
    final balance =
        (order['balanceAmount'] as num?)?.toDouble() ?? (total - advance);
    final deliveryTs = order['deliveryDate'] as Timestamp?;
    final deliveryDateStr = deliveryTs != null
        ? DateFormat('dd MMM yyyy').format(deliveryTs.toDate())
        : 'Not specified';

    // Try to load logo from assets (if available)
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load(
        'assets/images/balaji_point_logo.png',
      );
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // If logo fails to load, continue without it.
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // === SHOP HEADER WITH LOGO ===
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(logoImage, width: 48),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (shopName.isNotEmpty)
                        pw.Text(
                          '${shopName.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (shopAddress.isNotEmpty)
                        pw.Text(
                          shopAddress,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      pw.Text(
                        '📞 Phone: $shopPhone | GSTIN: $shopGstNo',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      if (shopEmail.isNotEmpty)
                        pw.Text(
                          shopEmail,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // === CUSTOMER DETAILS ===
              pw.Text(
                '👤 CUSTOMER DETAILS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              if (carpenterName.isNotEmpty)
                pw.Text(
                  'Name: $carpenterName',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (carpenterPhone.isNotEmpty)
                pw.Text(
                  'Contact: $carpenterPhone',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  '📍 Shipping Address:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(address, style: const pw.TextStyle(fontSize: 11)),
              ],
              pw.SizedBox(height: 12),

              // === ORDER DETAILS ===
              pw.Text(
                '📝 ORDER DETAILS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Order No: #$orderNo',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Date: $dateStr',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'ITEMS:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              ...items.map((item) {
                final name = (item['name'] ?? '') as String;
                final qty = (item['quantity'] ?? 0) as int;
                final size =
                    (item['size'] ?? item['thickness'] ?? '') as String;
                final unit = (item['unit'] as String?) ?? 'Nos';
                final nameWithSize = size.isNotEmpty ? '$name ($size)' : name;
                return pw.Text(
                  '$nameWithSize - $qty $unit',
                  style: const pw.TextStyle(fontSize: 11),
                );
              }),
              pw.SizedBox(height: 12),

              // === PAYMENT SUMMARY ===
              pw.Text(
                '💰 PAYMENT SUMMARY',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total Order Value: ₹ ${total.toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Advance Paid: ₹ ${advance.toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Balance to Pay: ₹ ${balance.toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '🚚 Expected Delivery Date: $deliveryDateStr',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Thank you for your order! We will notify you once the materials are ready for dispatch.',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'order_$orderNo.pdf');
  }
}

class _OrderDetailStatusChip extends StatelessWidget {
  final String status;

  const _OrderDetailStatusChip({required this.status});

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
