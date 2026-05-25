import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Order Details', style: AppTypography.h5()),
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
                  style: AppTypography.bodyMedium(color: context.themeError),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return Center(
              child: CircularProgressIndicator(color: context.themePrimary),
            );
          }

          final data = snapshot.data!.data() ?? {};
          final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final createdAt = data['createdAt'] as Timestamp?;
          final createdDate = createdAt?.toDate() ?? DateTime.now();
          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);
          final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          final shopName = data['shopName'] as String? ?? '';
          final shopAddress = data['shopAddress'] as String? ?? '';
          final shopGstNo = data['shopGstNo'] as String? ?? '';
          final shopEmail = data['shopEmail'] as String? ?? '';
          final shopPhone = data['shopPhone'] as String? ?? '';
          final address = data['address'] as String? ?? '';
          final status = data['status'] as String? ?? 'pending';
          final carpenterName = data['carpenterName'] as String? ?? '';
          final carpenterPhone = data['carpenterPhone'] as String? ?? '';
          final orderNo = data['orderId'] as String? ?? orderId;

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(MediaQuery.of(context)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order $orderNo',
                              style: AppTypography.h4(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: AppTypography.bodySmall(
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shop block
                  if (shopName.isNotEmpty || shopAddress.isNotEmpty) ...[
                    Text(
                      shopName.isNotEmpty ? shopName : 'Shop details',
                      style: AppTypography.h5(),
                    ),
                    if (shopAddress.isNotEmpty)
                      Text(shopAddress,
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    if (shopGstNo.isNotEmpty)
                      Text('GST: $shopGstNo',
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    if (shopPhone.isNotEmpty)
                      Text('Phone: $shopPhone',
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    if (shopEmail.isNotEmpty)
                      Text(shopEmail,
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    const SizedBox(height: 16),
                  ],

                  // Carpenter block
                  if (carpenterName.isNotEmpty || carpenterPhone.isNotEmpty) ...[
                    Text('Carpenter', style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w600)),
                    if (carpenterName.isNotEmpty)
                      Text(carpenterName,
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    if (carpenterPhone.isNotEmpty)
                      Text(carpenterPhone,
                          style: AppTypography.bodySmall(
                              color: context.themeTextSecondary)),
                    const SizedBox(height: 16),
                  ],

                  // Shipping address
                  if (address.isNotEmpty) ...[
                    Text('Shipping address',
                        style: AppTypography.labelLarge()
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(address,
                        style: AppTypography.bodySmall(
                            color: context.themeTextSecondary)),
                    const SizedBox(height: 16),
                  ],

                  // Items table
                  Text('Items',
                      style: AppTypography.labelLarge()
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      children: [
                        // Header row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text('Item',
                                    style: AppTypography.labelSmall()
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Qty',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.labelSmall()
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Price',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.labelSmall()
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Total',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.labelSmall()
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        for (final item in items) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    (item['name'] ?? '') as String,
                                    style: AppTypography.bodySmall(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item['quantity'] ?? 0}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySmall(
                                        color: context.themeTextSecondary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${(item['price'] ?? 0).toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodySmall(
                                        color: context.themeTextSecondary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Builder(builder: (context) {
                                    final numPrice = (item['price'] ?? 0) as num;
                                    final numQty = (item['quantity'] ?? 0) as num;
                                    final numLine =
                                        (item['lineTotal'] as num?) ??
                                            (numPrice * numQty);
                                    return Text(
                                      '₹${numLine.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.bodySmall()
                                          .copyWith(fontWeight: FontWeight.w600),
                                    );
                                  }),
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
                      Text('Total',
                          style: AppTypography.labelLarge()
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: AppTypography.h4(color: context.themePrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async => _generateAndSharePdf(data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themeSecondary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(
                        'Download / Share PDF',
                        style: AppTypography.buttonMedium(color: AppColors.white),
                      ),
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
    final createdDate = createdAt?.toDate() ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final shopName = order['shopName'] as String? ?? '';
    final shopAddress = order['shopAddress'] as String? ?? '';
    final shopGstNo = order['shopGstNo'] as String? ?? '';
    final shopEmail = order['shopEmail'] as String? ?? '';
    final shopPhone = order['shopPhone'] as String? ?? '';
    final address = order['address'] as String? ?? '';
    final status = order['status'] as String? ?? 'pending';
    final orderNo = order['orderId'] as String? ?? '';
    final carpenterName = order['carpenterName'] as String? ?? '';
    final carpenterPhone = order['carpenterPhone'] as String? ?? '';
    final advance = (order['advanceAmount'] as num?)?.toDouble() ?? 0.0;
    final balance = (order['balanceAmount'] as num?)?.toDouble() ?? (total - advance);
    final deliveryTs = order['deliveryDate'] as Timestamp?;
    final deliveryDateStr = deliveryTs != null
        ? DateFormat('dd MMM yyyy').format(deliveryTs.toDate())
        : 'Not specified';

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/balaji_point_logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Shop header
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
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                      if (shopAddress.isNotEmpty)
                        pw.Text(shopAddress,
                            style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('Phone: $shopPhone | GSTIN: $shopGstNo',
                          style: const pw.TextStyle(fontSize: 11)),
                      if (shopEmail.isNotEmpty)
                        pw.Text(shopEmail,
                            style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Customer details
              pw.Text('CUSTOMER DETAILS',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              if (carpenterName.isNotEmpty)
                pw.Text('Name: $carpenterName',
                    style: const pw.TextStyle(fontSize: 11)),
              if (carpenterPhone.isNotEmpty)
                pw.Text('Contact: $carpenterPhone',
                    style: const pw.TextStyle(fontSize: 11)),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text('Shipping Address:',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(address, style: const pw.TextStyle(fontSize: 11)),
              ],
              pw.SizedBox(height: 12),

              // Order details
              pw.Text('ORDER DETAILS',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Order No: #$orderNo',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Date: $dateStr',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text(
                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text('ITEMS:',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...items.map((item) {
                final name = (item['name'] ?? '') as String;
                final qty = (item['quantity'] ?? 0) as int;
                final size = (item['size'] ?? item['thickness'] ?? '') as String;
                final unit = (item['unit'] as String?) ?? 'Nos';
                final nameWithSize = size.isNotEmpty ? '$name ($size)' : name;
                return pw.Text('$nameWithSize - $qty $unit',
                    style: const pw.TextStyle(fontSize: 11));
              }),
              pw.SizedBox(height: 12),

              // Payment summary
              pw.Text('PAYMENT SUMMARY',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Total Order Value: ₹ ${total.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Advance Paid: ₹ ${advance.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Balance to Pay: ₹ ${balance.toStringAsFixed(0)}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Expected Delivery Date: $deliveryDateStr',
                  style: const pw.TextStyle(fontSize: 11)),
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

// ---------------------------------------------------------------------------
// Status chip (shared with orders list)
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
