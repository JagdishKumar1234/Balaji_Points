import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class ExportUsersBeforeCleanupScreen extends StatefulWidget {
  const ExportUsersBeforeCleanupScreen({super.key});

  @override
  State<ExportUsersBeforeCleanupScreen> createState() => _ExportUsersBeforeCleanupScreenState();
}

class _ExportUsersBeforeCleanupScreenState extends State<ExportUsersBeforeCleanupScreen> {
  bool _isExporting = false;

  Future<void> _exportUsersPdf() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing user backup PDF...')),
    );

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .get();

      var users = query.docs.toList();

      // Filter carpenters only (exclude admins)
      users = users.where((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        if (role == 'admin') return false;
        return role == null || role.isEmpty || role == 'carpenter';
      }).toList();

      if (users.isEmpty) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No carpenters found.')),
        );
        return;
      }

      // Fetch bill data for each carpenter
      final Map<String, Map<String, dynamic>> carpenterData = {};
      double totalGrossPoints = 0;

      for (var userDoc in users) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        final billsSnapshot = await FirebaseFirestore.instance
            .collection('bills')
            .where('carpenterId', isEqualTo: userId)
            .get();

        double totalEarnedPoints = 0;
        for (var billDoc in billsSnapshot.docs) {
          final billData = billDoc.data();
          final amount = (billData['amount'] as num?)?.toDouble() ?? 0.0;
          final status = billData['status'] as String? ?? '';

          if (status == 'approved') {
            totalEarnedPoints += amount / 1000;
          }
        }

        carpenterData[userId] = {
          'totalPoints': userData['totalPoints'] ?? 0,
          'earnedPoints': totalEarnedPoints,
          'phone': userData['phoneNumber'] ?? userData['phone'] ?? 'N/A',
          'createdAt': userData['createdAt'] as Timestamp?,
        };

        totalGrossPoints += totalEarnedPoints;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'User Backup Report (Pre-Cleanup)',
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
              headers: ['Sr.', 'Carpenter Name', 'Phone', 'Total Points', 'Earned Points', 'Created Date'],
              data: users.asMap().entries.map((entry) {
                final idx = entry.key;
                final doc = entry.value;
                final data = doc.data();
                final firstName = data['firstName'] ?? '';
                final lastName = data['lastName'] ?? '';
                final phone = carpenterData[doc.id]?['phone'] ?? 'N/A';
                final totalPoints = carpenterData[doc.id]?['totalPoints'] ?? 0;
                final earnedPoints = carpenterData[doc.id]?['earnedPoints'] ?? 0.0;
                final createdAt = carpenterData[doc.id]?['createdAt'] as Timestamp?;
                final createdDate = createdAt?.toDate().toString().split(' ')[0] ?? 'N/A';

                return [
                  '${idx + 1}',
                  '$firstName $lastName',
                  phone,
                  '$totalPoints',
                  (earnedPoints as num).toStringAsFixed(2),
                  createdDate,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              cellStyle: pw.TextStyle(),
              cellHeight: 20,
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Summary',
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
            pw.Text(
              'Export Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'user_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ User backup exported successfully! (${users.length} carpenters)'),
          backgroundColor: Colors.green,
        ),
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
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          'Export Users Backup',
          style: AppTypography.h2(),
        ),
        backgroundColor: context.themePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.backup,
                size: 80,
                color: context.themePrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Create User Backup',
                style: AppTypography.h3(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Export all carpenters with their points and phone numbers before cleanup.',
                style: AppTypography.bodyMedium().copyWith(
                  color: context.themeTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportUsersPdf,
                icon: _isExporting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.themeContentColor,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 24),
                label: Text(_isExporting ? 'Exporting...' : 'Export to PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.all16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                  borderRadius: AppRadius.md12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 PDF will include:',
                      style: AppTypography.labelLarge().copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Carpenter name and phone number\n• Total points and earned points\n• Account creation date\n• Summary with total carpenters and gross points',
                      style: AppTypography.bodySmall().copyWith(
                        color: context.themeTextMuted,
                      ),
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
