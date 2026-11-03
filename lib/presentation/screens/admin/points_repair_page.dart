import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
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
        title: AppText.h3(
          AppLocalizations.of(context)!.pointsRepairTool,
          color: context.themeTextPrimary,
        ),
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
                      Icon(
                        Icons.info_outline_rounded,
                        color: context.themePrimary,
                      ),
                      const SizedBox(width: 8),
                      AppText.label(
                        AppLocalizations.of(context)!.pointsDataRepair,
                        color: context.themeTextPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText.body(
                    AppLocalizations.of(context)!.thisToolScansUserPointsData,
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
                    AppText.h5(
                      AppLocalizations.of(context)!.scanReport,
                      color: context.themeTextPrimary,
                    ),
                    const SizedBox(height: 12),
                    _buildReportRow(
                      AppLocalizations.of(context)!.totalUsersScanned,
                      '${_report!['totalUsersScanned']}',
                    ),
                    _buildReportRow(
                      AppLocalizations.of(context)!.usersWithIssues,
                      '${_report!['usersWithIssues']}',
                    ),
                    _buildReportRow(
                      AppLocalizations.of(context)!.usersWithDuplicates,
                      '${_report!['usersWithDuplicates']}',
                    ),
                    _buildReportRow(
                      AppLocalizations.of(context)!.totalDuplicateEntries,
                      '${_report!['totalDuplicates']}',
                    ),
                    _buildReportRow(
                      AppLocalizations.of(context)!.pointsMismatches,
                      '${_report!['pointsMismatches']}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: AppLocalizations.of(context)!.viewFullScanDetails,
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
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        AppText.h5(
                          AppLocalizations.of(context)!.repairComplete,
                          color: context.themeTextPrimary,
                        ),
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
                label: AppLocalizations.of(context)!.viewDetailedResults,
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
                    Icon(Icons.error_outline_rounded, color: AppColors.error),
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
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
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
                label: _report == null
                    ? AppLocalizations.of(context)!.scanForIssues
                    : AppLocalizations.of(context)!.scanAgain,
                onPressed: _scanForIssues,
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 12),
              if (_report != null && _report!['usersWithIssues'] > 0)
                AppButton(
                  label: AppLocalizations.of(context)!.repairAllUsers,
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
          AppLocalizations.of(context)!.successfullyRepaired,
          '$repaired/$total',
          AppColors.success,
        ),
        const SizedBox(height: 8),
        _buildRepairSummaryRow(
          AppLocalizations.of(context)!.duplicatesRemoved,
          '$duplicatesRemoved',
          AppColors.warning,
        ),
        const SizedBox(height: 8),
        _buildRepairSummaryRow(
          AppLocalizations.of(context)!.pointsAdjusted,
          '${pointsDiff.toInt()}',
          AppColors.primaryOnDark,
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
          _success = AppLocalizations.of(context)!.noIssuesFoundAllUserData;
        }
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.scanFailed('$e');
        _isLoading = false;
      });
    }
  }

  Future<void> _repairAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.h4(AppLocalizations.of(context)!.repairAllUsers2),
        content: AppText.body(
          AppLocalizations.of(
            context,
          )!.repairConfirmBody('${_report!['usersWithIssues']}'),
          color: context.themeTextSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText.body(
              AppLocalizations.of(context)!.cancel,
              color: context.themeTextSecondary,
            ),
          ),
          AppButton(
            label: AppLocalizations.of(context)!.repair,
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
      final verificationResult = await _repairService.verifyAllUsersAfterRepair(
        result,
      );

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _repairResults = result;

          if (verificationResult['allVerified'] == true &&
              verificationResult['noPointsLost'] == true) {
            _success = AppLocalizations.of(
              context,
            )!.repairSuccess('${result['repaired']}', '${result['total']}');
          } else {
            _success = AppLocalizations.of(
              context,
            )!.repairPartial('${result['repaired']}', '${result['total']}');
          }
        } else {
          _error =
              result['error'] ?? AppLocalizations.of(context)!.repairFailed;
        }
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.repairFailed2('$e');
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
            AppLocalizations.of(context)!.scanningForIssues,
            color: context.themeTextPrimary,
          ),
          const SizedBox(height: 8),
          AppText.body(
            AppLocalizations.of(context)!.analyzingAllUserPointsData,
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
