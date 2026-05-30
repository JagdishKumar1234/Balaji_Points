import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/bill_details_page.dart';
import 'package:balaji_points/core/utils/bill_query_utils.dart';
import 'package:intl/intl.dart';

/// Bill History Widget - Shows all approved bills with filters
/// Displays bill images, carpenter info, dates, and amounts
class BillHistoryList extends StatefulWidget {
  const BillHistoryList({super.key});

  @override
  State<BillHistoryList> createState() => _BillHistoryListState();
}

class _BillHistoryListState extends State<BillHistoryList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _expanded = {};
  final Map<String, Map<String, dynamic>?> _carpenterCache = {};

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _carpenterNameController =
      TextEditingController();
  String _carpenterNameFilter = '';
  String _selectedStatus = 'approved'; // approved, rejected, all
  bool _showFilters = false;

  /// Latest filtered bills (by status + date) for PDF export.
  List<QueryDocumentSnapshot> _billsForExport = [];
  bool _isExporting = false;

  @override
  void dispose() {
    _carpenterNameController.dispose();
    super.dispose();
  }

  // ---------------- IMAGE VIEWER ----------------
  void _viewBillImage(String imageUrl) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.black.withValues(alpha: 0.87),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error,
                              color: context.themeError,
                              size: 60,
                            ),
                            AppText.body(
                              l10n.failedToLoadImage,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: context.themeTextSecondary,
                          ),
                          Text(
                            l10n.noImageAvailable,
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
              ),
            ),
            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FETCH CARPENTER DATA ----------------
  Future<Map<String, dynamic>?> _fetchCarpenterData(String carpenterId) async {
    if (_carpenterCache.containsKey(carpenterId)) {
      return _carpenterCache[carpenterId];
    }

    try {
      final doc = await _firestore.collection('users').doc(carpenterId).get();

      if (doc.exists) {
        final data = doc.data();
        _carpenterCache[carpenterId] = data;
        return data;
      }

      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: carpenterId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        _carpenterCache[carpenterId] = data;
        return data;
      }

      _carpenterCache[carpenterId] = null;
      return null;
    } catch (e) {
      AppLogger.debug('Error fetching carpenter data: $e');
      _carpenterCache[carpenterId] = null;
      return null;
    }
  }

  // ---------------- DATE PICKERS ----------------
  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // ---------------- FILTERS ----------------
  List<QueryDocumentSnapshot> _filterBills(List<QueryDocumentSnapshot> bills) {
    return bills.where((doc) {
      final bill = doc.data() as Map<String, dynamic>;
      final status = bill['status'] as String?;
      final billDate = bill['billDate'] as Timestamp?;
      final approvedAt = bill['approvedAt'] as Timestamp?;
      final rejectedAt = bill['rejectedAt'] as Timestamp?;
      final createdAt = bill['createdAt'] as Timestamp?;

      // Filter by status first
      if (_selectedStatus != 'all') {
        if (status != _selectedStatus) return false;
      } else {
        // For 'all', only show approved or rejected bills (not pending)
        if (status != 'approved' && status != 'rejected') return false;
      }

      // Use billDate if available, otherwise approvedAt/rejectedAt, otherwise createdAt
      final dateToFilter =
          billDate?.toDate() ??
          approvedAt?.toDate() ??
          rejectedAt?.toDate() ??
          createdAt?.toDate();

      if (dateToFilter == null) return false;

      // Apply date range filter
      if (_startDate != null) {
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        if (dateToFilter.isBefore(start)) return false;
      }

      if (_endDate != null) {
        final end = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        if (dateToFilter.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        _carpenterNameFilter.isNotEmpty;
  }

  /// Export current filtered bills to PDF (Excel-style sheet with main title).
  Future<void> _exportBillsToPdf() async {
    if (_isExporting || _billsForExport.isEmpty) {
      if (_billsForExport.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No bills to export. Apply filters or wait for data.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preparing PDF...')));
    }

    try {
      // Build rows: resolve carpenter names and apply carpenter name filter
      final rows = <Map<String, dynamic>>[];
      for (final doc in _billsForExport) {
        final bill = doc.data() as Map<String, dynamic>;
        final carpenterId = bill['carpenterId'] ?? '';
        final carpenterData = await _fetchCarpenterData(carpenterId);
        String carpenterName = '—';
        if (carpenterData != null) {
          final first = carpenterData['firstName'] ?? '';
          final last = carpenterData['lastName'] ?? '';
          carpenterName = ('$first $last').trim();
          if (carpenterName.isEmpty) carpenterName = '—';
        }
        if (_carpenterNameFilter.isNotEmpty &&
            !carpenterName.toLowerCase().contains(_carpenterNameFilter)) {
          continue;
        }
        final billId = doc.id;
        final amount = (bill['amount'] ?? 0) as num;
        final amountDouble = amount.toDouble();
        final points =
            (bill['pointsEarned'] ?? (amountDouble / 1000).floor()) as num;
        final status = (bill['status'] ?? '') as String;
        final phone = (bill['carpenterPhone'] ?? '') as String;
        final billDate = bill['billDate'] as Timestamp?;
        final approvedAt = bill['approvedAt'] as Timestamp?;
        final createdAt = bill['createdAt'] as Timestamp?;
        final dateToShow =
            billDate?.toDate() ?? approvedAt?.toDate() ?? createdAt?.toDate();
        final dateStr = dateToShow != null
            ? DateFormat('dd-MMM-yyyy').format(dateToShow)
            : '—';
        rows.add({
          'sno': rows.length + 1,
          'billId': billId,
          'date': dateStr,
          'carpenterName': carpenterName,
          'phone': phone,
          'amount': amountDouble,
          'points': points.toInt(),
          'status': status == 'approved' ? 'Approved' : 'Rejected',
        });
      }

      if (rows.isEmpty) {
        if (mounted) {
          setState(() => _isExporting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No bills match current filters for export.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load(AppConstants.logoPath);
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}

      final periodStr = (_startDate != null || _endDate != null)
          ? 'Period: ${_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : '—'} to ${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : '—'}'
          : 'All time';
      final generatedStr =
          'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.SizedBox.shrink(),
          footer: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Bill History Report • ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            // Main title and branding
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(logoImage, width: 44, height: 44),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill History Report',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        AppConstants.appName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppConstants.shopAddressShort,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        periodStr,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        generatedStr,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 12),
            // Excel-style table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.8),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(2.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.3),
                6: const pw.FlexColumnWidth(1.2),
                7: const pw.FlexColumnWidth(1.2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _pdfCell('S.No', bold: true),
                    _pdfCell('Bill ID', bold: true),
                    _pdfCell('Date', bold: true),
                    _pdfCell('Carpenter Name', bold: true),
                    _pdfCell('Phone', bold: true),
                    _pdfCell('Amount (₹)', bold: true),
                    _pdfCell('Points', bold: true),
                    _pdfCell('Status', bold: true),
                  ],
                ),
                ...rows.map(
                  (r) => pw.TableRow(
                    children: [
                      _pdfCell('${r['sno']}'),
                      _pdfCell('${r['billId']}', small: true),
                      _pdfCell('${r['date']}'),
                      _pdfCell('${r['carpenterName']}'),
                      _pdfCell('${r['phone']}'),
                      _pdfCell(
                        '₹${(r['amount'] as double).toStringAsFixed(0)}',
                      ),
                      _pdfCell('${r['points']}'),
                      _pdfCell('${r['status']}'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total bills: ${rows.length}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      if (mounted) {
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'bill_history_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: context.themeError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _pdfCell(String text, {bool bold = false, bool small = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: small ? 8 : 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Compact Filter Bar with iOS style
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.themeBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top row: Status chips and filter toggle
              Row(
                children: [
                  // Compact status chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCompactStatusChip(
                            'approved',
                            'Approved',
                            AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          _buildCompactStatusChip(
                            'rejected',
                            'Rejected',
                            context.themeError,
                          ),
                          const SizedBox(width: 6),
                          _buildCompactStatusChip(
                            'all',
                            'All',
                            context.themePrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Export to PDF
                  Container(
                    decoration: BoxDecoration(
                      color: (_billsForExport.isEmpty || _isExporting)
                          ? context.themeTextSecondary.withValues(alpha: 0.1)
                          : context.themePrimary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.sm8,
                    ),
                    child: IconButton(
                      icon: _isExporting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.themeContentColor,
                              ),
                            )
                          : Icon(
                              Icons.picture_as_pdf,
                              color: _billsForExport.isEmpty
                                  ? context.themeTextSecondary
                                  : context.themePrimary,
                              size: 22,
                            ),
                      onPressed: _isExporting ? null : _exportBillsToPdf,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: 'Export all bills to PDF',
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Filter toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? context.themePrimary.withValues(alpha: 0.1)
                          : context.themeTextSecondary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.sm8,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list
                            : Icons.filter_list_outlined,
                        color: _showFilters
                            ? context.themePrimary
                            : context.themeTextSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _showFilters = !_showFilters),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: 'Filters',
                    ),
                  ),
                ],
              ),

              // Collapsible advanced filters
              if (_showFilters) ...[
                const SizedBox(height: 8),
                // Compact date range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: AppRadius.sm8,
                            border: Border.all(
                              color: _startDate != null
                                  ? context.themePrimary.withValues(alpha: 0.4)
                                  : context.themeTextSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: _startDate != null
                                    ? context.themePrimary
                                    : context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('dd MMM').format(_startDate!)
                                      : 'From',
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                    color: _startDate != null
                                        ? context.themePrimary
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                              if (_startDate != null)
                                InkWell(
                                  onTap: () =>
                                      setState(() => _startDate = null),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: AppRadius.sm8,
                            border: Border.all(
                              color: _endDate != null
                                  ? context.themePrimary.withValues(alpha: 0.4)
                                  : context.themeTextSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                size: 14,
                                color: _endDate != null
                                    ? context.themePrimary
                                    : context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd MMM').format(_endDate!)
                                      : 'To',
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                    color: _endDate != null
                                        ? context.themePrimary
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                              if (_endDate != null)
                                InkWell(
                                  onTap: () => setState(() => _endDate = null),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Compact search
                TextField(
                  controller: _carpenterNameController,
                  onChanged: (value) => setState(
                    () => _carpenterNameFilter = value.toLowerCase(),
                  ),
                  style: AppTypography.bodyMedium().copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search carpenter...',
                    hintStyle: AppTypography.bodyMedium().copyWith(
                      color: context.themeTextSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.themeTextSecondary,
                      size: 18,
                    ),
                    suffixIcon: _carpenterNameFilter.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: context.themeTextSecondary,
                            ),
                            onPressed: () {
                              _carpenterNameController.clear();
                              setState(() => _carpenterNameFilter = '');
                            },
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    filled: true,
                    fillColor: context.themeSoftSurface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.sm8,
                      borderSide: BorderSide(
                        color: context.themeTextSecondary.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.sm8,
                      borderSide: BorderSide(
                        color: context.themeTextSecondary.withValues(
                          alpha: 0.2,
                        ),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.sm8,
                      borderSide: BorderSide(
                        color: context.themePrimary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bills List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('bills')
                .where('status', whereIn: ['approved', 'rejected'])
                .snapshots(),
            builder: (_, snap) {
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: context.themeError,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading bills',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snap.error.toString(),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snap.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.themeContentColor,
                  ),
                );
              }

              var bills = sortBillsByCreatedAtDesc(snap.data!.docs);
              bills = _filterBills(bills);
              _billsForExport = bills;

              if (bills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: context.themeTextMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasActiveFilters()
                            ? 'No bills found matching filters'
                            : 'No bills found',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bills.length,
                itemBuilder: (_, i) {
                  final bill = bills[i].data() as Map<String, dynamic>;
                  bill['billId'] = bills[i].id;

                  final billId = bill['billId'];
                  final isExpanded = _expanded[billId] ?? false;
                  final carpenterId = bill['carpenterId'] ?? '';
                  final amount = bill['amount'] ?? 0;
                  final phone = bill['carpenterPhone'] ?? '';
                  final imageUrl = bill['imageUrl'] ?? '';
                  final status = bill['status'] ?? '';
                  final billDate = bill['billDate'] as Timestamp?;
                  final approvedAt = bill['approvedAt'] as Timestamp?;
                  final createdAt = bill['createdAt'] as Timestamp?;

                  // Extract points earned (for approved bills)
                  final points =
                      bill['pointsEarned'] ?? (amount / 1000).floor();

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchCarpenterData(carpenterId),
                    builder: (context, carpenterSnapshot) {
                      String carpenterName = 'Carpenter';
                      String? profileImageUrl;

                      if (carpenterSnapshot.hasData &&
                          carpenterSnapshot.data != null) {
                        final carpenterData = carpenterSnapshot.data!;
                        final firstName = carpenterData['firstName'] ?? '';
                        final lastName = carpenterData['lastName'] ?? '';
                        carpenterName = ('$firstName $lastName').trim();
                        if (carpenterName.isEmpty) carpenterName = 'Carpenter';
                        profileImageUrl =
                            carpenterData['profileImage'] as String?;
                      }

                      // Apply carpenter name filter
                      if (_carpenterNameFilter.isNotEmpty) {
                        final fullName = carpenterName.toLowerCase();
                        if (!fullName.contains(_carpenterNameFilter)) {
                          return const SizedBox.shrink();
                        }
                      }

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        shadowColor: status == 'approved'
                            ? AppColors.success.withValues(alpha: 0.3)
                            : context.themeError.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.all16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.all16,
                            color: context.themeSurface,
                            border: Border.all(
                              color: status == 'approved'
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : context.themeError.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: AppRadius.all16,
                            onTap: () async {
                              // Navigate to Bill Details page
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BillDetailsPage(
                                    billId: billId,
                                    initialBillData: bill,
                                  ),
                                ),
                              );

                              // Refresh if needed
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Redesigned compact layout
                                  Row(
                                    children: [
                                      // Profile Image
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: context.themeContentColor
                                              .withValues(alpha: 0.1),
                                          border: Border.all(
                                            color: context.themeContentColor
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child:
                                            profileImageUrl != null &&
                                                profileImageUrl.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  profileImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Icon(
                                                        Icons.person,
                                                        color:
                                                            AppColors.primary,
                                                        size: 20,
                                                      ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                color:
                                                    context.themeContentColor,
                                                size: 20,
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Name, Phone & Status
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    carpenterName,
                                                    style:
                                                        AppTypography.labelLarge()
                                                            .copyWith(
                                                              fontSize: 14,
                                                              color: AppColors
                                                                  .primary,
                                                              height: 1.2,
                                                            ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Status Badge - Inline
                                                StatusChip(
                                                  status: status,
                                                  compact: true,
                                                  showIcon: true,
                                                ),
                                              ],
                                            ),
                                            if (phone.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                phone,
                                                style: AppTypography.bodyMedium()
                                                    .copyWith(
                                                      fontSize: 11,
                                                      color: context
                                                          .themeTextSecondary,
                                                      height: 1.2,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Right Side: Image Thumbnail, Amount & Points
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Image Thumbnail
                                          if (imageUrl.isNotEmpty) ...[
                                            GestureDetector(
                                              onTap: () =>
                                                  _viewBillImage(imageUrl),
                                              child: Container(
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  borderRadius: AppRadius.sm8,
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: AppRadius.sm8,
                                                  child: Stack(
                                                    children: [
                                                      Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        width: 45,
                                                        height: 45,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              color: context
                                                                  .themeBorder,
                                                              child: Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 18,
                                                                color: context
                                                                    .themeTextSecondary,
                                                              ),
                                                            ),
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              AppColors.black
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              AppColors
                                                                  .transparent,
                                                            ],
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.zoom_in,
                                                            color:
                                                                AppColors.white,
                                                            size: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          // Amount & Points in vertical stack
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Amount
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.15),
                                                  borderRadius: AppRadius.sm8,
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '₹${amount.toStringAsFixed(0)}',
                                                  style:
                                                      AppTypography.labelLarge()
                                                          .copyWith(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .success,
                                                            height: 1,
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              // Points
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context
                                                      .themeContentColor
                                                      .withValues(alpha: 0.15),
                                                  borderRadius: AppRadius.sm8,
                                                  border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.stars,
                                                      size: 10,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '$points',
                                                      style:
                                                          AppTypography.labelLarge()
                                                              .copyWith(
                                                                fontSize: 11,
                                                                color: AppColors
                                                                    .primary,
                                                                height: 1,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Date Information - Compact
                                  Row(
                                    children: [
                                      if (billDate != null) ...[
                                        Icon(
                                          Icons.receipt_long,
                                          size: 12,
                                          color: context.themeContentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText.caption(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(billDate.toDate()),
                                          color: context.themeContentColor,
                                        ),
                                        if (approvedAt != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: context.themeTextMuted,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ],
                                      if (approvedAt != null) ...[
                                        Icon(
                                          status == 'approved'
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 12,
                                          color: status == 'approved'
                                              ? AppColors.success
                                              : context.themeError,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText.caption(
                                          DateFormat(
                                            'dd MMM, hh:mm a',
                                          ).format(approvedAt.toDate()),
                                          color: status == 'approved'
                                              ? AppColors.success
                                              : context.themeError,
                                        ),
                                      ],
                                      if (billDate == null &&
                                          approvedAt == null &&
                                          createdAt != null) ...[
                                        Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: context.themeTextSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText.caption(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(createdAt.toDate()),
                                          color: context.themeTextSecondary,
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Expanded: Show larger image
                                  if (isExpanded && imageUrl.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => _viewBillImage(imageUrl),
                                      child: ClipRRect(
                                        borderRadius: AppRadius.sm8,
                                        child: Image.network(
                                          imageUrl,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                height: 200,
                                                color: context.themeBorder,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: context
                                                            .themeTextMuted,
                                                        size: 40,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      AppText.caption(
                                                        l10n.failedToLoadImage,
                                                        color: context
                                                            .themeTextSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: AppRadius.sm8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: AppRadius.sm8,
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 11,
            color: isSelected ? AppColors.white : color,
          ),
        ),
      ),
    );
  }
}
