import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/services/maintenance/points_sync_repair_service.dart';
import 'points_repair_details_page.dart';
import 'points_scan_details_page.dart';

class PointsRepairPage extends ConsumerStatefulWidget {
  const PointsRepairPage({super.key});

  @override
  ConsumerState<PointsRepairPage> createState() => _PointsRepairPageState();
}

class _PointsRepairPageState extends ConsumerState<PointsRepairPage> {
  final _repairService = PointsSyncRepairService();
  Map<String, dynamic>? _report;
  bool _isLoading = false;
  String? _error;
  String? _success;
  Map<String, dynamic>? _repairResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AppText.h3('Points Repair Tool', color: context.themeTextPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.all16,
                border: Border.all(
                  color: context.themePrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: context.themePrimary),
                      const SizedBox(width: 8),
                      AppText.label('Points Data Repair',
                          color: context.themeTextPrimary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText.body(
                    'This tool scans user points data and fixes:\n'
                    '• Duplicate history entries\n'
                    '• Inconsistent totalPoints\n'
                    '• Mismatched tiers',
                    color: context.themeTextSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report section
            if (_report != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: AppRadius.all16,
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.h5('Scan Report', color: context.themeTextPrimary),
                    const SizedBox(height: 12),
                    _buildReportRow('Total users scanned',
                        '${_report!['totalUsersScanned']}'),
                    _buildReportRow('Users with issues',
                        '${_report!['usersWithIssues']}'),
                    _buildReportRow('Users with duplicates',
                        '${_report!['usersWithDuplicates']}'),
                    _buildReportRow(
                        'Total duplicate entries', '${_report!['totalDuplicates']}'),
                    _buildReportRow('Points mismatches',
                        '${_report!['pointsMismatches']}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'View Full Scan Details',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PointsScanDetailsPage(report: _report!),
                  ),
                ),
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: 20),
            ],

            // Repair results
            if (_repairResults != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: AppRadius.all16,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 22),
                        const SizedBox(width: 8),
                        AppText.h5('Repair Complete',
                            color: context.themeTextPrimary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRepairSummary(_repairResults!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // View details button
              AppButton(
                label: 'View Detailed Results',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PointsRepairDetailsPage(
                      repairReport: _report ?? {},
                      repairResults: _repairResults!,
                    ),
                  ),
                ),
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 20),
            ],

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: AppRadius.all16,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.body(_error!, color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Success message
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: AppRadius.all16,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.body(_success!, color: AppColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action buttons
            if (!_isLoading) ...[
              AppButton(
                label: _report == null ? 'Scan for Issues' : 'Scan Again',
                onPressed: _scanForIssues,
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 12),
              if (_report != null && _report!['usersWithIssues'] > 0)
                AppButton(
                  label: 'Repair All Users',
                  onPressed: _repairAll,
                  variant: AppButtonVariant.primary,
                ),
            ] else
              _buildScanLoadingAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.body(label, color: context.themeTextSecondary),
          AppText.body(value, color: context.themeTextPrimary),
        ],
      ),
    );
  }

  Widget _buildRepairSummary(Map<String, dynamic> results) {
    final repaired = results['repaired'] as int? ?? 0;
    final total = results['total'] as int? ?? 0;
    final duplicatesRemoved = results['totalDuplicatesRemoved'] as int? ?? 0;
    final pointsDiff = results['totalPointsDifference'] as num? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRepairSummaryRow(
          'Successfully Repaired',
          '$repaired/$total',
          AppColors.success,
        ),
        const SizedBox(height: 8),
        _buildRepairSummaryRow(
          'Duplicates Removed',
          '$duplicatesRemoved',
          const Color(0xFFFF8A65),
        ),
        const SizedBox(height: 8),
        _buildRepairSummaryRow(
          'Points Adjusted',
          '${pointsDiff.toInt()}',
          const Color(0xFF42A5F5),
        ),
      ],
    );
  }

  Widget _buildRepairSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(label, color: context.themeTextSecondary),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: AppRadius.sm8,
          ),
          child: AppText.body(value, color: color),
        ),
      ],
    );
  }

  Future<void> _scanForIssues() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final report = await _repairService.generateRepairReport();
      setState(() {
        _report = report;
        _isLoading = false;
        if (report['usersWithIssues'] == 0) {
          _success = 'No issues found! All user data is consistent.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Scan failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _repairAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.h4('Repair All Users?'),
        content: AppText.body(
          'This will repair ${_report!['usersWithIssues']} users by:\n\n'
          '• Removing duplicate history entries\n'
          '• Recalculating correct totals\n'
          '• Updating tier assignments\n\n'
          'This action cannot be undone easily.',
          color: context.themeTextSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText.body('Cancel', color: context.themeTextSecondary),
          ),
          AppButton(
            label: 'Repair',
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            fullWidth: false,
            verticalPadding: 10,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _repairService.repairAllUsers();

      // Verify no points were lost
      final verificationResult =
          await _repairService.verifyAllUsersAfterRepair(result);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _repairResults = result;

          if (verificationResult['allVerified'] == true &&
              verificationResult['noPointsLost'] == true) {
            _success =
                'Repaired ${result['repaired']}/${result['total']} users successfully!\n✅ Verified: NO POINTS LOST';
          } else {
            _success =
                'Repaired ${result['repaired']}/${result['total']} users.\n⚠️ Some verification issues - check logs';
          }
        } else {
          _error = result['error'] ?? 'Repair failed';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Repair failed: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildScanLoadingAnimation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.themePrimary.withValues(alpha: 0.3),
                width: 3,
              ),
              color: context.themePrimary.withValues(alpha: 0.05),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 40,
                  color: context.themePrimary,
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.themePrimary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppText.h5(
            'Scanning for Issues...',
            color: context.themeTextPrimary,
          ),
          const SizedBox(height: 8),
          AppText.body(
            'Analyzing all user points data',
            color: context.themeTextSecondary,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.themePrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
