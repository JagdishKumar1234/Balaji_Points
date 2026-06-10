import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:intl/intl.dart';

/// Full single-file implementation:
/// - Users list (carpenters)
/// - Add Carpenter dialog (Phone + OTP)
/// NOTE: OTP verification uses FirebaseAuth and will sign the app in as the verified user
/// while verifying. After creating the user the code signs out that user. Admin will
/// therefore be signed out and must sign in again. See notes above for Server-side option.

class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  String _searchQuery = '';
  String _selectedTier = 'All';
  String _selectedSort = 'points'; // Default sort by points
  final List<String> _tiers = ['All', 'Platinum', 'Gold', 'Silver', 'Bronze'];
  final _userService = UserService();
  bool _isExporting = false;

  Future<void> _exportUsersToPdf() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Preparing carpenter list PDF...')));

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: false)
          .get();

      var users = query.docs.toList();

      // Apply same role filter used in UI (only carpenters / non-admins)
      users = users.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        if (role == 'admin') return false;
        return role == null || role.isEmpty || role == 'carpenter';
      }).toList();

      // Apply current search + tier filters for consistency
      users = users.where((doc) {
        final data = doc.data();
        final firstName = (data['firstName'] ?? '').toString().toLowerCase();
        final lastName = (data['lastName'] ?? '').toString().toLowerCase();
        final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().toLowerCase();
        final tier = data['tier'] ?? 'Bronze';

        final matchesSearch =
            _searchQuery.isEmpty ||
            firstName.contains(_searchQuery) ||
            lastName.contains(_searchQuery) ||
            phone.contains(_searchQuery);

        final matchesTier = _selectedTier == 'All' || tier == _selectedTier;

        return matchesSearch && matchesTier;
      }).toList();

      if (users.isEmpty) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No carpenters to export for current filters.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load(AppConstants.logoPath);
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}

      final generatedStr =
          'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          footer: (context) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Carpenter List • ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          build: (context) => [
            // Header with logo and shop details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 52,
                    height: 52,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(12),
                      color: PdfColors.white,
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColors.grey300,
                          blurRadius: 4,
                          offset: const PdfPoint(1, -1),
                        ),
                      ],
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(logoImage),
                    ),
                  ),
                if (logoImage != null) pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SRI BALAJI PLYWOOD AND HARDWARE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.brown800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Opp Union Bank, 150, VCTV Main Road, Erode-638003',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Phone: 096006 09121   GSTIN: 33DFXPS5949H2ZH',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Carpenter User List',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              generatedStr,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total carpenters: ${users.length}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blue900,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            // Table header
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.8), // #
                1: const pw.FlexColumnWidth(2.4), // Name
                2: const pw.FlexColumnWidth(2.4), // Mobile
                3: const pw.FlexColumnWidth(1.6), // Points
                4: const pw.FlexColumnWidth(1.6), // Tier
                5: const pw.FlexColumnWidth(2.0), // Joined on
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _userHeaderCell('#'),
                    _userHeaderCell('Carpenter Name'),
                    _userHeaderCell('Mobile No.'),
                    _userHeaderCell('Points'),
                    _userHeaderCell('Tier'),
                    _userHeaderCell('Date of Joined'),
                  ],
                ),
                ...List<pw.TableRow>.generate(users.length, (index) {
                  final data = users[index].data();
                  final firstName = (data['firstName'] ?? '').toString().trim();
                  final lastName = (data['lastName'] ?? '').toString().trim();
                  final fullName = '$firstName $lastName'.trim().isEmpty
                      ? 'Carpenter'
                      : '$firstName $lastName'.trim();
                  final phone = (data['phone'] ?? '').toString().trim();
                  final rawPoints = data['totalPoints'];
                  final points = (rawPoints is num ? rawPoints.toInt() : 0).toString();
                  final tier = (data['tier'] ?? 'Bronze').toString();
                  DateTime? joinedDate;
                  if (data['createdAt'] is Timestamp) {
                    joinedDate = (data['createdAt'] as Timestamp).toDate();
                  } else if (data['createdAt'] is DateTime) {
                    joinedDate = data['createdAt'] as DateTime;
                  }
                  final joinedStr = joinedDate != null
                      ? DateFormat('dd-MMM-yyyy').format(joinedDate)
                      : '—';

                  return pw.TableRow(
                    children: [
                      _userCell('${index + 1}'),
                      _userCell(fullName),
                      _userCell(phone),
                      _userCell(points, alignRight: true),
                      _userCell(tier),
                      _userCell(joinedStr),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      setState(() => _isExporting = false);
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export carpenter list: $e'),
          backgroundColor: context.themeError,
        ),
      );
    }
  }

  pw.Widget _userHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _userCell(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Align(
        alignment: alignRight
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(
          user: user,
          onDelete: () => _deleteCarpenter(user),
        ),
      ),
    );
  }

  void _showAddCarpenterDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCarpenterDialog(),
    );
  }

  Future<void> _deleteCarpenter(Map<String, dynamic> user) async {
    final l10n = AppLocalizations.of(context)!;
    final userId = user['userId'] as String?;
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final userName = '$firstName $lastName'.trim().isEmpty
        ? 'Carpenter'
        : '$firstName $lastName'.trim();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToDeleteCarpenter),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: context.themeError,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.deleteCarpenter,
                style: AppTypography.labelLarge().copyWith(
                  fontSize: 20,
                  color: context.themeError,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteCarpenterConfirmation.replaceAll('{userName}', userName),
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 16,
            color: context.themeContentColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
            child: Text(
              l10n.delete,
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: context.themeContentColor),
        ),
      );
    }

    try {
      final success = await _userService.deleteCarpenter(userId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.carpenterDeletedSuccess),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToDeleteCarpenter),
              backgroundColor: context.themeError,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Parse error message for better user feedback
        String errorMessage = l10n.failedToDeleteCarpenter;
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('permission') ||
            errorStr.contains('permission_denied')) {
          errorMessage =
              '${l10n.failedToDeleteCarpenter}\nPermission denied. Please check Firestore security rules.';
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage =
              '${l10n.failedToDeleteCarpenter}\nNetwork error. Please check your connection.';
        } else {
          errorMessage = '${l10n.failedToDeleteCarpenter}\n${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Search + Add button
        Container(
          padding: const EdgeInsets.all(16),
          color: context.themeBackground,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: AppTypography.bodyMedium().copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: l10n.searchByNameOrPhone,
                        hintStyle: AppTypography.bodyMedium().copyWith(
                          color: context.themeTextMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.themeContentColor,
                        ),
                        filled: true,
                        fillColor: context.themeSoftSurface,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Actions: Add + Export
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAddCarpenterDialog,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.add),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isExporting
                              ? context.themeTextSecondary.withValues(
                                  alpha: 0.1,
                                )
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
                                  color: context.themeContentColor,
                                  size: 22,
                                ),
                          onPressed: _isExporting ? null : _exportUsersToPdf,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          tooltip: 'Export carpenter list to PDF',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sort Dropdown + Tier Filter Row
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.themeSoftSurface,
                        borderRadius: AppRadius.md12,
                        border: Border.all(
                          color: context.themePrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: context.themeContentColor,
                          ),
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 14,
                            color: context.themeContentColor,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'points',
                              child: Text('Points (High to Low)'),
                            ),
                            DropdownMenuItem(
                              value: 'pointsLowToHigh',
                              child: Text('Points (Low to High)'),
                            ),
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Newest First'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Oldest First'),
                            ),
                            DropdownMenuItem(
                              value: 'nameAZ',
                              child: Text('Name (A-Z)'),
                            ),
                            DropdownMenuItem(
                              value: 'nameZA',
                              child: Text('Name (Z-A)'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSort = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tier Filter
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tiers.map((tier) {
                            final isSelected = _selectedTier == tier;
                            final tierLabel = tier == 'All'
                                ? l10n.all
                                : tier == 'Platinum'
                                ? l10n.platinum
                                : tier == 'Gold'
                                ? l10n.gold
                                : tier == 'Silver'
                                ? l10n.silver
                                : l10n.bronze;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(tierLabel),
                                labelStyle: AppTypography.labelLarge().copyWith(
                                  fontSize: 14,
                                  color: isSelected
                                      ? AppColors.white
                                      : context.themePrimary,
                                ),
                                backgroundColor: context.themeBorder,
                                selectedColor: context.themePrimary,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTier = tier;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final l10n = AppLocalizations.of(context)!;
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
                        l10n.errorLoadingUsers,
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
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

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.themeContentColor,
                  ),
                );
              }

              var users = snapshot.data?.docs ?? [];

              // Filter to show only carpenters (exclude admins)
              // Include users with role='carpenter' OR users without a role field (assumed to be carpenters)
              users = users.where((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final role = user['role'] as String?;

                // Exclude admins, include carpenters and users without role
                if (role == 'admin') {
                  return false;
                }

                // Include if role is 'carpenter' or if role is null/empty (assumed carpenter)
                return role == null || role.isEmpty || role == 'carpenter';
              }).toList();

              // Apply search and tier filters
              users = users.where((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final firstName = (user['firstName'] ?? '')
                    .toString()
                    .toLowerCase();
                final lastName = (user['lastName'] ?? '')
                    .toString()
                    .toLowerCase();
                final phone = (user['phoneNumber'] ?? user['phone'] ?? '').toString().toLowerCase();
                final tier = user['tier'] ?? 'Bronze';

                final matchesSearch =
                    _searchQuery.isEmpty ||
                    firstName.contains(_searchQuery) ||
                    lastName.contains(_searchQuery) ||
                    phone.contains(_searchQuery);

                final matchesTier =
                    _selectedTier == 'All' || tier == _selectedTier;

                return matchesSearch && matchesTier;
              }).toList();

              // Sort based on selected option
              users.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                switch (_selectedSort) {
                  case 'points':
                    // Sort by points (high to low)
                    final aRaw = aData['totalPoints'];
                    final bRaw = bData['totalPoints'];
                    final aPoints = aRaw is num ? aRaw.toInt() : 0;
                    final bPoints = bRaw is num ? bRaw.toInt() : 0;
                    return bPoints.compareTo(aPoints);

                  case 'pointsLowToHigh':
                    // Sort by points (low to high)
                    final aRaw = aData['totalPoints'];
                    final bRaw = bData['totalPoints'];
                    final aPoints = aRaw is num ? aRaw.toInt() : 0;
                    final bPoints = bRaw is num ? bRaw.toInt() : 0;
                    return aPoints.compareTo(bPoints);

                  case 'newest':
                    // Sort by registration date (newest first)
                    final aCreated = aData['createdAt'] as Timestamp?;
                    final bCreated = bData['createdAt'] as Timestamp?;
                    if (aCreated == null && bCreated == null) return 0;
                    if (aCreated == null) return 1;
                    if (bCreated == null) return -1;
                    return bCreated.compareTo(aCreated);

                  case 'oldest':
                    // Sort by registration date (oldest first)
                    final aCreated = aData['createdAt'] as Timestamp?;
                    final bCreated = bData['createdAt'] as Timestamp?;
                    if (aCreated == null && bCreated == null) return 0;
                    if (aCreated == null) return 1;
                    if (bCreated == null) return -1;
                    return aCreated.compareTo(bCreated);

                  case 'nameAZ':
                    // Sort by name (A to Z)
                    final aFirstName = (aData['firstName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final aLastName = (aData['lastName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final bFirstName = (bData['firstName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final bLastName = (bData['lastName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final aFullName = '$aFirstName $aLastName'.trim();
                    final bFullName = '$bFirstName $bLastName'.trim();
                    return aFullName.compareTo(bFullName);

                  case 'nameZA':
                    // Sort by name (Z to A)
                    final aFirstName = (aData['firstName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final aLastName = (aData['lastName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final bFirstName = (bData['firstName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final bLastName = (bData['lastName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final aFullName = '$aFirstName $aLastName'.trim();
                    final bFullName = '$bFirstName $bLastName'.trim();
                    return bFullName.compareTo(aFullName);

                  default:
                    return 0;
                }
              });

              if (users.isEmpty) {
                final l10n = AppLocalizations.of(context)!;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 80,
                        color: context.themeBorder,
                      ),
                      const SizedBox(height: 20),
                      AppText.label(l10n.noUsersFound),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? l10n.tryDifferentSearch
                            : l10n.noCarpentersYet,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  user['userId'] = userId;

                  final firstName = user['firstName'] ?? '';
                  final lastName = user['lastName'] ?? '';
                  final phone = user['phone'] ?? '';
                  final rawTotalPoints = user['totalPoints'];
                  final totalPoints = rawTotalPoints is num ? rawTotalPoints.toInt() : 0;
                  final tier = user['tier'] ?? 'Bronze';
                  final profileImage = user['profileImage'] ?? '';
                  final createdAt = user['createdAt'] is Timestamp
                      ? (user['createdAt'] as Timestamp).toDate()
                      : (user['createdAt'] is DateTime
                            ? user['createdAt'] as DateTime
                            : null);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.all16,
                      side: BorderSide(color: context.themeBorder, width: 1),
                    ),
                    child: InkWell(
                      onTap: () => _showUserDetails(user),
                      borderRadius: AppRadius.all16,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Top Row: Rank, Profile, Name, Actions
                            Row(
                              children: [
                                // Rank Badge
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.themePrimary,
                                    borderRadius: AppRadius.sm8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${index + 1}',
                                      style: AppTypography.labelLarge()
                                          .copyWith(
                                            fontSize: 14,
                                            color: AppColors.white,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Profile Image
                                ClipOval(
                                  child:
                                      profileImage != null && profileImage != ''
                                      ? Image.network(
                                          profileImage,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: context
                                                      .themeContentColor
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 24,
                                                    color: context
                                                        .themeContentColor,
                                                  ),
                                                );
                                              },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              width: 48,
                                              height: 48,
                                              color: context.themeContentColor
                                                  .withValues(alpha: 0.1),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(context.themePrimary),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          color: context.themeContentColor
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.person,
                                            size: 24,
                                            color: context.themeContentColor,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // User Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$firstName $lastName',
                                        style: AppTypography.labelLarge()
                                            .copyWith(
                                              fontSize: 16,
                                              color: context.themeContentColor,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        phone,
                                        style: AppTypography.bodyMedium()
                                            .copyWith(
                                              fontSize: 13,
                                              color: context.themeTextSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Delete Button
                                OutlinedButton(
                                  onPressed: () => _deleteCarpenter(user),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.themeError,
                                    side: BorderSide(
                                      color: context.themeError,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.sm8,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.delete,
                                    style: AppTypography.labelLarge().copyWith(
                                      fontSize: 13,
                                      color: context.themeError,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Bottom Row: Tier, Points, Joined Date
                            Row(
                              children: [
                                // Tier Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTierColor(tier),
                                    borderRadius: AppRadius.sm8,
                                  ),
                                  child: Text(
                                    tier,
                                    style: AppTypography.labelLarge().copyWith(
                                      fontSize: 11,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Points
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        size: 16,
                                        color: context.themeContentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '$totalPoints Points',
                                          style: AppTypography.labelLarge()
                                              .copyWith(
                                                fontSize: 14,
                                                color:
                                                    context.themeContentColor,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Joined Date
                                if (createdAt != null)
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: context.themeTextSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(createdAt),
                                            style: AppTypography.bodyMedium()
                                                .copyWith(
                                                  fontSize: 12,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
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

/// ---------------------------
/// Add Carpenter Dialog (Phone + PIN)
/// ---------------------------
/// This dialog creates a new carpenter with phone + PIN authentication
/// Uses PinAuthService to create user without signing out admin

class AddCarpenterDialog extends StatefulWidget {
  const AddCarpenterDialog({super.key});

  @override
  State<AddCarpenterDialog> createState() => _AddCarpenterDialogState();
}

class _AddCarpenterDialogState extends State<AddCarpenterDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _creating = false;

  final _pinAuthService = PinAuthService();

  void _showSnack(String s, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        backgroundColor: isError ? context.themeError : AppColors.success,
      ),
    );
  }

  Future<bool> _phoneExists(String phone) async {
    final normalized = _pinAuthService.normalizePhone(phone);
    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: normalized)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  Future<void> _createCarpenter() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneRaw = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (phoneRaw.isEmpty || phoneRaw.length < 10) {
      _showSnack(l10n.enterValidPhone, isError: true);
      return;
    }

    if (pin.isEmpty || pin.length < 4) {
      _showSnack('PIN must be at least 4 digits', isError: true);
      return;
    }

    // Check duplicate
    final exists = await _phoneExists(phoneRaw);
    if (exists) {
      _showSnack(l10n.phoneAlreadyExists, isError: true);
      return;
    }

    setState(() => _creating = true);

    try {
      final success = await _pinAuthService.setPinForPhone(
        phone: phoneRaw,
        pin: pin,
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
      );

      setState(() => _creating = false);

      if (success) {
        if (mounted) {
          _showSnack('Carpenter created successfully!');
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          _showSnack('Failed to create carpenter', isError: true);
        }
      }
    } catch (e) {
      setState(() => _creating = false);
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.addCarpenter,
              style: AppTypography.labelLarge().copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumberLabel,
                hintText: l10n.phoneNumberHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN (4-6 digits)',
                hintText: 'Enter PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name (Optional)',
                hintText: 'Enter first name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name (Optional)',
                hintText: 'Enter last name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            if (_creating)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createCarpenter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------
/// Points History View Widget
/// ---------------------------

class _PointsHistoryView extends StatelessWidget {
  final String userId;
  final int totalPoints;
  const _PointsHistoryView({required this.userId, required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_points')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: context.themeContentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.themeError.withValues(alpha: 0.1),
              borderRadius: AppRadius.md12,
              border: Border.all(color: context.themeError.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Error loading history: ${snapshot.error}',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: context.themeError,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeSoftSurface,
              borderRadius: AppRadius.md12,
            ),
            child: Text(
              'No points history found',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: context.themeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final pointsHistory = (userData['pointsHistory'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        if (pointsHistory.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeSoftSurface,
              borderRadius: AppRadius.md12,
            ),
            child: Text(
              'No transactions yet',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: context.themeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Deduplicate history by billId (keep first occurrence with latest timestamp)
        final Map<String, Map<String, dynamic>> deduplicatedMap = {};
        for (final item in pointsHistory) {
          final billId = item['billId'] as String? ?? '';
          if (billId.isNotEmpty) {
            final existing = deduplicatedMap[billId];
            final currentTime = item['createdAt'] as Timestamp?;
            final existingTime = existing?['createdAt'] as Timestamp?;

            // Keep the entry with the latest timestamp
            if (existing == null || (currentTime != null && existingTime != null && currentTime.compareTo(existingTime) > 0)) {
              deduplicatedMap[billId] = item;
            }
          }
        }

        final deduplicatedHistory = deduplicatedMap.values.toList();

        // Calculate sum of all history entries
        int historySum = 0;
        for (final entry in deduplicatedHistory) {
          final points = entry['points'] as num?;
          if (points != null) {
            historySum += points.toInt();
          }
        }

        // Sort history by date (newest first)
        final sortedHistory = List<Map<String, dynamic>>.from(deduplicatedHistory);
        sortedHistory.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary cards
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeSoftSurface,
                borderRadius: AppRadius.md12,
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Transactions',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        '${deduplicatedHistory.length}',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 16,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History Sum',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: context.themePrimary),
                          const SizedBox(width: 4),
                          Text(
                            '$historySum',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Total',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 16, color: context.themePrimary),
                          const SizedBox(width: 4),
                          Text(
                            '$totalPoints',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (historySum != totalPoints) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: AppRadius.sm8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Difference: ${(historySum - totalPoints).abs()}',
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: AppColors.warning,
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

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date & Time',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: context.themePrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Bill ID',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: context.themePrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Points',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: context.themePrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            ...sortedHistory.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final item = entry.value;
              final timestamp = item['createdAt'] as Timestamp?;
              final billId = item['billId'] as String? ?? 'N/A';
              final points = (item['points'] as num?)?.toInt() ?? 0;

              final dateStr = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                  : 'N/A';

              final isLastRow = index == sortedHistory.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? context.themeSurface
                      : context.themeBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: context.themeBorder,
                      width: isLastRow ? 0 : 0.5,
                    ),
                  ),
                  borderRadius: isLastRow
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      : BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateStr,
                        style: AppTypography.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.themeTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        billId,
                        style: AppTypography.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.stars, size: 14, color: context.themePrimary),
                          const SizedBox(width: 4),
                          Text(
                            '$points',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 12,
                              color: context.themePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Grand Total Footer
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.md12,
                border: Border.all(
                  color: context.themePrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total Points',
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 14,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 18, color: context.themePrimary),
                      const SizedBox(width: 6),
                      Text(
                        '$totalPoints',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.themePrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Withdrawal Section
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeError.withValues(alpha: 0.08),
                borderRadius: AppRadius.md12,
                border: Border.all(
                  color: context.themeError.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.undo, color: context.themeError, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Withdraw Points',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                          color: context.themeError,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select transactions below to withdraw points',
                    style: AppTypography.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WithdrawalList(
                    userId: userId,
                    history: sortedHistory,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ---------------------------
/// Withdrawal List Widget
/// ---------------------------

class _WithdrawalList extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> history;

  const _WithdrawalList({
    required this.userId,
    required this.history,
  });

  @override
  State<_WithdrawalList> createState() => _WithdrawalListState();
}

class _WithdrawalListState extends State<_WithdrawalList> {
  final Set<String> _selectedBillIds = {};

  @override
  Widget build(BuildContext context) {
    // Deduplicate history by billId (keep first occurrence with latest timestamp)
    final Map<String, Map<String, dynamic>> deduplicatedMap = {};
    for (final item in widget.history) {
      final billId = item['billId'] as String? ?? '';
      if (billId.isNotEmpty) {
        final existing = deduplicatedMap[billId];
        final currentTime = item['createdAt'] as Timestamp?;
        final existingTime = existing?['createdAt'] as Timestamp?;

        // Keep the entry with the latest timestamp
        if (existing == null || (currentTime != null && existingTime != null && currentTime.compareTo(existingTime) > 0)) {
          deduplicatedMap[billId] = item;
        }
      }
    }

    final deduplicatedHistory = deduplicatedMap.values.toList();

    return Column(
      children: [
        ...deduplicatedHistory.map<Widget>((item) {
          final billId = item['billId'] as String? ?? '';
          final points = (item['points'] as num?)?.toInt() ?? 0;
          final timestamp = item['createdAt'] as Timestamp?;

          final dateStr = timestamp != null
              ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
              : 'N/A';

          final isSelected = _selectedBillIds.contains(billId);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.themeError.withValues(alpha: 0.1)
                  : context.themeSurface,
              borderRadius: AppRadius.sm8,
              border: Border.all(
                color: isSelected
                    ? context.themeError
                    : context.themeBorder,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedBillIds.add(billId);
                  } else {
                    _selectedBillIds.remove(billId);
                  }
                });
              },
              title: Text(
                'Bill: $billId',
                style: AppTypography.bodySmall().copyWith(
                  fontSize: 13,
                  color: context.themeTextPrimary,
                ),
              ),
              subtitle: Text(
                '$dateStr • $points points',
                style: AppTypography.bodySmall().copyWith(
                  fontSize: 12,
                  color: context.themeTextSecondary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
            ),
          );
        }).toList(),
        if (_selectedBillIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmWithdrawal(context),
              icon: const Icon(Icons.undo),
              label: Text('Withdraw ${_selectedBillIds.length} Transaction(s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themeError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.sm8,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmWithdrawal(BuildContext context) async {
    final totalPoints = _selectedBillIds.fold<int>(0, (total, billId) {
      final item = widget.history.firstWhere(
        (item) => item['billId'] == billId,
        orElse: () => {},
      );
      return total + ((item['points'] as num?)?.toInt() ?? 0);
    });

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Text(
          'Withdraw $totalPoints points from ${_selectedBillIds.length} transaction(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Remove selected bills from pointsHistory
      final userPointsRef =
          FirebaseFirestore.instance.collection('user_points').doc(widget.userId);

      await userPointsRef.update({
        'pointsHistory': FieldValue.arrayRemove(
          widget.history
              .where((item) => _selectedBillIds.contains(item['billId']))
              .toList(),
        ),
      });

      if (!mounted) return;

      setState(() {
        _selectedBillIds.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrew $totalPoints points'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: context.themeError,
        ),
      );
    }
  }
}

/// ---------------------------
/// Approved Bills List Widget
/// ---------------------------

class _ApprovedBillsList extends StatelessWidget {
  final String carpenterId;
  const _ApprovedBillsList({required this.carpenterId});

  @override
  Widget build(BuildContext context) {
    final billService = BillService();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                color: context.themeContentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeError,
              borderRadius: AppRadius.md12,
            ),
            child: Text(
              'Error loading bills: ${snapshot.error}',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: context.themeError,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeSoftSurface,
              borderRadius: AppRadius.md12,
            ),
            child: Text(
              'No approved bills yet',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 14,
                color: context.themeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final bills = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index].data() as Map<String, dynamic>;
            final billId = bills[index].id;
            final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
            final pointsEarned = (bill['pointsEarned'] as num?)?.toInt() ?? 0;
            final approvedAt = bill['approvedAt'] as Timestamp?;
            final billDate = bill['billDate'] as Timestamp?;
            final storeName = bill['storeName'] as String? ?? '';
            final billNumber = bill['billNumber'] as String? ?? '';

            DateTime? displayDate;
            if (approvedAt != null) {
              displayDate = approvedAt.toDate();
            } else if (billDate != null) {
              displayDate = billDate.toDate();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: AppRadius.md12,
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: context.themeTextSecondary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (storeName.isNotEmpty) AppText.label(storeName),
                            if (billNumber.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Bill #$billNumber',
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 12,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                            if (displayDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: context.themeTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(displayDate),
                                    style: AppTypography.bodyMedium().copyWith(
                                      fontSize: 12,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText.label('₹${amount.toStringAsFixed(0)}'),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars,
                                size: 16,
                                color: context.themeContentColor,
                              ),
                              const SizedBox(width: 4),
                              AppText.label('$pointsEarned Points'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showWithdrawConfirmation(
                        context,
                        billService,
                        billId,
                        amount,
                        pointsEarned,
                      ),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Withdraw Points'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.themeError,
                        side: BorderSide(color: context.themeError, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.sm8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
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

  Future<void> _showWithdrawConfirmation(
    BuildContext context,
    BillService billService,
    String billId,
    double amount,
    int points,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: context.themeError,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Withdraw Points',
                style: AppTypography.labelLarge().copyWith(
                  fontSize: 20,
                  color: context.themeError,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              'Are you sure you want to withdraw points from this bill?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeSoftSurface,
                borderRadius: AppRadius.sm8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount:',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                        ),
                      ),
                      AppText.label('₹${amount.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Points to withdraw:',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$points',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                          color: context.themeError,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. The points will be deducted from the carpenter\'s account.',
              style: AppTypography.bodyMedium().copyWith(
                fontSize: 13,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
            child: Text(
              'Withdraw',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    if (!context.mounted) return;

    // Show loading dialog and store reference
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Prevent back button from closing
        child: Center(
          child: CircularProgressIndicator(color: context.themeContentColor),
        ),
      ),
    );

    try {
      final success = await billService.withdrawBill(billId);

      // Close loading dialog - ensure we close it
      if (context.mounted) {
        Navigator.of(context, rootNavigator: false).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Points withdrawn successfully'
                  : 'Failed to withdraw points. Please try again.',
            ),
            backgroundColor: success ? AppColors.success : context.themeError,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Ensure loading dialog is closed even on error
      if (context.mounted) {
        Navigator.of(context, rootNavigator: false).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error withdrawing points: ${e.toString()}'),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// ---------------------------
/// User Details Screen (Full Screen)
/// ---------------------------

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDelete;
  const UserDetailsScreen({super.key, required this.user, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final phone = user['phone'] ?? '';
    final rawPoints = user['totalPoints'];
    final totalPoints = rawPoints is num ? rawPoints.toInt() : 0;
    final tier = user['tier'] ?? 'Bronze';
    final profileImage = user['profileImage'] ?? '';

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(color: context.themeContentColor),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ClipOval(
                  child: profileImage != null && profileImage != ''
                      ? Image.network(
                          profileImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.white.withValues(alpha: 0.20),
                              child: Icon(
                                Icons.person,
                                size: 35,
                                color: AppColors.white,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.white.withValues(alpha: 0.20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.themePrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.white.withValues(alpha: 0.20),
                          child: const Icon(
                            Icons.person,
                            size: 35,
                            color: AppColors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 20,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        phone,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points Summary Card (Real-time updates)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user['userId'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      int currentPoints = totalPoints;
                      String currentTier = tier;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        currentPoints =
                            (userData['totalPoints'] as num?)?.toInt() ??
                            totalPoints;
                        currentTier = userData['tier'] as String? ?? tier;
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.themeSoftSurface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 32,
                                  color: context.themeContentColor,
                                ),
                                const SizedBox(width: 12),
                                AppText.label('$currentPoints'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.totalPointsLabel,
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 14,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _getTierColor(currentTier),
                                borderRadius: AppRadius.md12,
                              ),
                              child: Text(
                                l10n.tierLabel(currentTier),
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Reset PIN Button Section
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themePrimary.withValues(alpha: 0.05),
                      borderRadius: AppRadius.md12,
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_reset,
                              color: context.themeContentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            AppText.label(l10n.adminResetPin),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.adminResetPinSubtitle,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themePrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    AdminResetPINDialog(user: user),
                              );
                            },
                            icon: const Icon(Icons.vpn_key, size: 18),
                            label: Text(l10n.adminResetPin),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.themePrimary,
                              side: BorderSide(
                                color: context.themeContentColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md12,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete Button Section
                  if (onDelete != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeError.withValues(alpha: 0.1),
                        borderRadius: AppRadius.md12,
                        border: Border.all(
                          color: context.themeError.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: context.themeError,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.dangerZone,
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 16,
                                  color: context.themeError,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.deleteCarpenterWarning,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 13,
                              color: context.themePrimary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pop(); // Close screen first
                                onDelete?.call();
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(l10n.deleteCarpenter),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.themeError,
                                side: BorderSide(
                                  color: context.themeError,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.md12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Points History Section
                  const SizedBox(height: 24),
                  AppText.label('Points History & Transactions'),
                  const SizedBox(height: 12),

                  _PointsHistoryView(userId: user['userId'], totalPoints: totalPoints),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin Reset PIN Dialog
/// Allows admin to reset PIN for any carpenter
class AdminResetPINDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminResetPINDialog({super.key, required this.user});

  @override
  State<AdminResetPINDialog> createState() => _AdminResetPINDialogState();
}

class _AdminResetPINDialogState extends State<AdminResetPINDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinAuthService = PinAuthService();
  bool _isResetting = false;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final phone = widget.user['phone'] as String? ?? '';

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinMismatch),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      final success = await _pinAuthService.resetPin(
        phone: phone,
        newPin: newPin,
        isAdmin: true,
      );

      if (!mounted) return;
      setState(() => _isResetting = false);

      if (success) {
        final firstName = widget.user['firstName'] ?? '';
        final lastName = widget.user['lastName'] ?? '';
        final carpenterName = '$firstName $lastName'.trim().isEmpty
            ? 'Carpenter'
            : '$firstName $lastName'.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminResetPinSuccess(carpenterName)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop(); // Close dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminResetPinFailed),
            backgroundColor: context.themeError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminResetPinFailed),
          backgroundColor: context.themeError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = widget.user['firstName'] ?? '';
    final lastName = widget.user['lastName'] ?? '';
    final carpenterName = '$firstName $lastName'.trim().isEmpty
        ? 'Carpenter'
        : '$firstName $lastName'.trim();
    final phone = widget.user['phone'] as String? ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.themeContentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: AppColors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.adminResetPinTitle(carpenterName),
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 18,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 13,
                              color: AppColors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: _isResetting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminResetPinSubtitle,
                      style: AppTypography.bodyMedium().copyWith(
                        fontSize: 14,
                        color: context.themePrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New PIN Field
                    TextFormField(
                      controller: _newPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 20,
                        letterSpacing: 8,
                        color: context.themeContentColor,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.enterNewPinForCarpenter,
                        counterText: "",
                        filled: true,
                        fillColor: context.themePrimary.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themePrimary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themePrimary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themeContentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? "";
                        if (v.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
                          return l10n.enter4Digits;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm PIN Field
                    TextFormField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 20,
                        letterSpacing: 8,
                        color: context.themeContentColor,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.confirmNewPinForCarpenter,
                        counterText: "",
                        filled: true,
                        fillColor: context.themePrimary.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themePrimary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themePrimary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.all16,
                          borderSide: BorderSide(
                            color: context.themeContentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? "";
                        if (v.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
                          return l10n.enter4Digits;
                        }
                        if (v != _newPinController.text.trim()) {
                          return l10n.pinMismatch;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isResetting
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md12,
                              ),
                              side: BorderSide(
                                color: context.themeContentColor,
                                width: 1.5,
                              ),
                            ),
                            child: AppText.label(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.themeContentColor,
                              borderRadius: AppRadius.md12,
                            ),
                            child: ElevatedButton(
                              onPressed: _isResetting ? null : _resetPin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.transparent,
                                shadowColor: AppColors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.md12,
                                ),
                              ),
                              child: _isResetting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      l10n.adminResetPin,
                                      style: AppTypography.labelLarge()
                                          .copyWith(
                                            fontSize: 16,
                                            color: AppColors.white,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getTierColor(String tier) {
  switch (tier) {
    case 'Platinum':
      return const Color(0xFF00D4FF);
    case 'Gold':
      return const Color(0xFFFFD700);
    case 'Silver':
      return AppColors.tierSilver;
    case 'Bronze':
    default:
      return AppColors.tierBronze;
  }
}
