import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class SearchHeader extends StatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedTier;
  final String selectedSort;
  final List<String> tiers;
  final bool isExporting;
  final Function(String) onSearchChanged;
  final Function(String?) onTierChanged;
  final Function(String?) onSortChanged;
  final VoidCallback onAddPressed;
  final VoidCallback onExportPressed;

  const SearchHeader({
    required this.searchController,
    required this.searchQuery,
    required this.selectedTier,
    required this.selectedSort,
    required this.tiers,
    required this.isExporting,
    required this.onSearchChanged,
    required this.onTierChanged,
    required this.onSortChanged,
    required this.onAddPressed,
    required this.onExportPressed,
    super.key,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late bool _isExporting;

  @override
  void initState() {
    super.initState();
    _isExporting = widget.isExporting;
  }

  Future<void> _exportUsersToPdf() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing carpenter list PDF...')),
    );

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: false)
          .get();

      var users = query.docs.toList();

      users = users.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        if (role == 'admin') return false;
        return role == null || role.isEmpty || role == 'carpenter';
      }).toList();

      users = users.where((doc) {
        final data = doc.data();
        final firstName = (data['firstName'] ?? '').toString().toLowerCase();
        final lastName = (data['lastName'] ?? '').toString().toLowerCase();
        final phone = (data['phoneNumber'] ?? data['phone'] ?? '').toString().toLowerCase();
        final tier = data['tier'] ?? 'Bronze';

        final matchesSearch = widget.searchQuery.isEmpty ||
            firstName.contains(widget.searchQuery) ||
            lastName.contains(widget.searchQuery) ||
            phone.contains(widget.searchQuery);

        final matchesTier = widget.selectedTier == 'All' || tier == widget.selectedTier;

        return matchesSearch && matchesTier;
      }).toList();

      if (users.isEmpty) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No carpenters to export for current filters.')),
        );
        return;
      }

      // Fetch bill data for each carpenter
      final Map<String, Map<String, dynamic>> carpenterBillData = {};
      double totalGrossPoints = 0;

      for (var userDoc in users) {
        final userId = userDoc.id;
        final billsSnapshot = await FirebaseFirestore.instance
            .collection('bills')
            .where('carpenterId', isEqualTo: userId)
            .get();

        double totalBillAmount = 0;
        double totalEarnedPoints = 0;

        for (var billDoc in billsSnapshot.docs) {
          final billData = billDoc.data();
          final amount = (billData['amount'] as num?)?.toDouble() ?? 0.0;
          final status = billData['status'] as String? ?? '';

          totalBillAmount += amount;
          if (status == 'approved') {
            totalEarnedPoints += amount / 1000;
          }
        }

        carpenterBillData[userId] = {
          'totalBillAmount': totalBillAmount,
          'totalEarnedPoints': totalEarnedPoints,
        };

        totalGrossPoints += totalEarnedPoints;
      }

      // Sort users by points (descending)
      users.sort((a, b) {
        final pointsA = carpenterBillData[a.id]?['totalEarnedPoints'] ?? 0.0 as num;
        final pointsB = carpenterBillData[b.id]?['totalEarnedPoints'] ?? 0.0 as num;
        return pointsB.compareTo(pointsA);
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Carpenter List Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on: ${DateFormat('dd/MM/yyyy, hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Phone', 'Tier', 'Total Bills (₹)', 'Earned Points', 'Status'],
              data: users.map((doc) {
                final data = doc.data();
                final firstName = data['firstName'] ?? '';
                final lastName = data['lastName'] ?? '';
                final phone = data['phoneNumber'] ?? data['phone'] ?? '';
                final tier = data['tier'] ?? 'Bronze';
                final isActive = data['isActive'] ?? true;
                final billData = carpenterBillData[doc.id] ?? {};
                final totalBillAmount = (billData['totalBillAmount'] ?? 0.0 as num).toStringAsFixed(0);
                final earnedPoints = (billData['totalEarnedPoints'] ?? 0.0 as num).toStringAsFixed(2);

                return [
                  '$firstName $lastName',
                  phone,
                  tier,
                  totalBillAmount,
                  earnedPoints,
                  isActive ? 'Active' : 'Inactive',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(),
              cellHeight: 20,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Total Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total Carpenters: ${users.length}',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Gross Total Points: ${totalGrossPoints.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'carpenter_list_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Carpenter list exported successfully!')),
      );
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: context.themeBackground,
      child: Column(
        children: [
          // Search + Action Buttons Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  style: AppTypography.bodyMedium().copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l10n.searchByNameOrPhone,
                    hintStyle: AppTypography.bodyMedium().copyWith(
                      color: context.themeTextMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: context.themeContentColor,
                    ),
                    filled: true,
                    fillColor: context.themeSoftSurface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.md12,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onAddPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.add, style: const TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.md12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isExporting
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
                          color: context.themeContentColor,
                          size: 22,
                        ),
                  onPressed: _isExporting ? null : _exportUsersToPdf,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Export carpenter list to PDF',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filters Row (Sort + Tier)
          SizedBox(
            height: 44,
            child: Row(
              children: [
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      value: widget.selectedSort,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: context.themeContentColor,
                      ),
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 13,
                        color: context.themeTextPrimary,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'points',
                          child: Text(
                            'Sort by Points',
                            style: TextStyle(color: context.themeTextPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text(
                            'Sort by Name',
                            style: TextStyle(color: context.themeTextPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'recent',
                          child: Text(
                            'Recent Joins',
                            style: TextStyle(color: context.themeTextPrimary),
                          ),
                        ),
                      ],
                      onChanged: widget.onSortChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tier Filter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        value: widget.selectedTier,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: context.themeContentColor,
                        ),
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 13,
                          color: context.themeTextPrimary,
                        ),
                        isExpanded: true,
                        items: widget.tiers
                            .map((tier) => DropdownMenuItem(
                                  value: tier,
                                  child: Text(
                                    'Tier: $tier',
                                    style: TextStyle(color: context.themeTextPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: widget.onTierChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
