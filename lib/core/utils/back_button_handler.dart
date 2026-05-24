import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

/// Utility class for handling Android back button scenarios
class BackButtonHandler {
  /// Show exit confirmation dialog
  static Future<bool?> showExitConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return false;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit App?',
          style: AppTypography.buttonMedium().copyWith(fontSize: 20),
        ),
        content: Text(
          'Do you want to exit the app?',
          style: AppTypography.bodyMedium().copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.grey600,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Exit',
              style: AppTypography.labelLarge().copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Show discard changes dialog
  static Future<bool?> showDiscardDialog(
    BuildContext context, {
    String? customMessage,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return false;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Discard Changes?',
          style: AppTypography.buttonMedium().copyWith(fontSize: 20),
        ),
        content: Text(
          customMessage ??
              'You have unsaved changes. Do you want to discard them?',
          style: AppTypography.bodyMedium().copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.grey600,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Discard',
              style: AppTypography.labelLarge().copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Exit app
  static void exitApp() {
    SystemNavigator.pop();
  }

  /// Show snackbar message for double-tap exit
  static void showDoubleTapExitMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Press back again to exit',
          style: AppTypography.bodyMedium().copyWith(color: AppColors.white),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.grey800,
      ),
    );
  }
}
