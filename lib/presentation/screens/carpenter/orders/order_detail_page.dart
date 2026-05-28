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
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

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
        title: const AppText.h4('Order Details'),
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
                child: AppText.body(
                  'Error loading order:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  color: context.themeError,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: AppLoader());
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
                            AppText.h4('Order $orderNo'),
                            const SizedBox(height: 4),
                            AppText.bodySmall(
                              dateStr,
                              color: context.themeTextSecondary,
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
                    AppText.h4(shopName.isNotEmpty ? shopName : 'Shop details'),
                    if (shopAddress.isNotEmpty)
                      AppText.bodySmall(shopAddress,
                          color: context.themeTextSecondary),
                    if (shopGstNo.isNotEmpty)
                      AppText.bodySmall('GST: $shopGstNo',
                          color: context.themeTextSecondary),
                    if (shopPhone.isNotEmpty)
                      AppText.bodySmall('Phone: $shopPhone',
                          color: context.themeTextSecondary),
                    if (shopEmail.isNotEmpty)
                      AppText.bodySmall(shopEmail,
                          color: context.themeTextSecondary),
                    const SizedBox(height: 16),
                  ],

                  // Carpenter block
                  if (carpenterName.isNotEmpty || carpenterPhone.isNotEmpty) ...[
                    const AppText.label('Carpenter'),
                    if (carpenterName.isNotEmpty)
                      AppText.bodySmall(carpenterName,
                          color: context.themeTextSecondary),
                    if (carpenterPhone.isNotEmpty)
                      AppText.bodySmall(carpenterPhone,
                          color: context.themeTextSecondary),
                    const SizedBox(height: 16),
                  ],

                  // Shipping address
                  if (address.isNotEmpty) ...[
                    const AppText.label('Shipping address'),
                    AppText.bodySmall(address,
                        color: context.themeTextSecondary),
                    const SizedBox(height: 16),
                  ],

                  // Items table
                  const AppText.label('Items'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 12,
                    showShadow: false,
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
                              const Expanded(
                                flex: 4,
                                child: AppText.labelSmall('Item'),
                              ),
                              const Expanded(
                                flex: 2,
                                child: AppText.labelSmall('Qty',
                                    textAlign: TextAlign.right),
                              ),
                              const Expanded(
                                flex: 2,
                                child: AppText.labelSmall('Price',
                                    textAlign: TextAlign.right),
                              ),
                              const Expanded(
                                flex: 2,
                                child: AppText.labelSmall('Total',
                                    textAlign: TextAlign.right),
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
                                  child: AppText.bodySmall(
                                    (item['name'] ?? '') as String,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: AppText.bodySmall(
                                    '${item['quantity'] ?? 0}',
                                    textAlign: TextAlign.right,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: AppText.bodySmall(
                                    '₹${(item['price'] ?? 0).toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    color: context.themeTextSecondary,
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
                                    return AppText.bodySmall(
                                      '₹${numLine.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
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
                      const AppText.label('Total'),
                      AppText.h4(
                        '₹${total.toStringAsFixed(0)}',
                        color: context.themePrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  AppButton.secondary(
                    label: 'Download / Share PDF',
                    icon: Icons.picture_as_pdf,
                    onPressed: () async => _generateAndSharePdf(data),
                    verticalPadding: 12,
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
