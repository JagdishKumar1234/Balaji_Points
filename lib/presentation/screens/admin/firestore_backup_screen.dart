import 'package:flutter/material.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'dart:convert';

class FirestoreBackupScreen extends StatefulWidget {
  const FirestoreBackupScreen({super.key});

  @override
  State<FirestoreBackupScreen> createState() => _FirestoreBackupScreenState();
}

class _FirestoreBackupScreenState extends State<FirestoreBackupScreen> {
  bool _isBackingUp = false;
  String _backupStatus = '';

  Future<void> _backupAllData() async {
    if (_isBackingUp) return;

    setState(() {
      _isBackingUp = true;
      _backupStatus = AppLocalizations.of(context)!.startingBackup;
    });

    try {
      final db = FirebaseFirestore.instance;

      // Fetch all users
      final usersSnapshot = await db.collection('users').forAdminBranch().get();
      final users = usersSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Fetch all bills
      final billsSnapshot = await db.collection('bills').forAdminBranch().get();
      final bills = billsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Create backup object
      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'collections': {
          'users': {'count': users.length, 'data': users},
          'bills': {'count': bills.length, 'data': bills},
        },
      };

      // Convert to JSON
      final backupJson = jsonEncode(backup);

      // Show summary
      setState(() {
        _backupStatus =
            '''
Backup Complete!

Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Users: ${users.length}
• Bills: ${bills.length}
• Timestamp: ${backup['timestamp']}
• Size: ${(backupJson.length / 1024).toStringAsFixed(2)} KB

Location: Firebase Firestore
Backup Type: Full Database Export

Next Step:
Copy the JSON data below to save as backup file
        ''';
      });

      // Show detailed backup data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.backupExportedUsersBills('${users.length}', '${bills.length}'),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: AppColors.success,
        ),
      );

      // Display backup preview
      _showBackupPreview(backup, backupJson);
    } catch (e) {
      setState(() {
        _backupStatus = AppLocalizations.of(context)!.error2('${e.toString()}');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.backupFailed('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  void _showBackupPreview(Map<String, dynamic> backup, String backupJson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(
          AppLocalizations.of(context)!.backupData,
          style: AppTypography.h3(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.backupUsersCount(
                  '${backup['collections']['users']['count']}',
                ),
                style: AppTypography.labelLarge(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: AppRadius.md12,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonEncode(backup['collections']['users']['data'].take(2)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.backupBillsCount(
                  '${backup['collections']['bills']['count']}',
                ),
                style: AppTypography.labelLarge(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: AppRadius.md12,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonEncode(backup['collections']['bills']['data'].take(2)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.md12,
                ),
                child: SelectableText(
                  AppLocalizations.of(context)!.totalSizeKb(
                    '${(backupJson.length / 1024).toStringAsFixed(2)}',
                  ),
                  style: AppTypography.labelSmall(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.firebaseBackup,
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
                Icons.cloud_download_rounded,
                size: 80,
                color: context.themePrimary,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.databaseBackup,
                style: AppTypography.h3(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.createACompleteBackupOfAll,
                style: AppTypography.bodyMedium().copyWith(
                  color: context.themeTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_backupStatus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _backupStatus,
                      style: AppTypography.bodySmall().copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.whatWillBeBackedUp,
                        style: AppTypography.labelLarge().copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.allUserAccountsCarpentersAdminsAll,
                        style: AppTypography.bodySmall().copyWith(
                          color: context.themeTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _backupAllData,
                icon: _isBackingUp
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.themeContentColor,
                        ),
                      )
                    : const Icon(Icons.backup_rounded, size: 24),
                label: Text(
                  _isBackingUp
                      ? AppLocalizations.of(context)!.backingUp
                      : AppLocalizations.of(context)!.startBackup,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                  borderRadius: AppRadius.md12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.backupIsStoredInFirebaseNo,
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.warning,
                        ),
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
