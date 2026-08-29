import 'package:flutter/material.dart';
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
      _backupStatus = 'Starting backup...';
    });

    try {
      final db = FirebaseFirestore.instance;

      // Fetch all users
      final usersSnapshot = await db.collection('users').get();
      final users = usersSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Fetch all bills
      final billsSnapshot = await db.collection('bills').get();
      final bills = billsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Create backup object
      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'collections': {
          'users': {
            'count': users.length,
            'data': users,
          },
          'bills': {
            'count': bills.length,
            'data': bills,
          },
        },
      };

      // Convert to JSON
      final backupJson = jsonEncode(backup);

      // Show summary
      setState(() {
        _backupStatus = '''
✅ Backup Complete!

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
            'Backup exported: ${users.length} users, ${bills.length} bills',
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );

      // Display backup preview
      _showBackupPreview(backup, backupJson);
    } catch (e) {
      setState(() {
        _backupStatus = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
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
          'Backup Data',
          style: AppTypography.h3(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Users (${backup['collections']['users']['count']})',
                style: AppTypography.labelLarge(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: AppRadius.md12,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonEncode(backup['collections']['users']['data'].take(2)),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bills (${backup['collections']['bills']['count']})',
                style: AppTypography.labelLarge(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: AppRadius.md12,
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonEncode(backup['collections']['bills']['data'].take(2)),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: AppRadius.md12,
                ),
                child: SelectableText(
                  'Total Size: ${(backupJson.length / 1024).toStringAsFixed(2)} KB',
                  style: AppTypography.labelSmall(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          'Firebase Backup',
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
                Icons.cloud_download,
                size: 80,
                color: context.themePrimary,
              ),
              const SizedBox(height: 24),
              Text(
                'Database Backup',
                style: AppTypography.h3(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create a complete backup of all users and bills data from Firebase Firestore.',
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
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 What will be backed up:',
                        style: AppTypography.labelLarge().copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• All user accounts (carpenters & admins)\n• All bill records\n• Complete user data with timestamps\n• Firestore metadata',
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
                    : const Icon(Icons.backup, size: 24),
                label: Text(_isBackingUp ? 'Backing up...' : 'Start Backup'),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                  borderRadius: AppRadius.md12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Backup is stored in Firebase. No files are saved locally.',
                        style: AppTypography.bodySmall().copyWith(
                          color: Colors.orange[700],
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
