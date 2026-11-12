import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/branch/public_branches.dart';

/// Branch dropdown for guest forms. The chosen branch's admin receives what
/// is sent. Careers require a branch; in Contact Us it is optional, and
/// "Any branch" sends the enquiry to the Balaji Points team (super admin).
class BranchPicker extends ConsumerWidget {
  const BranchPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = true,
  });

  final PublicBranch? value;
  final ValueChanged<PublicBranch?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final branches =
        ref.watch(publicBranchesProvider).asData?.value ?? const [];
    final selected = branches.where((b) => b.id == value?.id).firstOrNull;
    return DropdownButtonFormField<PublicBranch>(
      initialValue: selected,
      isExpanded: true,
      validator: (v) =>
          required && v == null ? l10n.enquiryBranchRequired : null,
      decoration: InputDecoration(
        labelText: required
            ? l10n.enquiryBranchLabel
            : l10n.enquiryBranchOptional,
        hintText: l10n.enquiryBranchHint,
        isDense: true,
        prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
        filled: true,
        fillColor: context.themeCard,
        border: OutlineInputBorder(borderRadius: AppRadius.md12),
      ),
      items: [
        if (!required)
          DropdownMenuItem<PublicBranch>(
            value: null,
            child: Text(l10n.enquiryBranchAny, overflow: TextOverflow.ellipsis),
          ),
        for (final b in branches)
          DropdownMenuItem(
            value: b,
            child: Text(b.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
