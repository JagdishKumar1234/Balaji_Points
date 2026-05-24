import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/bill_details_page.dart';
import 'package:balaji_points/core/utils/bill_query_utils.dart';
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
  String _carpenterNameFilter = '';
  bool _showFilters = false;

  // ---------------- IMAGE VIEWER ----------------
  void _viewBillImage(String imageUrl) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
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
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 60,
                            ),
                            Text(
                              l10n.failedToLoadImage,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                          Text(
                            l10n.noImageAvailable,
                            style: const TextStyle(color: Colors.white),
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
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
    print('🎯 UI: _approveBill called');
    print('   Bill data: $bill');

    final billId = bill['billId'];
    final carpenterId = bill['carpenterId'];
    final amount = (bill['amount'] ?? 0).toDouble();

    print(
      '   Extracted: billId="$billId", carpenterId="$carpenterId", amount=$amount',
    );

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Approve Bill',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: AppColors.lightPrimary,
          ),
        ),
        content: Text(
          'Approve this bill of ₹${amount.toStringAsFixed(0)}?\n\n${(amount / 1000).floor()} points will be added to the carpenter.',
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 16,
            color: AppColors.lightPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.lightPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Approve',
              style: AppTypography.labelLarge().copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('❌ UI: User cancelled approval');
      return;
    }

    print('✅ UI: User confirmed approval, calling approveBill...');
    _showLoadingDialog();

    try {
      print('📞 UI: Calling _billService.approveBill()...');
      print(
        '   Parameters: billId="$billId", carpenterId="$carpenterId", amount=$amount',
      );

      final success = await _billService.approveBill(
        billId,
        carpenterId,
        amount,
      );

      print('📥 UI: approveBill returned: $success');
      Navigator.pop(context); // close loading

      if (!mounted) {
        print('⚠️ UI: Widget not mounted, skipping snackbar');
        return;
      }

      print('📢 UI: Showing snackbar (success: $success)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? Colors.green : Colors.red,
          content: Text(
            success
                ? 'Bill approved and points added successfully'
                : 'Failed to approve bill',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e, st) {
      print('❌ UI: Exception caught in _approveBill');
      print('   Error: $e');
      print('   StackTrace: $st');
      Navigator.pop(context); // close loading
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error approving bill: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
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
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          'Are you sure you want to reject this bill?',
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 16,
            color: AppColors.lightPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.lightPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: AppTypography.labelLarge().copyWith(color: Colors.white),
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
          backgroundColor: success ? Colors.orange : Colors.red,
          content: Text(
            success ? 'Bill rejected successfully' : 'Failed to reject bill',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error rejecting bill: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
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
      builder: (_) => const Center(
        child: const CircularProgressIndicator(color: AppColors.lightPrimary),
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
      print('Error fetching carpenter data: $e');
      _carpenterCache[carpenterId] = null;
      return null;
    }
  }

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
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.lightPrimary,
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.lightPrimary,
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
    });
  }

  // ---------------- HELPER: CHECK IF FILTERS ARE ACTIVE ----------------
  bool _hasActiveFilters() {
    return _carpenterNameFilter.isNotEmpty ||
        _startDate != null ||
        _endDate != null;
  }

  @override
  void dispose() {
    _carpenterNameController.dispose();
    super.dispose();
  }

  // ---------------- FILTER BILLS ----------------
  List<QueryDocumentSnapshot> _filterBills(List<QueryDocumentSnapshot> bills) {
    return bills.where((billDoc) {
      final bill = billDoc.data() as Map<String, dynamic>;

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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Compact iOS-style Filter Bar
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
          child: Column(
            children: [
              // Search bar with filter toggle
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carpenterNameController,
                      onChanged: (value) => setState(() => _carpenterNameFilter = value.toLowerCase()),
                      style: AppTypography.bodyMedium().copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search carpenter...',
                        hintStyle: AppTypography.bodyMedium().copyWith(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                        suffixIcon: _carpenterNameFilter.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 16, color: Colors.grey[600]),
                                onPressed: () {
                                  _carpenterNameController.clear();
                                  setState(() => _carpenterNameFilter = '');
                                },
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.lightPrimary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppColors.lightPrimary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                        color: _showFilters ? AppColors.lightPrimary : Colors.grey[700],
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showFilters = !_showFilters),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _startDate != null
                                  ? AppColors.lightPrimary.withValues(alpha: 0.4)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: _startDate != null ? AppColors.lightPrimary : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? DateFormat('dd MMM').format(_startDate!)
                                      : 'From',
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                    color: _startDate != null ? AppColors.lightPrimary : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (_startDate != null)
                                InkWell(
                                  onTap: () => setState(() => _startDate = null),
                                  child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _endDate != null
                                  ? AppColors.lightPrimary.withValues(alpha: 0.4)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                size: 14,
                                color: _endDate != null ? AppColors.lightPrimary : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd MMM').format(_endDate!)
                                      : 'To',
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                    color: _endDate != null ? AppColors.lightPrimary : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (_endDate != null)
                                InkWell(
                                  onTap: () => setState(() => _endDate = null),
                                  child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_hasActiveFilters())
                      IconButton(
                        icon: Icon(Icons.clear_all, size: 18, color: AppColors.lightPrimary),
                        onPressed: _clearFilters,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                    return const Center(
                      child: const CircularProgressIndicator(
                        color: AppColors.lightPrimary,
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasActiveFilters()
                                ? 'No bills found matching filters'
                                : l10n.noPendingBills,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 16,
                              color: Colors.grey[600],
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
                            shadowColor: AppColors.lightSecondary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    AppColors.lightSecondary.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.lightSecondary.withValues(alpha: 0.2),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ------------ CARPENTER PROFILE ROW -------------
                                    Row(
                                      children: [
                                        // Profile Image
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.lightPrimary
                                                .withOpacity(0.1),
                                            border: Border.all(
                                              color: AppColors.lightPrimary
                                                  .withOpacity(0.3),
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
                                                          color: AppColors.lightPrimary,
                                                          size: 28,
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person,
                                                  color: AppColors.lightPrimary,
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
                                                style: AppTypography.labelLarge()
                                                    .copyWith(
                                                      fontSize: 16,
                                                      color:
                                                          AppColors.lightPrimary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (phone.isNotEmpty)
                                                Text(
                                                  phone,
                                                  style: AppTypography.bodyMedium().copyWith(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Points, Amount, and Image Thumbnail
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Image Thumbnail (if available)
                                            if (imageUrl.isNotEmpty) ...[
                                              GestureDetector(
                                                onTap: () => _viewBillImage(imageUrl),
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: AppColors.lightPrimary.withOpacity(0.3),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Stack(
                                                      children: [
                                                        Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          width: 50,
                                                          height: 50,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            color: Colors.grey[300],
                                                            child: Icon(
                                                              Icons.broken_image,
                                                              size: 20,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ),
                                                        // Overlay icon to indicate it's clickable
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topCenter,
                                                              end: Alignment.bottomCenter,
                                                              colors: [
                                                                Colors.black.withOpacity(0.3),
                                                                Colors.transparent,
                                                              ],
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.zoom_in,
                                                              color: Colors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
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
                                                    color: AppColors.lightSecondary
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: AppColors.lightPrimary
                                                          .withOpacity(0.3),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.monetization_on,
                                                        size: 18,
                                                        color:
                                                            AppColors.lightSecondary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${(amount / 1000).floor()} pts',
                                                        style: AppTypography.labelLarge().copyWith(
                                                              fontSize: 15,
                                                              color: AppColors.lightSecondary,
                                                            ),
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
                                                    color: Colors.green.withOpacity(
                                                      0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: AppColors.lightPrimary
                                                          .withOpacity(0.3),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '₹${amount.toStringAsFixed(0)}',
                                                    style: AppTypography.labelLarge().copyWith(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.green.shade700,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

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
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Bill Date: ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(billDate.toDate()),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                                color: Colors.green[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Approved: ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy, hh:mm a',
                                                ).format(approvedAt.toDate()),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Submitted: ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy, hh:mm a',
                                                ).format(createdAt.toDate()),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),

                                    // ------------ BILL IMAGE (if expanded) -------------
                                    if (isExpanded && imageUrl.isNotEmpty) ...[
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
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.error_outline,
                                                          color:
                                                              Colors.grey[400],
                                                          size: 40,
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          l10n.failedToLoadImage,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 12,
                                                          ),
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
                                              backgroundColor: Colors.red[50],
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                  ),
                                            ),
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            label: Text(
                                              l10n.reject,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _approveBill(bill),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
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
                  backgroundColor: AppColors.lightPrimary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add Bill',
                    style: AppTypography.labelLarge().copyWith(
                      color: Colors.white,
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
