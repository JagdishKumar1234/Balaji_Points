import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';

class AddCarpenterDialog extends StatefulWidget {
  final VoidCallback? onCarpenterAdded;

  const AddCarpenterDialog({this.onCarpenterAdded, super.key});

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

    if (pin.length != 4) {
      _showSnack(AppLocalizations.of(context)!.enter4Digits, isError: true);
      return;
    }

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

      if (success && mounted) {
        _showSnack(AppLocalizations.of(context)!.carpenterCreatedSuccessfully);
        widget.onCarpenterAdded?.call();
        Navigator.of(context).pop();
      } else if (!success && mounted) {
        _showSnack(
          AppLocalizations.of(context)!.failedToCreateCarpenter,
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _creating = false);
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.error2('$e'), isError: true);
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
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.pin46Digits,
                hintText: AppLocalizations.of(context)!.enterPin,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.firstNameOptional,
                hintText: AppLocalizations.of(context)!.enterFirstName,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.lastNameOptional,
                hintText: AppLocalizations.of(context)!.enterLastName,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            if (_creating)
              const AppLoader()
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
                        foregroundColor: context.themeOnPrimary,
                        backgroundColor: context.themePrimary,
                      ),
                      child: Text(AppLocalizations.of(context)!.create),
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
