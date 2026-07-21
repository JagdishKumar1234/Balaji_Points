import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/bill_details_page.dart';
import 'package:balaji_points/core/utils/bill_query_utils.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:intl/intl.dart';

class PendingBillsList extends StatefulWidget {
  const PendingBillsList({super.key});

  @override
  State<PendingBillsList> createState() => _PendingBillsListState();
}

class _PendingBillsListState extends State<PendingBillsList> {
  final BillService _billService = BillService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, bool> _expanded = {};
  final Map<String, Map<String, dynamic>?> _carpenterCache = {};

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _carpenterNameController =
      TextEditingController();
  final TextEditingController _billNumberController =
      TextEditingController();
  String _carpenterNameFilter = '';
  String _billNumberFilter = '';
  bool _showFilters = false;

  // DataTable sort state
  String _sortColumn = 'billNumber'; // column to sort by
  bool _sortAscending = false; // sort direction

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

            // close
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

  // ---------------- APPROVE HANDLER ----------------
  Future<void> _approveBill(Map<String, dynamic> bill) async {
    AppLogger.debug('🎯 UI: _approveBill called');
    AppLogger.debug('   Bill data: $bill');

    final billId = bill['billId'];
    final carpenterId = bill['carpenterId'];
    final amount = (bill['amount'] ?? 0).toDouble();

    AppLogger.debug(
      '   Extracted: billId="$billId", carpenterId="$carpenterId", amount=$amount',
    );

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText.label('Approve Bill'),
        content: AppText.body(
          'Approve this bill of ₹${amount.toStringAsFixed(0)}?\n\n${(amount / 1000).toStringAsFixed(2)} points will be added to the carpenter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Approve',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      AppLogger.debug('❌ UI: User cancelled approval');
      return;
    }

    AppLogger.debug('✅ UI: User confirmed approval, calling approveBill...');
    _showLoadingDialog();

    try {
      AppLogger.debug('📞 UI: Calling _billService.approveBill()...');
      AppLogger.debug(
        '   Parameters: billId="$billId", carpenterId="$carpenterId", amount=$amount',
      );

      final success = await _billService.approveBill(
        billId,
        carpenterId,
        amount,
      );

      AppLogger.debug('📥 UI: approveBill returned: $success');
      Navigator.pop(context); // close loading

      if (!mounted) {
        AppLogger.debug('⚠️ UI: Widget not mounted, skipping snackbar');
        return;
      }

      AppLogger.debug('📢 UI: Showing snackbar (success: $success)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.success : context.themeError,
          content: Text(
            success
                ? 'Bill approved and points added successfully'
                : 'Failed to approve bill',
            style: const TextStyle(color: AppColors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, st) {
      AppLogger.debug('❌ UI: Exception caught in _approveBill');
      AppLogger.debug('   Error: $e');
      AppLogger.debug('   StackTrace: $st');
      Navigator.pop(context); // close loading
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.themeError,
          content: Text(
            'Error approving bill: ${e.toString()}',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
  }

  // ---------------- REJECT HANDLER ----------------
  Future<void> _rejectBill(String billId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject Bill',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: context.themeError,
          ),
        ),
        content: AppText.body('Are you sure you want to reject this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: AppTypography.labelLarge().copyWith(
                color: context.themeOnError,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog();

    try {
      final success = await _billService.rejectBill(billId);

      Navigator.pop(context); // close loading

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.warning : context.themeError,
          content: Text(
            success ? 'Bill rejected successfully' : 'Failed to reject bill',
            style: const TextStyle(color: AppColors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.themeError,
          content: Text(
            'Error rejecting bill: ${e.toString()}',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    }
  }

  // ---------------- LOADING POPUP ----------------
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: context.themeContentColor),
      ),
    );
  }

  // ---------------- FETCH CARPENTER DATA ----------------
  Future<Map<String, dynamic>?> _fetchCarpenterData(String carpenterId) async {
    // Check cache first
    if (_carpenterCache.containsKey(carpenterId)) {
      return _carpenterCache[carpenterId];
    }

    try {
      // Try to get by document ID first (phone number as doc ID)
      final doc = await _firestore.collection('users').doc(carpenterId).get();

      if (doc.exists) {
        final data = doc.data();
        _carpenterCache[carpenterId] = data;
        return data;
      }

      // If not found by doc ID, try querying by phone field
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

  // Fetch all bills for a carpenter with summary info
  Future<Map<String, dynamic>> _fetchCarpenterBillsSummary(String carpenterId) async {
    try {
      final bills = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .orderBy('createdAt', descending: true)
          .get();

      double totalPoints = 0;
      int totalBills = 0;
      int approvedBills = 0;
      int pendingBills = 0;
      int rejectedBills = 0;
      final Map<String, double> pointsBySite = {};
      final List<Map<String, dynamic>> billsList = [];

      for (final billDoc in bills.docs) {
        final billData = billDoc.data();
        final amount = (billData['amount'] as num?)?.toDouble() ?? 0.0;
        final status = billData['status'] as String? ?? 'pending';
        final siteName = (billData['siteName'] as String?)?.trim();
        final billDate = billData['billDate'] as Timestamp?;
        final createdAt = billData['createdAt'] as Timestamp?;
        final billNumber = billData['billNumber'] as String? ?? '';
        final points = amount / 1000;

        totalBills++;
        totalPoints += points;

        if (status == 'approved') {
          approvedBills++;
        } else if (status == 'pending') {
          pendingBills++;
        } else if (status == 'rejected') {
          rejectedBills++;
        }

        // Only add to points by site if site is not empty
        if (siteName != null && siteName.isNotEmpty) {
          pointsBySite[siteName] = (pointsBySite[siteName] ?? 0) + points;
        }

        billsList.add({
          'billNumber': billNumber,
          'siteName': siteName ?? '', // Empty string if no site
          'amount': amount,
          'points': points,
          'status': status,
          'billDate': billDate,
          'createdAt': createdAt,
          'billId': billDoc.id,
        });
      }

      return {
        'totalPoints': totalPoints,
        'totalBills': totalBills,
        'approvedBills': approvedBills,
        'pendingBills': pendingBills,
        'rejectedBills': rejectedBills,
        'pointsBySite': pointsBySite,
        'billsList': billsList,
        'allSites': pointsBySite.keys.toList(),
      };
    } catch (e) {
      AppLogger.debug('Error fetching carpenter bills summary: $e');
      return {
        'totalPoints': 0,
        'totalBills': 0,
        'approvedBills': 0,
        'pendingBills': 0,
        'rejectedBills': 0,
        'pointsBySite': {},
        'billsList': [],
        'allSites': [],
      };
    }
  }

  // Filter bills by site and date
  // ---------------- DATE PICKER ----------------
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
              surface: context.themeSurface,
              onSurface: context.themeTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, reset end date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
              surface: context.themeSurface,
              onSurface: context.themeTextPrimary,
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

  // ---------------- CLEAR FILTERS ----------------
  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _carpenterNameController.clear();
      _carpenterNameFilter = '';
      _billNumberController.clear();
      _billNumberFilter = '';
    });
  }

  // ---------------- HELPER: CHECK IF FILTERS ARE ACTIVE ----------------
  bool _hasActiveFilters() {
    return _carpenterNameFilter.isNotEmpty ||
        _billNumberFilter.isNotEmpty ||
        _startDate != null ||
        _endDate != null;
  }

  @override
  void dispose() {
    _carpenterNameController.dispose();
    _billNumberController.dispose();
    super.dispose();
  }

  // ---------------- FILTER BILLS ----------------
  List<QueryDocumentSnapshot> _filterBills(List<QueryDocumentSnapshot> bills) {
    return bills.where((billDoc) {
      final bill = billDoc.data() as Map<String, dynamic>;

      // Bill number filter
      if (_billNumberFilter.isNotEmpty) {
        final billNumber = (bill['billNumber'] as String? ?? '').toUpperCase();
        if (!billNumber.contains(_billNumberFilter.toUpperCase())) {
          return false;
        }
      }

      // Date range filter
      if (_startDate != null || _endDate != null) {
        final billDate = bill['billDate'] as Timestamp?;
        final createdAt = bill['createdAt'] as Timestamp?;

        // Use billDate if available, otherwise use createdAt
        final dateToCheck = billDate ?? createdAt;
        if (dateToCheck == null) return false;

        final billDateTime = dateToCheck.toDate();
        final billDateOnly = DateTime(
          billDateTime.year,
          billDateTime.month,
          billDateTime.day,
        );

        // Check start date
        if (_startDate != null) {
          final startDateOnly = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          if (billDateOnly.isBefore(startDateOnly)) {
            return false;
          }
        }

        // Check end date
        if (_endDate != null) {
          final endDateOnly = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          if (billDateOnly.isAfter(endDateOnly)) {
            return false;
          }
        }
      }

      // Carpenter name filter (will be applied after fetching carpenter data)
      return true;
    }).toList();
  }

  // ---------------- DESKTOP DATA TABLE VIEW ----------------
  Widget _buildDesktopDataTable(List<QueryDocumentSnapshot> bills) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _sortColumnIndex(),
          sortAscending: _sortAscending,
          headingRowColor: WidgetStatePropertyAll(
            context.themeSurface.withValues(alpha: 0.5),
          ),
          columns: [
            DataColumn(
              label: Text(
                'Bill #',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
              onSort: (index, ascending) {
                setState(() {
                  _sortColumn = 'billNumber';
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: Text(
                'Carpenter',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
              onSort: (index, ascending) {
                setState(() {
                  _sortColumn = 'carpenter';
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: Text(
                'Amount (₹)',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
              numeric: true,
              onSort: (index, ascending) {
                setState(() {
                  _sortColumn = 'amount';
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: Text(
                'Points',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
              numeric: true,
              onSort: (index, ascending) {
                setState(() {
                  _sortColumn = 'points';
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: Text(
                'Date',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
              onSort: (index, ascending) {
                setState(() {
                  _sortColumn = 'date';
                  _sortAscending = ascending;
                });
              },
            ),
            DataColumn(
              label: Text(
                'Status',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: AppTypography.labelSmall()
                    .copyWith(color: context.themePrimary),
              ),
            ),
          ],
          rows: _buildDataTableRows(bills),
        ),
      ),
    );
  }

  int _sortColumnIndex() {
    switch (_sortColumn) {
      case 'billNumber':
        return 0;
      case 'carpenter':
        return 1;
      case 'amount':
        return 2;
      case 'points':
        return 3;
      case 'date':
        return 4;
      default:
        return 0;
    }
  }

  List<DataRow> _buildDataTableRows(List<QueryDocumentSnapshot> bills) {
    return bills.map((billDoc) {
      final bill = billDoc.data() as Map<String, dynamic>;
      final billId = billDoc.id;
      final amount = (bill['amount'] ?? 0).toDouble();
      final points = amount / 1000;
      final status = bill['status'] ?? 'pending';
      final billDate = bill['billDate'] as Timestamp?;
      final createdAt = bill['createdAt'] as Timestamp?;
      final displayDate = billDate?.toDate() ?? createdAt?.toDate();
      final dateStr = displayDate != null
          ? DateFormat('dd MMM yyyy').format(displayDate)
          : 'N/A';
      final carpenterId = bill['carpenterId'] ?? '';

      Color statusColor = context.themeTextSecondary;
      String statusLabel = 'N/A';
      if (status == 'approved') {
        statusColor = AppColors.success;
        statusLabel = 'Approved';
      } else if (status == 'pending') {
        statusColor = context.themeError;
        statusLabel = 'Pending';
      } else if (status == 'rejected') {
        statusColor = context.themeError.withValues(alpha: 0.6);
        statusLabel = 'Rejected';
      }

      return DataRow(
        cells: [
          DataCell(
            Text(
              bill['billNumber'] ?? 'N/A',
              style: AppTypography.bodySmall(),
            ),
          ),
          DataCell(
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchCarpenterData(carpenterId),
              builder: (context, snap) {
                String carpenterName = 'Carpenter';
                if (snap.hasData && snap.data != null) {
                  final first = snap.data!['firstName'] ?? '';
                  final last = snap.data!['lastName'] ?? '';
                  carpenterName = '$first $last'.trim();
                  if (carpenterName.isEmpty) carpenterName = 'Carpenter';
                }
                return Text(
                  carpenterName,
                  style: AppTypography.bodySmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          DataCell(
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: AppTypography.bodySmall(),
            ),
          ),
          DataCell(
            Text(
              points.toStringAsFixed(2),
              style: AppTypography.bodySmall(),
            ),
          ),
          DataCell(
            Text(
              dateStr,
              style: AppTypography.bodySmall(),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: AppTypography.labelSmall().copyWith(
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.visibility,
                    size: 16,
                    color: context.themePrimary,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BillDetailsPage(
                          billId: billId,
                          initialBillData: bill,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  tooltip: 'View Details',
                ),
                if (status == 'pending') ...[
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    onPressed: () => _approveBill(bill),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel,
                      size: 16,
                      color: context.themeError,
                    ),
                    onPressed: () => _rejectBill(billId),
                    tooltip: 'Reject',
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Compact iOS-style Filter Bar
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
              // Search bar with filter toggle
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.themeTextSecondary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.themeTextSecondary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.themePrimary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Filter toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? context.themePrimary.withValues(alpha: 0.1)
                          : context.themeTextSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list
                            : Icons.filter_list_outlined,
                        color: _showFilters
                            ? context.themeContentColor
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
                      tooltip: 'Date Filters',
                    ),
                  ),
                ],
              ),

              // Collapsible date filters
              if (_showFilters) ...[
                const SizedBox(height: 6),
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
                            borderRadius: BorderRadius.circular(8),
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
                                    ? context.themeContentColor
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
                                        ? context.themeContentColor
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
                            borderRadius: BorderRadius.circular(8),
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
                                    ? context.themeContentColor
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
                                        ? context.themeContentColor
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
                    if (_hasActiveFilters())
                      IconButton(
                        icon: Icon(
                          Icons.clear_all,
                          size: 18,
                          color: context.themeContentColor,
                        ),
                        onPressed: _clearFilters,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Clear Filters',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Bills List
        Expanded(
          child: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('bills')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text(l10n.errorLoadingBills));
                  }

                  if (!snap.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.themeContentColor,
                      ),
                    );
                  }

                  var bills = sortBillsByCreatedAtDesc(snap.data!.docs);

                  // Apply date filter
                  bills = _filterBills(bills);

                  if (bills.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 64,
                            color: context.themeTextMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasActiveFilters()
                                ? 'No bills found matching filters'
                                : l10n.noPendingBills,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 16,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show DataTable on desktop, ListView on mobile
                  if (context.isDesktop) {
                    return _buildDesktopDataTable(bills);
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
                      final phone = bill['carpenterPhone'] ?? "";
                      final imageUrl = bill['imageUrl'] ?? "";
                      final createdAt = bill['createdAt'] as Timestamp?;
                      final billDate = bill['billDate'] as Timestamp?;
                      final approvedAt = bill['approvedAt'] as Timestamp?;

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchCarpenterData(carpenterId),
                        builder: (context, carpenterSnapshot) {
                          // Get carpenter name and profile image
                          String carpenterName = "Carpenter";
                          String? profileImageUrl;

                          if (carpenterSnapshot.hasData &&
                              carpenterSnapshot.data != null) {
                            final carpenterData = carpenterSnapshot.data!;
                            final firstName = carpenterData['firstName'] ?? '';
                            final lastName = carpenterData['lastName'] ?? '';
                            carpenterName = ('$firstName $lastName').trim();
                            if (carpenterName.isEmpty) {
                              carpenterName = "Carpenter";
                            }
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
                            shadowColor: context.themeSecondary.withValues(
                              alpha: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: context.themeSurface,
                                border: Border.all(
                                  color: context.themeSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
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

                                  // Refresh if bill was approved/rejected
                                  if (result == true && mounted) {
                                    setState(() {});
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ------------ CARPENTER PROFILE ROW (Header - CLICKABLE) -------------
                                      InkWell(
                                        onTap: () {
                                          // Navigate to carpenter profile
                                          context.push(
                                            '/admin/carpenter-profile/$carpenterId',
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            // Profile Image
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: context.themeContentColor
                                                    .withValues(alpha: 0.1),
                                                border: Border.all(
                                                  color: context.themeContentColor
                                                      .withValues(alpha: 0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child:
                                                  profileImageUrl != null &&
                                                      profileImageUrl.isNotEmpty
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        profileImageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) => Icon(
                                                              Icons.person,
                                                              color: context
                                                                  .themeContentColor,
                                                              size: 28,
                                                            ),
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: context
                                                          .themeContentColor,
                                                      size: 28,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Name
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    carpenterName,
                                                    style:
                                                        AppTypography.labelLarge()
                                                            .copyWith(
                                                              fontSize: 16,
                                                              color: context
                                                                  .themePrimary,
                                                            ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (phone.isNotEmpty)
                                                    Text(
                                                      phone,
                                                      style: AppTypography
                                                          .bodyMedium()
                                                          .copyWith(
                                                            fontSize: 12,
                                                            color: context
                                                                .themeTextSecondary,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Points and Amount Column
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                // Points Container
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: context
                                                        .themeContentColor
                                                        .withValues(
                                                          alpha: 0.2,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: context
                                                          .themeContentColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.monetization_on,
                                                        size: 18,
                                                        color: context
                                                            .themeSecondary,
                                                      ),
                                                      const SizedBox(
                                                        width: 4,
                                                      ),
                                                      AppText.label(
                                                        '${(amount / 1000).toStringAsFixed(2)} pts',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Amount Container
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: context
                                                          .themeContentColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '₹${amount.toStringAsFixed(0)}',
                                                    style: AppTypography
                                                        .labelLarge()
                                                        .copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              AppColors.success,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // ------------ CARPENTER HISTORY (if expanded) -------------
                                      if (isExpanded)
                                        FutureBuilder<Map<String, dynamic>>(
                                          future: _fetchCarpenterBillsSummary(
                                              carpenterId),
                                          builder: (context, historySnapshot) {
                                            if (historySnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child:
                                                    CircularProgressIndicator(
                                                  color:
                                                      context.themePrimary,
                                                ),
                                              );
                                            }

                                            if (!historySnapshot.hasData) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: context.themeSoftSurface,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: AppText.caption(
                                                  'No history available',
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              );
                                            }

                                            final summary =
                                                historySnapshot.data!;
                                            final totalPoints = summary[
                                                    'totalPoints']
                                                as double? ??
                                                0;
                                            final totalBills =
                                                summary['totalBills']
                                                    as int? ??
                                                0;
                                            final approvedBills =
                                                summary['approvedBills']
                                                    as int? ??
                                                0;
                                            final pendingBills =
                                                summary['pendingBills']
                                                    as int? ??
                                                0;
                                            final pointsBySite = summary[
                                                    'pointsBySite']
                                                as Map<String, dynamic>? ??
                                                {};

                                            return Container(
                                              decoration: BoxDecoration(
                                                color: context.themeSoftSurface,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: context.themePrimary
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      AppText.labelSmall(
                                                        'Carpenter Summary',
                                                        color: context
                                                            .themePrimary,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color: context
                                                                  .themePrimary
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                        4,
                                                                      ),
                                                            ),
                                                        child: AppText.caption(
                                                          'Total: ${totalPoints.toStringAsFixed(0)} pts',
                                                          color: context
                                                              .themePrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),

                                                  // Stats Grid
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: context
                                                                    .themeSurface,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                          6,
                                                                        ),
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              AppText.caption(
                                                                'Total Bills',
                                                                color: context
                                                                    .themeTextSecondary,
                                                              ),
                                                              AppText.label(
                                                                '$totalBills',
                                                                color: context
                                                                    .themePrimary,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: AppColors
                                                                    .success
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                          6,
                                                                        ),
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              AppText.caption(
                                                                'Approved',
                                                                color: AppColors
                                                                    .success,
                                                              ),
                                                              AppText.label(
                                                                '$approvedBills',
                                                                color: AppColors
                                                                    .success,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                                color: context
                                                                    .themeError
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                          6,
                                                                        ),
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              AppText.caption(
                                                                'Pending',
                                                                color: context
                                                                    .themeError,
                                                              ),
                                                              AppText.label(
                                                                '$pendingBills',
                                                                color: context
                                                                    .themeError,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),

                                                  // Points by Site
                                                  if (pointsBySite
                                                      .isNotEmpty) ...[
                                                    AppText.labelSmall(
                                                      'Points by Site',
                                                      color: context
                                                          .themeTextSecondary,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: pointsBySite
                                                          .entries
                                                          .map(
                                                            (entry) => Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                    bottom: 4,
                                                                  ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: AppText
                                                                        .caption(
                                                                      entry.key,
                                                                      maxLines: 1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      color: context
                                                                          .themeTextPrimary,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                          horizontal:
                                                                              6,
                                                                          vertical:
                                                                              2,
                                                                        ),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                          color: context
                                                                              .themeContentColor
                                                                              .withValues(
                                                                                alpha:
                                                                                    0.1,
                                                                              ),
                                                                          borderRadius:
                                                                              BorderRadius
                                                                                  .circular(
                                                                                    3,
                                                                                  ),
                                                                        ),
                                                                    child: AppText
                                                                        .caption(
                                                                      '${(entry.value as num).toStringAsFixed(0)} pts',
                                                                      color: context
                                                                          .themeContentColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],

                                                  // ----------- BILL HISTORY TABLE -----------
                                                  _BillHistoryFilteredList(
                                                    carpenterId: carpenterId,
                                                    billsList: (summary[
                                                            'billsList'] as List?)
                                                        ?.cast<
                                                            Map<String, dynamic>>()
                                                        .toList() ??
                                                        [],
                                                    allSites: (summary[
                                                            'allSites'] as List?)
                                                        ?.cast<String>()
                                                        .toList() ??
                                                        [],
                                                  ),

                                                ],
                                              ),
                                            );
                                          },
                                        ),

                                      const SizedBox(height: 10),

                                      // ------------ SITE NAME ROW (NEW) -------------
                                      if ((bill['siteName'] as String?)?.isNotEmpty ?? false)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: context.themeContentColor,
                                            ),
                                            const SizedBox(width: 6),
                                            AppText.caption(
                                              'Site: ',
                                              color:
                                                  context.themeTextSecondary,
                                            ),
                                            Expanded(
                                              child: AppText.labelSmall(
                                                bill['siteName'] as String? ??
                                                    'N/A',
                                                color:
                                                    context.themeContentColor,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 6),

                                      // ------------ DATE ROW -------------
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Bill Date
                                          if (billDate != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.receipt_long,
                                                  size: 14,
                                                  color:
                                                      context.themeContentColor,
                                                ),
                                                const SizedBox(width: 6),
                                                AppText.caption(
                                                  'Bill Date: ',
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                AppText.labelSmall(
                                                  DateFormat(
                                                    'dd MMM yyyy',
                                                  ).format(billDate.toDate()),
                                                  color:
                                                      context.themeContentColor,
                                                ),
                                              ],
                                            ),
                                          // Approved Date (if available)
                                          if (approvedAt != null) ...[
                                            if (billDate != null)
                                              const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 14,
                                                  color: AppColors.success,
                                                ),
                                                const SizedBox(width: 6),
                                                AppText.caption(
                                                  'Approved: ',
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                AppText.labelSmall(
                                                  DateFormat(
                                                    'dd MMM yyyy, hh:mm a',
                                                  ).format(approvedAt.toDate()),
                                                  color: AppColors.success,
                                                ),
                                              ],
                                            ),
                                          ],
                                          // Submitted Date (if bill date not available, show createdAt)
                                          if (billDate == null &&
                                              createdAt != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  size: 14,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                AppText.caption(
                                                  'Submitted: ',
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                AppText.caption(
                                                  DateFormat(
                                                    'dd MMM yyyy, hh:mm a',
                                                  ).format(createdAt.toDate()),
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),

                                      // ------------ BILL IMAGE (if expanded) -------------
                                      if (isExpanded &&
                                          imageUrl.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        GestureDetector(
                                          onTap: () => _viewBillImage(imageUrl),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              height: 170,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    height: 170,
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
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          AppText.caption(
                                                            l10n.failedToLoadImage,
                                                            color: context
                                                                .themeTextMuted,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 10),

                                      // ------------ ACTION BUTTONS -------------
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _rejectBill(billId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    context.themeError,
                                                foregroundColor:
                                                    context.themeOnError,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                              ),
                                              icon: Icon(
                                                Icons.close,
                                                color: context.themeOnError,
                                                size: 18,
                                              ),
                                              label: Text(
                                                l10n.reject,
                                                style: TextStyle(
                                                  color: context.themeOnError,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _approveBill(bill),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.success,
                                                foregroundColor:
                                                    AppColors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.check,
                                                size: 18,
                                              ),
                                              label: Text(
                                                l10n.approve,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
              // Floating Action Button
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    context.push('/admin/add-bill');
                  },
                  backgroundColor: context.themePrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                  icon: const Icon(Icons.add, color: AppColors.white),
                  label: Text(
                    'Add Bill',
                    style: AppTypography.labelLarge().copyWith(
                      color: AppColors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============= BILL HISTORY FILTERED LIST WIDGET =============
class _BillHistoryFilteredList extends StatefulWidget {
  final String carpenterId;
  final List<Map<String, dynamic>> billsList;
  final List<String> allSites;

  const _BillHistoryFilteredList({
    required this.carpenterId,
    required this.billsList,
    required this.allSites,
  });

  @override
  State<_BillHistoryFilteredList> createState() => _BillHistoryFilteredListState();
}

class _BillHistoryFilteredListState extends State<_BillHistoryFilteredList> {
  String? _selectedSite;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Map<String, dynamic>> get _filteredBills {
    return widget.billsList.where((bill) {
      // Site filter
      if (_selectedSite != null && _selectedSite!.isNotEmpty) {
        if (bill['siteName'] != _selectedSite) return false;
      }

      // Date range filter
      final billDate = bill['billDate'] as Timestamp?;
      if (billDate != null) {
        final date = billDate.toDate();
        if (_dateFrom != null &&
            date.isBefore(DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day))) {
          return false;
        }
        if (_dateTo != null &&
            date.isAfter(DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBills;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.themePrimary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelSmall(
                'All Bills History',
                color: context.themePrimary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.themePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: AppText.caption(
                  '${filtered.length}/${widget.billsList.length} bills',
                  color: context.themePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filters Row
          Row(
            children: [
              // Site Filter
              Expanded(
                child: DropdownButton<String?>(
                  value: _selectedSite,
                  isExpanded: true,
                  hint: AppText.caption('Filter by Site', color: context.themeTextSecondary),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: AppText.caption('All Sites', color: context.themeTextPrimary),
                    ),
                    ...widget.allSites.map(
                      (site) => DropdownMenuItem<String?>(
                        value: site,
                        child: AppText.caption(site, color: context.themeTextPrimary),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedSite = value),
                  underline: Container(
                    height: 1,
                    color: context.themePrimary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date From
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dateFrom = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: AppText.caption(
                      _dateFrom == null ? 'From' : '${_dateFrom!.day}/${_dateFrom!.month}',
                      color: _dateFrom == null
                          ? context.themeTextSecondary
                          : context.themePrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Date To
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dateTo = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: AppText.caption(
                      _dateTo == null ? 'To' : '${_dateTo!.day}/${_dateTo!.month}',
                      color: _dateTo == null ? context.themeTextSecondary : context.themePrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Clear button
              if (_selectedSite != null || _dateFrom != null || _dateTo != null)
                InkWell(
                  onTap: () => setState(() {
                    _selectedSite = null;
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: context.themeError,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bills List
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AppText.caption(
                  'No bills found',
                  color: context.themeTextSecondary,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Rows - Numbered List
                ...filtered.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final bill = entry.value;

                  final billNum = bill['billNumber'] as String? ?? 'N/A';
                  final site = bill['siteName'] as String? ?? 'N/A';
                  final amount = bill['amount'] as num? ?? 0;
                  final pts = (bill['points'] as num?)?.toStringAsFixed(1) ?? '0';
                  final status = bill['status'] as String? ?? 'pending';
                  final billDate = bill['billDate'] as Timestamp?;
                  final createdAt = bill['createdAt'] as Timestamp?;

                  // Use billDate if available, otherwise use createdAt
                  final displayDate = billDate?.toDate() ?? createdAt?.toDate();
                  final dateStr = displayDate != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(displayDate)
                      : 'N/A';

                  Color statusColor = context.themeTextSecondary;
                  String statusLabel = 'N/A';
                  if (status == 'approved') {
                    statusColor = AppColors.success;
                    statusLabel = 'Approved';
                  } else if (status == 'pending') {
                    statusColor = context.themeError;
                    statusLabel = 'Pending';
                  } else if (status == 'rejected') {
                    statusColor = context.themeError.withValues(alpha: 0.6);
                    statusLabel = 'Rejected';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with number and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.label(
                                '#$index - Bill ID: $billNum',
                                color: context.themePrimary,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: AppText.caption(
                                  statusLabel,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Bill details in rows
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.caption(
                                      'Site',
                                      color: context.themeTextSecondary,
                                    ),
                                    AppText.bodyLarge(
                                      site.isEmpty ? '-' : site,
                                      color: context.themeTextPrimary,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.caption(
                                      'Amount',
                                      color: context.themeTextSecondary,
                                    ),
                                    AppText.label(
                                      '₹${amount.toInt()}',
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.caption(
                                      'Points',
                                      color: context.themeTextSecondary,
                                    ),
                                    AppText.label(
                                      '$pts pts',
                                      color: context.themePrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AppText.caption(
                                  dateStr,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }
}
